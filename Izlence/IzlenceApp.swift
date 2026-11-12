import SwiftUI
import UniformTypeIdentifiers

@main struct IzlenceApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store).preferredColorScheme(.dark) } }
}

enum Cinema {
    static let background = Color(red: 6/255, green: 24/255, blue: 32/255)
    static let surface = Color(red: 13/255, green: 37/255, blue: 46/255)
    static let gold = Color(red: 245/255, green: 181/255, blue: 74/255)
    static let muted = Color(red: 179/255, green: 197/255, blue: 204/255)
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            navigation { HomeView() }.tabItem { Label("Ana Sayfa", systemImage: "house") }.tag(0)
            navigation { DiscoverView() }.tabItem { Label("Keşfet", systemImage: "safari") }.tag(1)
            navigation { ArchiveView() }.tabItem { Label("Arşivim", systemImage: "square.stack") }.tag(2)
            navigation { ListsView() }.tabItem { Label("Listeler", systemImage: "list.bullet.rectangle") }.tag(3)
            navigation { ProfileView() }.tabItem { Label("Profil", systemImage: "person.crop.circle") }.tag(4)
        }
        .tint(Cinema.gold)
        .alert("İşlem tamamlanamadı", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("Tamam", role: .cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
        .safeAreaInset(edge: .top, spacing: 0) {
            if store.busy {
                HStack { ProgressView().tint(Cinema.gold); Text(store.progress).font(.footnote); Spacer(); Button("İptal") { store.cancel() }.frame(minHeight: 44) }
                    .padding(.horizontal).background(Cinema.surface)
            }
        }
        .task(id: tab) { if [0, 2, 3].contains(tab) { await store.refreshTV() } }
    }
    private func navigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().background(Cinema.background)
                .navigationDestination(for: Film.self) { DetailView(initial: $0) }
                .toolbarBackground(Cinema.background, for: .navigationBar)
        }
        // The system TabView supplies Liquid Glass on iOS 26+ and native material on iOS 17–18.
        // Do not paint an opaque tab-bar background over the system material.
    }
}

struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("Logo").resizable().scaledToFit().frame(width: 56, height: 56).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("İzlence").font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(Cinema.gold)
                Text("Senin sinema evrenin").font(.subheadline).foregroundStyle(Cinema.muted)
            }
            Spacer()
        }
    }
}

struct FilmArt: View {
    var film: Film
    var wide = false
    @EnvironmentObject private var store: AppStore
    private var localName: String { "\(film.id)-\(wide ? "backdrop" : "poster")" }
    private var path: String { wide ? film.backdrop : film.poster }
    var body: some View {
        Group {
            if store.catalog.contains(where: { $0.id == film.id }) {
                Image(localName).resizable().scaledToFill()
            } else if !path.isEmpty, let url = URL(string: "https://image.tmdb.org/t/p/\(wide ? "w780" : "w342")\(path)") {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { placeholder }
            } else { placeholder }
        }.accessibilityHidden(true)
    }
    private var placeholder: some View {
        Rectangle().fill(Cinema.surface).overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(Cinema.muted) }
    }
}

struct FilmCard: View {
    var film: Film
    var body: some View {
        NavigationLink(value: film) {
            VStack(alignment: .leading, spacing: 8) {
                FilmArt(film: film).frame(width: 136, height: 196).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) { Text(film.rating, format: .number.precision(.fractionLength(1))).font(.caption.bold()).padding(6).background(.ultraThinMaterial, in: Capsule()).padding(8) }
                Text(film.title).font(.subheadline.bold()).lineLimit(2).foregroundStyle(.white)
                Text("\(film.year) · \(film.label)").font(.caption).foregroundStyle(Cinema.muted)
            }.frame(width: 136, alignment: .topLeading)
        }.buttonStyle(.plain).accessibilityElement(children: .combine)
    }
}

