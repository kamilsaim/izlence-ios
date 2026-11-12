import Foundation
import SwiftUI

@MainActor final class AppStore: ObservableObject {
    @Published private(set) var library = Library()
    @Published private(set) var keys = APIKeys()
    @Published private(set) var catalog: [Film] = []
    @Published var error: String?
    @Published var busy = false
    @Published var progress = ""
    @Published var notice = ""
    private var storageFailure = false
    private var operation: Task<Void, Never>?
    private let file: URL
    let isUITesting: Bool

    init(directory: URL? = nil, testing: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing"), loadKeys: Bool = true) {
        isUITesting = testing
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Izlence", isDirectory: true)
        file = root.appendingPathComponent("library-v2.json")
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) { library = try BackupCodec.decode(Data(contentsOf: file)) }
        } catch { storageFailure = true; self.error = "Arşiv okunamadı; mevcut dosya korundu. JSON yedeğiyle geri yükleyebilirsin." }
        if !testing && loadKeys { do { keys = try KeychainStore.read() } catch { self.error = error.localizedDescription } }
        if let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
           let data = try? Data(contentsOf: url), let rows = (try? JSONSerialization.jsonObject(with: data)) as? [JSON] {
            catalog = rows.compactMap { try? Film($0) }
        }
        if testing { library = Library() }
    }
    var tmdb: TMDBClient { TMDBClient(key: keys.tmdb, preferences: library.preferences) }
    var entries: [Entry] { library.entries.values.sorted { $0.updatedAt > $1.updatedAt } }

    private func write(_ next: Library, recovering: Bool = false) throws {
        guard !storageFailure || recovering else { throw ArchiveError.invalid("Önce arşiv yedeğini geri yükle; mevcut dosya korunuyor.") }
        let bytes = try BackupCodec.encode(next)
        if !isUITesting {
            try bytes.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            var destination = file; var values = URLResourceValues(); values.isExcludedFromBackup = true
            try destination.setResourceValues(values)
        }
        library = next; storageFailure = false
    }
    func apply(_ edit: (inout Library) -> Void) {
        var next = library; edit(&next)
        do { try write(next) } catch { self.error = error.localizedDescription }
    }
    func save(_ entry: Entry) {
        var value = entry; value.updatedAt = Date()
        apply { $0.entries[value.id] = value }
    }
    func toggle(_ film: Film, flag: String) {
        var e = library.entries[film.id] ?? Entry(film: film)
        switch flag {
        case "watched": e.watched.toggle(); if e.watched { e.watchlist = false; e.watchedAt = e.watchedAt ?? Date() } else { e.watchedAt = nil }
        case "favorite": e.favorite.toggle()
        default: e.watchlist.toggle(); if e.watchlist { e.watched = false; e.watchedAt = nil }
        }
        save(e)
    }
    func saveKeys(tmdb: String, google: String) throws {
        let normalized = APIKeys(tmdb: tmdb.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "Bearer ", with: ""), google: google.trimmingCharacters(in: .whitespacesAndNewlines))
        guard [normalized.tmdb, normalized.google].allSatisfy({ $0.count <= 8192 && $0.rangeOfCharacter(from: .whitespacesAndNewlines) == nil }) else { throw ArchiveError.invalid("Anahtar boşluk içermemeli ve 8192 karakteri aşmamalı.") }
        if !isUITesting { try KeychainStore.save(normalized) }; keys = normalized
    }
    func preferences(_ p: Preferences) {
        apply { next in if next.preferences != p { next.aiPicks = []; next.recommendations = [] }; next.preferences = p }
    }
    func backup() throws -> Data { try BackupCodec.encode(library) }
    func restore(_ bytes: Data, replace: Bool) throws {
        var imported = try BackupCodec.decode(bytes)
        if !replace { var merged = library; for (id, value) in imported.entries where merged.entries[id] == nil { merged.entries[id] = value }; imported = merged }
        if !isUITesting, FileManager.default.fileExists(atPath: file.path) {
            let recovery = file.deletingLastPathComponent().appendingPathComponent("recovery-\(Int(Date().timeIntervalSince1970)).json")
            try FileManager.default.copyItem(at: file, to: recovery)
            var values = URLResourceValues(); values.isExcludedFromBackup = true; var url = recovery; try url.setResourceValues(values)
        }
        try write(imported, recovering: true)
    }
    func wipeArchive() throws {
        cancel()
        let folder = file.deletingLastPathComponent()
        for url in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) where url.lastPathComponent.hasPrefix("recovery-") { try FileManager.default.removeItem(at: url) }
        try write(Library(), recovering: true)
    }
    func perform(_ action: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }; busy = true; notice = ""; progress = "Hazırlanıyor…"
        operation = Task {
            defer { busy = false; progress = ""; operation = nil }
            do { try await action() } catch is CancellationError { notice = "İşlem iptal edildi." }
            catch { self.error = error.localizedDescription }
        }
    }
    func cancel() { operation?.cancel() }
    func dismiss(_ film: Film) {
        apply { $0.dismissed.insert(film.id); $0.aiPicks.removeAll { $0.id == film.id }; $0.recommendations.removeAll { $0.id == film.id } }
    }
    func generateAI(_ ask: String) async throws {
        guard library.entries.count >= 3 else { throw ArchiveError.invalid("Zevkini tanımak için arşivine en az 3 yapım ekle.") }
        guard !keys.tmdb.isEmpty else { throw ArchiveError.invalid("Önerileri doğrulamak için TMDB anahtarını da ekle.") }
        let source = library; let originalKeys = keys; let client = tmdb
        let (model, memory, raw) = try await GeminiClient(key: keys.google).generate(library: source, ask: ask) { [weak self] value in await MainActor.run { self?.progress = value } }
        var picks: [Pick] = []
        for row in raw {
            try Task.checkCancellation(); progress = "Öneriler TMDB ile doğrulanıyor…"
            let type = row.text("type", "movie"); guard ["movie", "tv"].contains(type) else { continue }
            let year = row.int("year"); guard year > 1800 else { continue }
            let candidates = try await client.results("/search/\(type)", ["query": row.text("title"), type == "tv" ? "first_air_date_year" : "year": String(year)], type: type)
            func normalized(_ s: String) -> String { s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX")).filter { $0.isLetter || $0.isNumber } }
            guard var f = candidates.first(where: { (normalized($0.title) == normalized(row.text("title")) || normalized($0.original) == normalized(row.text("title"))) && abs((Int($0.year) ?? 0) - year) <= 1 }), library.entries[f.id] == nil, !library.dismissed.contains(f.id), !picks.contains(where: { $0.id == f.id }) else { continue }
            if !source.preferences.providers.isEmpty { f = try await client.details(f); if Set(f.providerIDs).isDisjoint(with: source.preferences.providers) { continue } }
            picks.append(Pick(film: f, reason: row.text("reason")))
        }
        try Task.checkCancellation()
        guard originalKeys == keys, source.preferences == library.preferences else { throw ArchiveError.invalid("API ayarları değişti. Yeniden öneri iste.") }
        guard !picks.isEmpty else { throw ArchiveError.invalid("Yeni bir yapım doğrulanamadı. İsteğini değiştirip yeniden dene.") }
        var next = library; next.aiPicks = picks; next.memory = memory; next.model = model; try write(next)
    }
    func recommendations() async throws {
        let source = library; let client = tmdb
        let seeds = entries.filter { $0.favorite || $0.score >= 7 }.sorted { $0.score > $1.score }
        var candidates: [Pick] = []
        let offset = seeds.isEmpty ? 0 : source.round % seeds.count
        for index in 0..<min(3, seeds.count) {
            let seed = seeds[(index + offset) % seeds.count].film; progress = "\(seed.title) benzeri yapımlar aranıyor…"
            let rows = try await client.results("/\(seed.type)/\(seed.number)/recommendations", type: seed.type)
            candidates += rows.map { Pick(film: $0, reason: "\(seed.title) beğenine göre") }
        }
        let trends = try await client.results("/trending/all/week", ["page": String(source.round % 4 + 1)])
        candidates += trends.map { Pick(film: $0, reason: "Bu hafta öne çıkanlardan") }
        var seen = Set<String>(); var filtered: [Pick] = []
        for pick in candidates where source.entries[pick.id] == nil && !source.dismissed.contains(pick.id) && seen.insert(pick.id).inserted {
            try Task.checkCancellation()
            if !source.preferences.providers.isEmpty {
                let details = try await client.details(pick.film)
                if Set(details.providerIDs).isDisjoint(with: source.preferences.providers) { continue }
            }
            filtered.append(pick); if filtered.count >= 24 { break }
        }
        guard source.preferences == library.preferences else { throw ArchiveError.invalid("Tercihler değişti. Yeniden dene.") }
        guard !filtered.isEmpty else { throw ArchiveError.invalid("Bu tercihlerle yeni öneri bulunamadı.") }
        var next = library; next.recommendations = filtered; next.round += 1; try write(next)
    }
    func scanCollections() async throws {
        let client = tmdb; var found: [Collection] = []; var ids = Set<Int>()
        for e in entries where e.film.type == "movie" {
            try Task.checkCancellation(); progress = "\(e.film.title) serisi kontrol ediliyor…"
            let f = try await client.details(e.film)
            if f.collectionID > 0, ids.insert(f.collectionID).inserted { found.append(try await client.collection(f.collectionID)) }
        }
        var next = library; next.collections = found; try write(next); notice = "\(found.count) seri bulundu."
    }
    func importIMDb(_ bytes: Data, watched: Bool) async throws {
        guard bytes.count <= BackupCodec.limit, let text = String(data: bytes, encoding: .utf8) else { throw ArchiveError.invalid("UTF-8 IMDb CSV dosyası seç (en çok 32 MB).") }
        let rows = try IMDbCSV.parse(text); guard !rows.isEmpty else { throw ArchiveError.invalid("Aktarılabilir IMDb kaydı bulunamadı.") }
        let client = tmdb; var pending: [Entry] = []; var skipped = 0
        for (index, row) in rows.enumerated() {
            try Task.checkCancellation(); progress = "IMDb aktarımı: \(index + 1)/\(rows.count)"
            do {
                var films: [Film] = []
                for attempt in 0..<3 {
                    do { films = try await client.search(row.imdb); break }
                    catch NetworkError.status(429) { if attempt == 2 { throw NetworkError.status(429) }; try await Task.sleep(for: .seconds(2 * (attempt + 1))) }
                }
                if let f = films.first {
                    var e = library.entries[f.id] ?? Entry(film: f)
                    if watched { e.watched = true; e.watchlist = false; e.watchedAt = row.watchedDate ?? e.watchedAt }
                    else if !e.watched { e.watchlist = true }
                    if row.score > 0 { e.score = row.score }; pending.append(e)
                } else { skipped += 1 }
            } catch NetworkError.status(404) { skipped += 1 }
            try await Task.sleep(for: .milliseconds(180))
        }
        try Task.checkCancellation()
        var next = library
        for e in pending { next.entries[e.id] = e }; try write(next); notice = "\(pending.count) kayıt aktarıldı; \(skipped) kayıt bulunamadı."
    }
    func refreshTV() async {
        guard !keys.tmdb.isEmpty, !busy else { return }
        let client = tmdb
        for e in entries.filter({ $0.tracking && $0.film.type == "tv" && Date().timeIntervalSince1970 * 1000 - $0.film.fetchedAt > 12 * 60 * 60 * 1000 }).prefix(30) {
            if Task.isCancelled { return }
            if let film = try? await client.details(e.film), var current = library.entries[e.id] { current.film = film; save(current) }
        }
    }
}
