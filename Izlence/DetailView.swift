import SwiftUI

struct DetailView: View {
    var initial: Film
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var film: Film?
    @State private var related: [Film] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var editor = false
    @State private var remove = false
    @State private var collection: Collection?
    private var value: Film { film ?? store.library.entries[initial.id]?.film ?? initial }
    private var entry: Entry? { store.library.entries[initial.id] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack(alignment: .bottomLeading) {
                    FilmArt(film: value, wide: true).frame(height: 280).clipped()
                    LinearGradient(colors: [.clear, Cinema.background], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(value.title).font(.system(.largeTitle, design: .serif, weight: .bold))
                        Text("\(value.year) · \(value.label) · ★ \(value.rating.formatted(.number.precision(.fractionLength(1))))").foregroundStyle(Cinema.muted)
                    }.padding(20)
                }
                VStack(alignment: .leading, spacing: 24) {
                    if loading { ProgressView("Ayrıntılar yükleniyor…") }
                    if let loadError { Text(loadError).font(.footnote).foregroundStyle(.orange); Button("Yeniden dene") { Task { await load() } } }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { flags }
                        VStack(alignment: .leading, spacing: 8) { flags }
                    }
                    if !value.genres.isEmpty { Text(value.genres.joined(separator: " · ")).font(.subheadline).foregroundStyle(Cinema.gold) }
                    if !value.overview.isEmpty { Text(value.overview).font(.body).lineSpacing(5) }
                    if value.runtime > 0 { Label("\(value.runtime) dakika", systemImage: "clock").foregroundStyle(Cinema.muted) }
                    if !value.directors.isEmpty { metadata("Yönetmen / Yaratıcı", text: value.directors.joined(separator: ", ")) }
                    if !value.cast.isEmpty { metadata("Oyuncular", text: value.cast.joined(separator: ", ")) }
                    Button { editor = true } label: {
                        HStack { Label("Puanım ve notum", systemImage: "square.and.pencil"); Spacer(); Text(entry?.score ?? 0 > 0 ? "\(entry?.score ?? 0)/10" : "Puan ver") }
                            .padding(16).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 16))
                    }.accessibilityIdentifier("edit-note")
                    if let note = entry?.note, !note.isEmpty { Text(note).foregroundStyle(Cinema.muted).textSelection(.enabled) }
                    if value.type == "tv" { tracking }
                    if !value.providers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nerede izleyebilirim?").font(.title3.bold())
                            Text(value.providers.joined(separator: " · "))
                            if let url = safeURL(value.providerLink) { Link("Yayın seçeneklerini aç", destination: url).frame(minHeight: 44) }
                            Text("Yayın bilgileri JustWatch üzerinden TMDB tarafından sağlanır; ülke ve tarihe göre değişebilir.").font(.caption).foregroundStyle(Cinema.muted)
                        }
                    }
                    if value.imdbID.range(of: #"^tt[0-9]{5,12}$"#, options: .regularExpression) != nil {
                        Link(destination: URL(string: "https://www.imdb.com/title/\(value.imdbID)/")!) { Label("IMDb’de aç", systemImage: "arrow.up.right.square") }.frame(minHeight: 44)
                    }
                    if value.trailer.range(of: #"^[A-Za-z0-9_-]{6,20}$"#, options: .regularExpression) != nil {
                        Link(destination: URL(string: "https://www.youtube.com/watch?v=\(value.trailer)")!) { Label("Fragmanı izle", systemImage: "play.circle") }.frame(minHeight: 44)
                    }
                    if let collection {
                        DisclosureGroup(collection.name) { ForEach(collection.parts) { FilmRow(film: $0) } }
                    }
                    if !value.photos.isEmpty {
                        Text("Kareler").font(.title3.bold())
                        ScrollView(.horizontal) {
                            HStack { ForEach(value.photos, id: \.self) { path in
                                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780\(path)")) { image in image.resizable().scaledToFill() } placeholder: { Rectangle().fill(Cinema.surface) }
                                    .frame(width: 280, height: 160).clipped().clipShape(RoundedRectangle(cornerRadius: 16)).accessibilityLabel("\(value.title) sahne görseli")
                            } }
                        }
                    }
                    if entry != nil { Button("Arşivimden kaldır", role: .destructive) { remove = true }.frame(minHeight: 44) }
                }.padding(.horizontal, 20)
                if !related.isEmpty { FilmShelf(title: "Benzer hikâyeler", films: related) }
            }.padding(.bottom, 32).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(Cinema.background).navigationBarTitleDisplayMode(.inline)
            .task(id: initial.id) { await load() }
            .sheet(isPresented: $editor) { EntryEditor(film: value, initial: entry).environmentObject(store) }
            .confirmationDialog("Bu yapım arşivinden kaldırılsın mı?", isPresented: $remove, titleVisibility: .visible) {
                Button("Kaldır", role: .destructive) { store.apply { $0.entries.removeValue(forKey: initial.id) }; dismiss() }
            } message: { Text("Bu yapıma verdiğin puan, not ve bölüm ilerlemesi de kaldırılır.") }
    }
    @ViewBuilder private var flags: some View {
        flag("İzledim", icon: "checkmark.circle", active: entry?.watched == true, key: "watched")
        flag("İzleyeceğim", icon: "bookmark", active: entry?.watchlist == true, key: "watchlist")
        flag("Favori", icon: "heart", active: entry?.favorite == true, key: "favorite")
    }
    private func flag(_ title: String, icon: String, active: Bool, key: String) -> some View {
        Button { store.toggle(value, flag: key) } label: { Label(title, systemImage: active ? icon + ".fill" : icon).font(.subheadline).frame(minHeight: 44) }
            .buttonStyle(.bordered).tint(active ? Cinema.gold : Cinema.muted).accessibilityValue(active ? "Seçili" : "Seçili değil").accessibilityIdentifier("flag-\(key)")
    }
    private var tracking: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dizi takibi", systemImage: "play.rectangle").font(.title3.bold())
            if let e = entry, e.tracking {
                Text("Sezon \(e.season) · Bölüm \(e.episode)").font(.headline).foregroundStyle(Cinema.gold)
                if e.hasNewEpisode { Label("Yeni bölüm yayınlandı", systemImage: "sparkles").foregroundStyle(Cinema.gold) }
                if let next = value.nextEpisode { Text("Sıradaki: S\(next.season) B\(next.episode) · \(next.date)").foregroundStyle(Cinema.muted) }
                Button("Bir bölüm izledim", systemImage: "plus.circle") {
                    var updated = e
                    let count = value.seasonEpisodes[e.season] ?? 0
                    if count > 0 && e.episode >= count, value.seasonEpisodes[e.season + 1] != nil { updated.season += 1; updated.episode = 1 }
                    else if count == 0 || e.episode < count { updated.episode += 1 }
                    store.save(updated)
                }.buttonStyle(.borderedProminent)
                Button("İlerlemeyi düzenle") { editor = true }.frame(minHeight: 44)
            } else {
                Text("\(value.seasons) sezon · \(value.episodes) bölüm").foregroundStyle(Cinema.muted)
                Button("Takibe başla", systemImage: "play") { var e = entry ?? Entry(film: value); e.tracking = true; store.save(e) }.buttonStyle(.borderedProminent)
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 20))
    }
    private func metadata(_ title: String, text: String) -> some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption).foregroundStyle(Cinema.muted); Text(text).font(.subheadline) } }
    private func safeURL(_ text: String) -> URL? { guard let url = URL(string: text), url.scheme == "https", let host = url.host, host == "themoviedb.org" || host.hasSuffix(".themoviedb.org") || host == "justwatch.com" || host.hasSuffix(".justwatch.com") else { return nil }; return url }
    private func load() async {
        guard !store.isUITesting else { return }; loading = true; loadError = nil
        defer { loading = false }
        do {
            let client = store.tmdb; let loaded = try await client.details(initial); try Task.checkCancellation(); film = loaded
            if var e = store.library.entries[initial.id] { e.film = loaded; store.save(e) }
            related = (try? await client.results("/\(initial.type)/\(initial.number)/similar", type: initial.type)) ?? []
            if loaded.collectionID > 0 { collection = try? await client.collection(loaded.collectionID) }
        } catch is CancellationError { } catch { if !Task.isCancelled { loadError = error.localizedDescription } }
    }
}