struct FilmShelf: View {
    var title: String
    var subtitle = ""
    var films: [Film]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.title2.bold()); if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(Cinema.muted) } }.padding(.horizontal, 20)
            ScrollView(.horizontal) { LazyHStack(alignment: .top, spacing: 16) { ForEach(films) { FilmCard(film: $0) } }.padding(.horizontal, 20) }.scrollIndicators(.hidden)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var hero = 0
    private var highlights: [Film] { [693134, 157336, 872585].compactMap { id in store.catalog.first { $0.number == id } } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                BrandHeader().padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu akşam ne izlesek?").font(.title.bold())
                    Text("Bir sonraki favorini birlikte bulalım.").foregroundStyle(Cinema.muted)
                }.padding(.horizontal, 20)
                if !highlights.isEmpty {
                    TabView(selection: $hero) {
                        ForEach(Array(highlights.enumerated()), id: \.element.id) { index, film in
                            NavigationLink(value: film) {
                                ZStack(alignment: .bottomLeading) {
                                    FilmArt(film: film, wide: true).frame(height: 320).clipped()
                                    LinearGradient(colors: [.clear, Cinema.background.opacity(0.95)], startPoint: .center, endPoint: .bottom)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("GECENİN SEÇİMİ").font(.caption.bold()).tracking(2).foregroundStyle(Cinema.gold)
                                        Text(film.title).font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(.white)
                                        Text("\(film.year)  ·  ★ \(film.rating.formatted(.number.precision(.fractionLength(1))))  ·  \(film.label)").font(.subheadline).foregroundStyle(Cinema.muted)
                                        Label("Yapımı keşfet", systemImage: "arrow.up.right").font(.subheadline.bold()).foregroundStyle(Cinema.gold).padding(.top, 4)
                                    }.padding(24).padding(.bottom, 16)
                                }.clipShape(RoundedRectangle(cornerRadius: 24)).padding(.horizontal, 20)
                            }.buttonStyle(.plain).tag(index)
                        }
                    }.tabViewStyle(.page(indexDisplayMode: .automatic)).frame(height: 320)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { counts }
                    VStack(spacing: 12) { counts }
                }.padding(.horizontal, 20)
                if !store.entries.filter({ $0.tracking }).isEmpty {
                    FilmShelf(title: "Kaldığın yerden", subtitle: "Takip ettiğin diziler", films: store.entries.filter { $0.tracking }.map(\.film))
                }
                FilmShelf(title: "Sinemanın iz bırakanları", subtitle: "Arşivine ekleyeceğin yeni hikâyeler", films: store.catalog.filter { $0.type == "movie" })
                FilmShelf(title: "Bir bölüm daha", films: store.catalog.filter { $0.type == "tv" })
                Text("Film bilgileri ve görseller TMDB tarafından sağlanır. Bu ürün TMDB API’sini kullanır; TMDB tarafından onaylanmış veya sertifikalandırılmış değildir.")
                    .font(.caption).foregroundStyle(Cinema.muted).padding(.horizontal, 20)
            }.padding(.vertical, 16).padding(.bottom, 24).frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
        }.navigationTitle("").toolbar(.hidden, for: .navigationBar)
    }
    @ViewBuilder private var counts: some View {
        count("İzledim", number: store.entries.filter { $0.watched }.count, icon: "checkmark.circle")
        count("İzleyeceğim", number: store.entries.filter { $0.watchlist }.count, icon: "bookmark")
        count("Favoriler", number: store.entries.filter { $0.favorite }.count, icon: "heart")
    }
    private func count(_ title: String, number: Int, icon: String) -> some View {
        VStack(spacing: 8) { Image(systemName: icon).foregroundStyle(Cinema.gold); Text(number.formatted()).font(.title2.bold()); Text(title).font(.caption).foregroundStyle(Cinema.muted) }
            .frame(maxWidth: .infinity).padding(16).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 20)).accessibilityElement(children: .combine)
    }
}

struct FilmRow: View {
    var film: Film
    var subtitle = ""
    var body: some View {
        NavigationLink(value: film) {
            HStack(spacing: 16) {
                FilmArt(film: film).frame(width: 64, height: 92).clipped().clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 6) {
                    Text(film.title).font(.headline).foregroundStyle(.white)
                    Text("\(film.year) · \(film.label) · ★ \(film.rating.formatted(.number.precision(.fractionLength(1))))").font(.caption).foregroundStyle(Cinema.muted)
                    if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(Cinema.muted) }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Cinema.muted)
            }.padding(12).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityElement(children: .combine)
    }
}

