import SwiftUI
import UniformTypeIdentifiers
import Charts

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data = Data()
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var apiSettings = false
    @State private var contentSettings = false
    @State private var statistics = false
    @State private var importing = false
    @State private var exporting = false
    @State private var importKind = "json"
    @State private var csvWatched = true
    @State private var backup = JSONDocument(data: Data())
    @State private var pending: Data?
    @State private var importConfirm = false
    @State private var wipe = false
    @State private var wipeKeys = false
    @State private var resetDismissed = false
    var body: some View {
        Form {
            Section { BrandHeader().padding(.vertical, 12).listRowBackground(Cinema.background) }
            Section("Sinema profilim") {
                Button { statistics = true } label: { Label("İzleme istatistiklerim", systemImage: "chart.bar.xaxis") }
                Button { contentSettings = true } label: { Label("Dil, ülke ve yayın platformları", systemImage: "globe") }
                Button { apiSettings = true } label: { Label("API ayarlarım", systemImage: "key") }
            }
            if !store.library.dismissed.isEmpty {
                Section("Öneri tercihlerim") {
                    Button("Gizlediğim önerileri sıfırla (\(store.library.dismissed.count))") { resetDismissed = true }
                }
            }
            Section {
                Button { do { backup = JSONDocument(data: try store.backup()); exporting = true } catch { store.error = error.localizedDescription } } label: { Label("JSON yedeği dışa aktar", systemImage: "square.and.arrow.up") }
                Button { importKind = "json"; importing = true } label: { Label("Android / Web / iOS yedeği aktar", systemImage: "square.and.arrow.down") }
            } header: { Text("Arşiv yedeğim") } footer: { Text("Arşivin bu cihazda saklanır. Cihazlar arasında otomatik eşitleme yoktur; JSON yedeğini taşıyabilirsin. Yedeğe API anahtarların eklenmez.") }
            Section("IMDb’den aktar") {
                Toggle("İzlediklerim olarak aktar", isOn: $csvWatched)
                Button { importKind = "csv"; importing = true } label: { Label("IMDb CSV dosyası seç", systemImage: "tablecells") }.disabled(store.busy)
                Text("Seçeneği kapatırsan kayıtlar İzleyeceğim listesine eklenir. Mevcut notların korunur.").font(.caption).foregroundStyle(Cinema.muted)
            }
            if !store.notice.isEmpty { Section { Text(store.notice).foregroundStyle(Cinema.gold) } }
            Section("Uygulama") {
                Link("Gizlilik politikası", destination: URL(string: "https://izlence.web.app/gizlilik.html")!)
                Text("İzlence iOS · \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))").font(.footnote).foregroundStyle(Cinema.muted)
                Text("Film bilgileri ve görseller: TMDB. Yayın platformları: JustWatch. Bu ürün TMDB tarafından onaylanmış veya sertifikalandırılmış değildir.").font(.caption).foregroundStyle(Cinema.muted)
            }
            Section("Verilerim") {
                Button("Arşivimi sil", role: .destructive) { wipe = true }
                Button("API anahtarlarımı sil", role: .destructive) { wipeKeys = true }
            }
        }.scrollContentBackground(.hidden).background(Cinema.background).navigationTitle("Profil")
            .sheet(isPresented: $apiSettings) { APISettingsView().environmentObject(store) }
            .sheet(isPresented: $contentSettings) { ContentSettingsView().environmentObject(store) }
            .sheet(isPresented: $statistics) { StatisticsView().environmentObject(store) }
            .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "izlence-yedek-\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash)))") { result in
                switch result { case .success: store.notice = "Yedek kaydedildi."; case .failure(let error): store.error = error.localizedDescription }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: importKind == "json" ? [.json] : [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                    if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > BackupCodec.limit { throw ArchiveError.invalid("Dosya 32 MB sınırını aşıyor.") }
                    let bytes = try Data(contentsOf: url)
                    if importKind == "json" { _ = try BackupCodec.decode(bytes); pending = bytes; importConfirm = true }
                    else { store.perform { try await store.importIMDb(bytes, watched: csvWatched) } }
                } catch { store.error = error.localizedDescription }
            }
            .confirmationDialog("Arşiv yedeği nasıl aktarılsın?", isPresented: $importConfirm, titleVisibility: .visible) {
                Button("Mevcut arşivle birleştir") { restore(replace: false) }
                Button("Arşivin tamamını yedekle değiştir", role: .destructive) { restore(replace: true) }
                Button("Vazgeç", role: .cancel) { pending = nil }
            } message: { Text("Birleştirme mevcut kayıtlarına dokunmaz. Değiştirme öncesinde cihazda kurtarma kopyası saklanır.") }
            .confirmationDialog("Arşivin tamamen silinsin mi?", isPresented: $wipe, titleVisibility: .visible) {
                Button("Arşivimi sil", role: .destructive) { do { try store.wipeArchive() } catch { store.error = error.localizedDescription } }
            } message: { Text("Puanların, notların, listelerin, zevk hafızan ve cihazdaki kurtarma kopyaların silinir. Önce JSON yedeği alabilirsin.") }
            .confirmationDialog("İki API anahtarı da silinsin mi?", isPresented: $wipeKeys, titleVisibility: .visible) {
                Button("Anahtarları sil", role: .destructive) { do { try store.saveKeys(tmdb: "", google: "") } catch { store.error = error.localizedDescription } }
            }
            .confirmationDialog("Gizlediğin öneriler yeniden gösterilebilsin mi?", isPresented: $resetDismissed, titleVisibility: .visible) {
                Button("Öneri gizlemelerini sıfırla") { store.apply { $0.dismissed = [] } }
            } message: { Text("Gizlediğin yapımlar yeniden önerilebilir. İzlenen yapımlar önerilmez.") }
    }
    private func restore(replace: Bool) {
        guard let pending else { return }
        do { try store.restore(pending, replace: replace); store.notice = "Yedek aktarıldı; arşivinde \(store.entries.count) yapım var."; self.pending = nil }
        catch { store.error = error.localizedDescription }
    }
}