struct EntryEditor: View {
    var film: Film
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var score: Int
    @State private var tracking: Bool
    @State private var season: Int
    @State private var episode: Int
    init(film: Film, initial: Entry?) {
        self.film = film; _note = State(initialValue: initial?.note ?? ""); _score = State(initialValue: initial?.score ?? 0)
        _tracking = State(initialValue: initial?.tracking ?? false); _season = State(initialValue: initial?.season ?? 1); _episode = State(initialValue: initial?.episode ?? 0)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Puanım") { Picker("Puan", selection: $score) { Text("Puan verilmedi").tag(0); ForEach(1...10, id: \.self) { Text("\($0)/10").tag($0) } } }
                Section("Kişisel notum") { TextEditor(text: $note).frame(minHeight: 180).accessibilityLabel("Kişisel notum").accessibilityIdentifier("note-editor") }
                if film.type == "tv" {
                    Section("Bölüm ilerlemesi") {
                        Toggle("Takip ediyorum", isOn: $tracking)
                        if tracking {
                            Stepper("Sezon \(season)", value: $season, in: 1...(film.seasons > 0 ? max(season, film.seasons) : 100))
                            Stepper("Bölüm \(episode)", value: $episode, in: 0...max(episode, film.seasonEpisodes[season] ?? 1000))
                                .onChange(of: season) { _, value in if let count = film.seasonEpisodes[value] { episode = min(episode, count) } }
                            Button("İlerlemeyi sıfırla", role: .destructive) { season = 1; episode = 0 }
                        }
                    }
                }
            }.navigationTitle("Puan ve not").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Kaydet") {
                        var e = store.library.entries[film.id] ?? Entry(film: film); e.note = note; e.score = score; e.tracking = tracking; e.season = season; e.episode = episode
                        store.save(e); if store.error == nil { dismiss() }
                    }.accessibilityIdentifier("save-note") }
                }
        }.tint(Cinema.gold).preferredColorScheme(.dark)
    }
}