struct EmptyState: View {
    var title: String; var message: String; var icon = "film"
    var body: some View {
        VStack(spacing: 16) { Image(systemName: icon).font(.system(size: 40)).foregroundStyle(Cinema.gold).accessibilityHidden(true); Text(title).font(.title3.bold()); Text(message).foregroundStyle(Cinema.muted).multilineTextAlignment(.center) }.padding(32).frame(maxWidth: .infinity)
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var store: AppStore
    @State private var mode = "Ara"
    @State private var query = ""
    @State private var results: [Film] = []
    @State private var page = 1
    @State private var loading = false
    @State private var searchError: String?
    @State private var submittedQuery = ""
    @State private var ask = ""
    @State private var consent = false
    @State private var searchTask: Task<Void, Never>?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Keşif türü", selection: $mode) { Text("Ara").tag("Ara"); Text("Sana Özel").tag("Sana Özel"); Text("AI Önerileri").tag("AI Önerileri") }.pickerStyle(.segmented)
                if mode == "Ara" { searchSection }
                else if mode == "Sana Özel" {
                    Text("Zevkine yeni bir pencere").font(.title2.bold())
                    Text("Favorilerin ve puanlarından yola çıkan kişisel öneriler. Google AI anahtarı gerekmez.").foregroundStyle(Cinema.muted)
                    Button("Önerileri yenile", systemImage: "sparkles") { store.perform { try await store.recommendations() } }.buttonStyle(.borderedProminent).disabled(store.busy)
                    picks(store.library.recommendations)
                } else { aiSection }
            }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.navigationTitle("Keşfet").onDisappear { searchTask?.cancel() }
            .confirmationDialog("Gemini’ye öneri isteği gönderilsin mi?", isPresented: $consent, titleVisibility: .visible) {
                Button("Gönder ve öneri hazırla") { store.perform { try await store.generateAI(ask) } }
            } message: { Text("Yapım adları, puanlar, favoriler, türler, zevk özeti ve buradaki isteğin Google’a gönderilir. Kişisel notların gönderilmez. Kendi Google AI kotan kullanılır.") }
    }
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("Yapım, kişi veya IMDb kimliği", text: $query).textFieldStyle(.roundedBorder).submitLabel(.search).onSubmit { search(reset: true) }.accessibilityIdentifier("search-field")
                Button { search(reset: true) } label: { Image(systemName: "magnifyingglass").frame(width: 44, height: 44) }.accessibilityLabel("Ara")
            }
            if store.keys.tmdb.isEmpty { Text("Şimdilik örnek katalogda arıyorsun. Tüm yapımlar için Profil’den TMDB anahtarını ekle.").font(.footnote).foregroundStyle(Cinema.muted) }
            if loading { HStack { ProgressView(); Text("Yapımlar aranıyor…"); Spacer(); Button("İptal") { searchTask?.cancel() } } }
            if let searchError { Text(searchError).foregroundStyle(.orange); Button("Yeniden dene") { search(reset: true) } }
            if results.isEmpty && !loading { EmptyState(title: submittedQuery.isEmpty ? "Bir hikâye ara" : "Sonuç bulunamadı", message: "Film, dizi, yönetmen, oyuncu veya tt ile başlayan IMDb kimliği yaz.", icon: "magnifyingglass") }
            LazyVStack(spacing: 12) { ForEach(results) { FilmRow(film: $0) } }
            if !results.isEmpty && !store.keys.tmdb.isEmpty { Button("Daha fazla sonuç") { search(reset: false) }.disabled(loading).frame(minHeight: 44) }
        }
    }
    private func search(reset: Bool) {
        searchTask?.cancel(); let text = (reset ? query : submittedQuery).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if reset { page = 1; results = []; submittedQuery = text }; searchError = nil
        guard !store.keys.tmdb.isEmpty else { results = store.catalog.filter { $0.title.localizedCaseInsensitiveContains(text) || $0.original.localizedCaseInsensitiveContains(text) }; return }
        let nextPage = reset ? 1 : page + 1; let client = store.tmdb; loading = true
        searchTask = Task { @MainActor in
            defer { if !Task.isCancelled { loading = false } }
            do {
                let found = try await client.search(text, page: nextPage); try Task.checkCancellation()
                var seen = Set(results.map(\.id)); results += found.filter { seen.insert($0.id).inserted }; page = nextPage
            } catch is CancellationError { } catch { if !Task.isCancelled { searchError = error.localizedDescription } }
        }
    }
    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Sinemayı senin gözünden", systemImage: "sparkles").font(.title2.bold()).foregroundStyle(Cinema.gold)
            Text("Arşivini tanıyan Gemini, her önerinin neden sana uygun olduğunu anlatır.").foregroundStyle(Cinema.muted)
            TextField("Bu akşam nasıl bir şey izlemek istersin?", text: $ask, axis: .vertical).lineLimit(2...5).padding(16).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 16))
            Button("AI önerilerimi hazırla", systemImage: "sparkles") { consent = true }.buttonStyle(.borderedProminent).disabled(store.busy)
            if !store.library.model.isEmpty { Text("Son kullanılan model: \(store.library.model)").font(.caption).foregroundStyle(Cinema.muted) }
            if !store.library.memory.isEmpty { DisclosureGroup("Zevk hafızam") { Text(store.library.memory).font(.subheadline); Button("Hafızayı sıfırla", role: .destructive) { store.apply { $0.memory = ""; $0.aiPicks = []; $0.model = "" } } } }
            picks(store.library.aiPicks)
        }
    }
    @ViewBuilder private func picks(_ items: [Pick]) -> some View {
        if items.isEmpty { EmptyState(title: "Yeni favorin burada başlayabilir", message: "Arşivine yapımlar ekle, puan ver ve önerilerini hazırla.", icon: "sparkles") }
        ForEach(items) { pick in
            VStack(alignment: .leading, spacing: 8) {
                FilmRow(film: pick.film, subtitle: pick.reason)
                HStack { Button("İzleyeceğim", systemImage: "bookmark") { store.toggle(pick.film, flag: "watchlist") }; Spacer(); Button("İlgilenmiyorum") { store.dismiss(pick.film) } }.font(.subheadline).frame(minHeight: 44)
            }
        }
    }
}