struct APISettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var tmdb = ""
    @State private var google = ""
    @State private var error: String?
    @State private var models: [String] = []
    @State private var model = "auto"
    @State private var loading = false
    @State private var task: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("TMDB API anahtarı / okuma jetonu", text: $tmdb).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityLabel("TMDB anahtarı")
                    Link("TMDB anahtarı oluştur", destination: URL(string: "https://www.themoviedb.org/settings/api")!)
                } header: { Text("Film bilgileri · TMDB") } footer: { Text("İsteğe bağlıdır. Boş bırakırsan Android/web ile aynı ortak bağlantı kullanılır. Kendi anahtarını girersen istekler doğrudan TMDB’ye gider.") }
                Section {
                    SecureField("Google AI API anahtarı", text: $google).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityLabel("Google AI anahtarı")
                    Link("Google AI Studio’yu aç", destination: URL(string: "https://aistudio.google.com/api-keys")!)
                    Button("Kullanılabilir modelleri getir") { loadModels() }.disabled(loading || google.isEmpty)
                    if loading { ProgressView("Modeller alınıyor…") }
                    Picker("Gemini modeli", selection: $model) {
                        Text("Otomatik").tag("auto")
                        if model != "auto", !models.contains(model) { Text(model).tag(model) }
                        ForEach(models, id: \.self) { Text($0).tag($0) }
                    }
                } header: { Text("Yapay zekâ · Google AI") } footer: { Text("AI isteği arşivindeki ad, puan ve tercihleri Google’a gönderir. Kişisel notların gönderilmez. Google AI kotası ve olası ücretler kendi hesabına aittir.") }
                Section { Label("Anahtarların Apple Keychain’de yalnızca bu cihaz için saklanır; JSON yedeğine eklenmez.", systemImage: "lock.shield").font(.footnote) }
                if let error { Section { Text(error).foregroundStyle(.orange) } }
            }.navigationTitle("API ayarlarım").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") {
                    do { try store.saveKeys(tmdb: tmdb, google: google); var p = store.library.preferences; p.model = model; store.preferences(p); if store.error == nil { dismiss() } }
                    catch { self.error = error.localizedDescription }
                } }
            }
        }.tint(Cinema.gold).preferredColorScheme(.dark)
            .onAppear { tmdb = store.keys.tmdb; google = store.keys.google; model = store.library.preferences.model }
            .onDisappear { task?.cancel() }
    }
    private func loadModels() {
        task?.cancel(); loading = true; error = nil
        task = Task { @MainActor in
            defer { loading = false }
            do { models = try await GeminiClient(key: google.trimmingCharacters(in: .whitespacesAndNewlines)).models() }
            catch is CancellationError { } catch { self.error = error.localizedDescription }
        }
    }
}

struct ContentSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = Preferences()
    @State private var providers: [(Int, String)] = []
    @State private var loading = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("İçerik") {
                    Picker("Bilgi dili", selection: $preferences.language) { Text("Türkçe").tag("tr-TR"); Text("English").tag("en-US"); Text("Deutsch").tag("de-DE") }
                    TextField("Ülke kodu (TR, DE, US…)", text: $preferences.region).textInputAutocapitalization(.characters).autocorrectionDisabled()
                }
                Section {
                    Button("Platformları getir") { Task { await load() } }.disabled(loading)
                    if loading { ProgressView() }
                    if let error { Text(error).foregroundStyle(.orange) }
                    ForEach(providers, id: \.0) { id, name in
                        Toggle(name, isOn: Binding(get: { preferences.providers.contains(id) }, set: { enabled in if enabled { preferences.providers.append(id) } else { preferences.providers.removeAll { $0 == id } } }))
                    }
                    if !preferences.providers.isEmpty { Button("Platform filtresini kaldır") { preferences.providers = [] } }
                } header: { Text("Yayın platformları") } footer: { Text("Platform seçmezsen öneriler kısıtlanmaz. Seçersen kişisel ve AI önerileri ülkenizdeki platformlarda doğrulanır.") }
            }.navigationTitle("İçerik tercihleri").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") {
                    preferences.region = preferences.region.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    guard preferences.region.range(of: #"^[A-Z]{2}$"#, options: .regularExpression) != nil else { error = "İki harfli ülke kodu gir."; return }
                    store.preferences(preferences); if store.error == nil { dismiss() }
                } }
            }
        }.tint(Cinema.gold).preferredColorScheme(.dark).onAppear { preferences = store.library.preferences }
    }
    private func load() async {
        loading = true; error = nil; defer { loading = false }
        do { providers = try await TMDBClient(key: store.keys.tmdb, preferences: preferences).providers() }
        catch { self.error = error.localizedDescription }
    }
}

struct StatisticsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear = 0
    private var allWatched: [Entry] { store.entries.filter { $0.watched } }
    private var watched: [Entry] { allWatched.filter { e in selectedYear == 0 || e.watchedAt.map { Calendar.current.component(.year, from: $0) == selectedYear } == true } }
    private var minutes: Int {
        (selectedYear == 0 ? store.entries : watched).reduce(0) { $0 + ArchiveStatistics.minutes($1) }
    }
    private var genres: [(String, Int)] { Dictionary(grouping: watched.flatMap { $0.film.genres }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 } }
    private var years: [(Int, Int)] {
        Dictionary(grouping: allWatched.compactMap(\.watchedAt), by: { Calendar.current.component(.year, from: $0) }).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
    }
    private var directors: [(String, Int)] { Dictionary(grouping: watched.flatMap { $0.film.directors }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 } }
    private var decades: [(String, Int)] { Dictionary(grouping: watched.compactMap { Int($0.film.year).map { "\($0 / 10 * 10)’ler" } }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 } }
    private var ratings: [(Int, Int)] { Dictionary(grouping: watched.filter { $0.score > 0 }, by: { $0.score }).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("İzleme dönemi", selection: $selectedYear) { Text("Tüm zamanlar").tag(0); ForEach(years, id: \.0) { year, _ in Text(String(year)).tag(year) } }
                }
                Section("Sinema yolculuğun") {
                    LabeledContent("Arşivindeki yapımlar", value: String(store.entries.count))
                    LabeledContent("İzlenen filmler", value: String(watched.filter { $0.film.type == "movie" }.count))
                    LabeledContent("İzlenen diziler", value: String(watched.filter { $0.film.type == "tv" }.count))
                    LabeledContent("Favoriler", value: String(store.entries.filter { $0.favorite }.count))
                    LabeledContent("Tahmini izleme süresi", value: "\(minutes / 60) saat \(minutes % 60) dakika")
                    Text("Dizi süresi takip edilen bölümlerden hesaplanır. Bölüm süresi bilinmiyorsa 45 dakika varsayılır. Tarihi bilinmeyen izlemeler yıllık grafiğe eklenmez.").font(.caption).foregroundStyle(Cinema.muted)
                }
                if !genres.isEmpty {
                    Section("En çok izlediğin türler") {
                        Chart(Array(genres.prefix(8)), id: \.0) { name, count in BarMark(x: .value("Yapım", count), y: .value("Tür", name)).foregroundStyle(Cinema.gold) }.frame(height: 240)
                    }
                }
                if !directors.isEmpty {
                    Section("En çok izlediğin yönetmenler") { ForEach(Array(directors.prefix(8)), id: \.0) { name, count in LabeledContent(name, value: String(count)) } }
                }
                if !decades.isEmpty {
                    Section("Yapımların dönemleri") {
                        Chart(decades, id: \.0) { decade, count in BarMark(x: .value("Dönem", decade), y: .value("Yapım", count)).foregroundStyle(Cinema.gold) }.frame(height: 180)
                    }
                }
                if !ratings.isEmpty {
                    Section("Puan dağılımın") {
                        Chart(ratings, id: \.0) { score, count in BarMark(x: .value("Puan", String(score)), y: .value("Yapım", count)).foregroundStyle(Cinema.gold) }.frame(height: 180)
                    }
                }
                if !years.isEmpty {
                    Section("Yıllara göre izlemelerin") {
                        Chart(years, id: \.0) { year, count in BarMark(x: .value("Yıl", String(year)), y: .value("Yapım", count)).foregroundStyle(Cinema.gold) }.frame(height: 180)
                    }
                }
            }.navigationTitle("İstatistiklerim").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Bitti") { dismiss() } } }
        }.tint(Cinema.gold).preferredColorScheme(.dark)
    }
}