struct ArchiveView: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter = "Tümü"
    @State private var query = ""
    @State private var sort = "Son eklenen"
    private var filtered: [Entry] {
        let list = store.entries.filter { e in
            (query.isEmpty || e.film.title.localizedCaseInsensitiveContains(query)) &&
            (filter == "Tümü" || filter == "Filmler" && e.film.type == "movie" || filter == "Diziler" && e.film.type == "tv" || filter == "Belgeseller" && e.film.genreIDs.contains(99))
        }
        return sort == "Puana göre" ? list.sorted { $0.score > $1.score } : sort == "Ada göre" ? list.sorted { $0.film.title.localizedStandardCompare($1.film.title) == .orderedAscending } : list.sorted { $0.addedAt > $1.addedAt }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Yapım türü", selection: $filter) { ForEach(["Tümü", "Filmler", "Diziler", "Belgeseller"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                HStack { Text("\(filtered.count) yapım").foregroundStyle(Cinema.muted); Spacer(); Picker("Sıralama", selection: $sort) { ForEach(["Son eklenen", "Ada göre", "Puana göre"], id: \.self) { Text($0) } } }
                if filtered.isEmpty { EmptyState(title: "Arşivin seni bekliyor", message: "Keşfet’ten yapım ekle veya Profil’den Android/web yedeğini aktar.", icon: "square.stack") }
                LazyVStack(spacing: 12) { ForEach(filtered) { e in FilmRow(film: e.film, subtitle: status(e)) } }
            }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.navigationTitle("Arşivim").searchable(text: $query, prompt: "Arşivinde ara")
    }
    private func status(_ e: Entry) -> String {
        var parts: [String] = []; if e.watched { parts.append("İzlendi") }; if e.favorite { parts.append("Favori") }; if e.watchlist { parts.append("İzlenecek") }; if e.score > 0 { parts.append("Puanın \(e.score)/10") }; return parts.joined(separator: " · ")
    }
}

struct ListsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter = "İzleyeceğim"
    private var entries: [Entry] { store.entries.filter {
        switch filter { case "İzledim": return $0.watched; case "Favoriler": return $0.favorite; case "Dizi Takibi": return $0.tracking; default: return $0.watchlist }
    } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal) { HStack { ForEach(["İzleyeceğim", "İzledim", "Favoriler", "Dizi Takibi", "Seriler"], id: \.self) { item in
                    Button(item) { filter = item }.buttonStyle(.bordered).tint(filter == item ? Cinema.gold : Cinema.muted).frame(minHeight: 44)
                } } }.scrollIndicators(.hidden)
                if filter == "Seriler" {
                    Button("Serileri tara", systemImage: "square.stack.3d.up") { store.perform { try await store.scanCollections() } }.buttonStyle(.borderedProminent).disabled(store.busy)
                    ForEach(store.library.collections) { collection in
                        DisclosureGroup {
                            ForEach(collection.parts) { f in FilmRow(film: f, subtitle: store.library.entries[f.id]?.watched == true ? "İzlendi" : "Henüz izlenmedi") }
                        } label: {
                            VStack(alignment: .leading) { Text(collection.name).font(.headline); Text("\(collection.parts.filter { store.library.entries[$0.id]?.watched == true }.count)/\(collection.parts.count) izlendi").font(.caption).foregroundStyle(Cinema.muted) }
                        }.padding(16).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if store.library.collections.isEmpty { EmptyState(title: "Hikâyenin devamı var", message: "Arşivindeki filmlerden serileri ve eksik parçaları bul.", icon: "square.stack.3d.up") }
                } else {
                    if entries.isEmpty { EmptyState(title: "Bu liste henüz boş", message: "Bir yapımın ayrıntısından listelerine ekleyebilirsin.", icon: "list.bullet.rectangle") }
                    LazyVStack(spacing: 12) { ForEach(entries) { e in
                        FilmRow(film: e.film, subtitle: e.tracking ? "S\(e.season) B\(e.episode)\(e.hasNewEpisode ? " · Yeni bölüm var" : "")" : "")
                    } }
                }
            }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.navigationTitle("Listeler")
    }
}
