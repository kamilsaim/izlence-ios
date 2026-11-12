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
                .navigationDestination(for: ContentCategory.self) { DiscoverView(initialCategory: $0.rawValue) }
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
        GeometryReader { geometry in
            Group {
                if store.catalog.contains(where: { $0.id == film.id }) {
                    Image(localName).resizable().scaledToFill()
                } else if !path.isEmpty, let url = URL(string: "https://image.tmdb.org/t/p/\(wide ? "w780" : "w342")\(path)") {
                    AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { placeholder }
                } else { placeholder }
            }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.accessibilityHidden(true)
    }
    private var placeholder: some View {
        Rectangle().fill(Cinema.surface).overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(Cinema.muted) }
    }
}

struct FilmCard: View {
    var film: Film
    var showRecommendationActions = true
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: film) {
                VStack(alignment: .leading, spacing: 8) {
                    FilmArt(film: film).frame(width: 136, height: 196).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .topLeading) { Text(film.rating, format: .number.precision(.fractionLength(1))).font(.caption.bold()).padding(6).background(.ultraThinMaterial, in: Capsule()).padding(8) }
                    Text(film.title).font(.subheadline.bold()).lineLimit(2).foregroundStyle(.white)
                    Text("\(film.year) · \(film.label)").font(.caption).foregroundStyle(Cinema.muted)
                }.frame(width: 136, alignment: .topLeading)
            }.buttonStyle(.plain).accessibilityElement(children: .combine)
            if showRecommendationActions { RecommendationMenu(film: film).padding(6) }
        }
    }
}

struct RecommendationMenu: View {
    var film: Film
    @EnvironmentObject private var store: AppStore
    var body: some View {
        Menu {
            Button("İzledim", systemImage: "checkmark.circle") { store.toggle(film, flag: "watched") }
                .accessibilityIdentifier("recommendation-watched")
            Button("Bunu bir daha önerme", systemImage: "eye.slash") { store.dismiss(film) }
                .accessibilityIdentifier("recommendation-dismiss")
        } label: {
            Image(systemName: "ellipsis").font(.headline).frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle()).foregroundStyle(Cinema.gold)
        }.accessibilityLabel("\(film.title) öneri seçenekleri").accessibilityIdentifier("recommendation-menu-\(film.id)")
    }
}

struct FilmShelf: View {
    var title: String
    var subtitle = ""
    var films: [Film]
    var showRecommendationActions = true
    var body: some View {
        if !films.isEmpty {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.title2.bold()); if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(Cinema.muted) } }.padding(.horizontal, 20)
            ScrollView(.horizontal) { LazyHStack(alignment: .top, spacing: 16) { ForEach(films) { FilmCard(film: $0, showRecommendationActions: showRecommendationActions) } }.padding(.horizontal, 20) }.scrollIndicators(.hidden)
        }
        }
    }
}

enum ContentCategory: String, CaseIterable, Identifiable {
    case all, movie, tv, documentary
    var id: String { rawValue }
    var title: String { switch self { case .all: "Araştır"; case .movie: "Filmler"; case .tv: "Diziler"; case .documentary: "Belgeseller" } }
    var icon: String { switch self { case .all: "magnifyingglass"; case .movie: "film"; case .tv: "tv"; case .documentary: "leaf" } }
    var color: Color { switch self { case .all: .purple; case .movie: .cyan; case .tv: .pink; case .documentary: .green } }
    func matches(_ film: Film) -> Bool { self == .all || film.type == rawValue || self == .documentary && film.genreIDs.contains(99) }
}

struct CategoryTile: View {
    let title: String
    let icon: String
    let color: Color
    var count: Int? = nil
    var selected = false
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).accessibilityHidden(true)
            Text(title).font(.caption).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if let count { Text(count.formatted()).font(.subheadline.bold()) }
        }.foregroundStyle(selected ? Cinema.gold : color).frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8).background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(selected ? Cinema.gold : color.opacity(0.25)) }
            .accessibilityElement(children: .combine)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var hero = ""
    @ScaledMetric(relativeTo: .title) private var heroHeight: CGFloat = 360
    private var available: [Film] { store.visibleRecommendations(store.catalog) }
    private var highlights: [Film] {
        let preferred = [693134, 157336, 872585].compactMap { id in store.catalog.first { $0.number == id && $0.type == "movie" } }
        return Array(store.visibleRecommendations(preferred + store.catalog).prefix(3))
    }
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
                        ForEach(highlights) { film in
                            ZStack(alignment: .topTrailing) {
                            NavigationLink(value: film) {
                                ZStack(alignment: .bottomLeading) {
                                    FilmArt(film: film, wide: true).frame(height: heroHeight).clipped()
                                    LinearGradient(colors: [.clear, Cinema.background.opacity(0.95)], startPoint: .center, endPoint: .bottom)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("GECENİN SEÇİMİ").font(.caption.bold()).tracking(2).foregroundStyle(Cinema.gold)
                                        Text(film.title).font(.system(.title, design: .serif, weight: .bold)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                                        Text("\(film.year)  ·  ★ \(film.rating.formatted(.number.precision(.fractionLength(1))))  ·  \(film.label)").font(.subheadline).foregroundStyle(Cinema.muted)
                                        Label("Yapımı keşfet", systemImage: "arrow.up.right").font(.subheadline.bold()).foregroundStyle(Cinema.gold).padding(.top, 4)
                                    }.padding(24).padding(.bottom, 16)
                                }.clipShape(RoundedRectangle(cornerRadius: 24)).padding(.horizontal, 20)
                            }.buttonStyle(.plain)
                            RecommendationMenu(film: film).padding(.top, 12).padding(.trailing, 32)
                            }.tag(film.id)
                        }
                    }.tabViewStyle(.page(indexDisplayMode: .automatic)).frame(height: heroHeight)
                } else {
                    EmptyState(title: "Yeni bir hikâye arayalım", message: "Keşfet sekmesinden yeni yapımlar bulabilirsin. İzlediklerin ve gizlediğin öneriler burada gösterilmez.", icon: "sparkles")
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 10)], spacing: 10) {
                    ForEach([ContentCategory.movie, .tv, .documentary, .all]) { category in
                        NavigationLink(value: category) { CategoryTile(title: category.title, icon: category.icon, color: category.color) }
                            .buttonStyle(.plain).accessibilityIdentifier("home-category-\(category.rawValue)")
                    }
                }.padding(.horizontal, 20)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { counts }
                    VStack(spacing: 12) { counts }
                }.padding(.horizontal, 20)
                if !store.entries.filter({ $0.tracking }).isEmpty {
                    FilmShelf(title: "Kaldığın yerden", subtitle: "Takip ettiğin diziler", films: store.entries.filter { $0.tracking && !$0.watched }.map(\.film), showRecommendationActions: false)
                }
                FilmShelf(title: "Sinemanın iz bırakanları", subtitle: "Arşivine ekleyeceğin yeni hikâyeler", films: available.filter { $0.type == "movie" })
                FilmShelf(title: "Bir bölüm daha", films: available.filter { $0.type == "tv" })
                Text("Film bilgileri ve görseller TMDB tarafından sağlanır. Bu ürün TMDB API’sini kullanır; TMDB tarafından onaylanmış veya sertifikalandırılmış değildir.")
                    .font(.caption).foregroundStyle(Cinema.muted).padding(.horizontal, 20)
            }.padding(.vertical, 16).padding(.bottom, 24).frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
        }.navigationTitle("").toolbar(.hidden, for: .navigationBar)
            .onChange(of: highlights.map(\.id), initial: true) { _, ids in if !ids.contains(hero) { hero = ids.first ?? "" } }
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
    var entry: Entry? = nil
    var body: some View {
        NavigationLink(value: film) {
            HStack(spacing: 16) {
                FilmArt(film: film).frame(width: 64, height: 92).clipped().clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 6) {
                    Text(film.title).font(.headline).foregroundStyle(.white)
                    Text("\(film.year) · \(film.label) · ★ \(film.rating.formatted(.number.precision(.fractionLength(1))))").font(.caption).foregroundStyle(Cinema.muted)
                    if let entry {
                        HStack(spacing: 12) {
                            if entry.watched { Image(systemName: "checkmark.circle.fill").accessibilityLabel("İzlendi") }
                            if entry.favorite { Image(systemName: "heart.fill").accessibilityLabel("Favori") }
                            if entry.watchlist { Image(systemName: "bookmark.fill").accessibilityLabel("İzlenecek") }
                            if !entry.note.isEmpty { Image(systemName: "note.text").accessibilityLabel("Not var") }
                        }.foregroundStyle(Cinema.gold)
                    }
                    if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(Cinema.muted) }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Cinema.muted)
            }.padding(12).background(Cinema.surface, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityElement(children: .combine).accessibilityIdentifier("film-\(film.id)")
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
    @State private var searchID = UUID()
    @State private var category: String
    init(initialCategory: String = "all") { _category = State(initialValue: initialCategory) }
    @State private var hasMore = false
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
        }.navigationTitle("Keşfet").onDisappear { cancelSearch() }
            .task { if results.isEmpty && (!store.isUITesting || category != "all") { search(reset: true) } }
            .confirmationDialog("Gemini’ye öneri isteği gönderilsin mi?", isPresented: $consent, titleVisibility: .visible) {
                Button("Gönder ve öneri hazırla") { store.perform { try await store.generateAI(ask) } }
            } message: { Text("Yapım adları, puanlar, favoriler, türler, zevk özeti ve buradaki isteğin Google’a gönderilir. Kişisel notların gönderilmez. Kendi Google AI kotan kullanılır.") }
    }
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Yapım türü", selection: $category) {
                Text("Tümü").tag("all"); Text("Film").tag("movie"); Text("Dizi").tag("tv"); Text("Belgesel").tag("documentary")
            }.pickerStyle(.segmented).onChange(of: category) { _, _ in search(reset: true) }
            HStack {
                TextField("Yapım, kişi veya IMDb kimliği", text: $query).textFieldStyle(.roundedBorder).submitLabel(.search).onSubmit { search(reset: true) }.accessibilityIdentifier("search-field")
                Button { search(reset: true) } label: { Image(systemName: "magnifyingglass").frame(width: 44, height: 44) }.accessibilityLabel("Ara")
            }
            if store.keys.tmdb.isEmpty { Text("Ortak TMDB bağlantısı kullanılıyor. Profil’den kendi anahtarını da ekleyebilirsin.").font(.footnote).foregroundStyle(Cinema.muted) }
            if loading { HStack { ProgressView(); Text("Yapımlar aranıyor…"); Spacer(); Button("İptal") { cancelSearch() } } }
            if let searchError { Text(searchError).foregroundStyle(.orange); Button("Yeniden dene") { search(reset: true) } }
            if results.isEmpty && !loading { EmptyState(title: submittedQuery.isEmpty ? "Bir hikâye ara" : "Sonuç bulunamadı", message: "Film, dizi, yönetmen, oyuncu veya tt ile başlayan IMDb kimliği yaz.", icon: "magnifyingglass") }
            LazyVStack(spacing: 12) { ForEach(results) { FilmRow(film: $0) } }
            if hasMore { Button("Daha fazla sonuç") { search(reset: false) }.disabled(loading).frame(minHeight: 44) }
        }
    }
    private func search(reset: Bool) {
        cancelSearch(); let text = (reset ? query : submittedQuery).trimmingCharacters(in: .whitespacesAndNewlines)
        if reset { page = 1; results = []; submittedQuery = text }; searchError = nil
        if store.isUITesting {
            results = store.catalog.filter { (text.isEmpty || $0.title.localizedCaseInsensitiveContains(text) || $0.original.localizedCaseInsensitiveContains(text)) && (category == "all" || $0.type == category || category == "documentary" && $0.genreIDs.contains(99)) }; hasMore = false; return
        }
        let nextPage = reset ? 1 : page + 1; let client = store.tmdb; loading = true; let requestID = searchID; let kind = category
        searchTask = Task { @MainActor in
            defer { if requestID == searchID { loading = false } }
            do {
                let found = try await client.searchPage(text, page: nextPage, category: kind); try Task.checkCancellation(); guard requestID == searchID else { return }
                var seen = Set(results.map(\.id)); results += found.films.filter { seen.insert($0.id).inserted }; page = nextPage; hasMore = found.hasMore
            } catch is CancellationError { } catch { if !Task.isCancelled { searchError = error.localizedDescription } }
        }
    }
    private func cancelSearch() { searchTask?.cancel(); searchID = UUID(); loading = false }
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
        let visible = items.filter { store.isRecommendationVisible($0.film) }
        if visible.isEmpty { EmptyState(title: "Yeni favorin burada başlayabilir", message: "Arşivine yapımlar ekle, puan ver ve önerilerini hazırla.", icon: "sparkles") }
        ForEach(visible) { pick in
            VStack(alignment: .leading, spacing: 8) {
                FilmRow(film: pick.film, subtitle: pick.reason)
                HStack { Button("İzleyeceğim", systemImage: "bookmark") { store.toggle(pick.film, flag: "watchlist") }; Spacer(); Button("Bunu bir daha önerme") { store.dismiss(pick.film) } }.font(.subheadline).frame(minHeight: 44)
            }
        }
    }
}

struct ArchiveView: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter = ContentCategory.all
    @State private var gridLayout = false
    @State private var query = ""
    @State private var sort = "Son eklenen"
    private var filtered: [Entry] {
        let list = store.entries.filter { e in
            (query.isEmpty || e.film.title.localizedCaseInsensitiveContains(query)) &&
            filter.matches(e.film)
        }
        return sort == "Puana göre" ? list.sorted { $0.score > $1.score } : sort == "Ada göre" ? list.sorted { $0.film.title.localizedStandardCompare($1.film.title) == .orderedAscending } : list.sorted { $0.addedAt > $1.addedAt }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 10)], spacing: 10) {
                    ForEach(ContentCategory.allCases) { category in
                        Button { filter = category } label: {
                            CategoryTile(title: category == .all ? "Tümü" : category.title,
                                         icon: category == .all ? "folder" : category.icon, color: category.color,
                                         count: store.entries.filter { category.matches($0.film) }.count, selected: filter == category)
                        }.buttonStyle(.plain).accessibilityIdentifier("archive-category-\(category.rawValue)")
                            .accessibilityAddTraits(filter == category ? .isSelected : [])
                    }
                }
                HStack { Text("\(filtered.count) yapım").foregroundStyle(Cinema.muted); Spacer(); Picker("Sıralama", selection: $sort) { ForEach(["Son eklenen", "Ada göre", "Puana göre"], id: \.self) { Text($0) } } }
                if filtered.isEmpty { EmptyState(title: "Arşivin seni bekliyor", message: "Keşfet’ten yapım ekle veya Profil’den Android/web yedeğini aktar.", icon: "square.stack") }
                if gridLayout {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), alignment: .top)], alignment: .leading, spacing: 20) {
                        ForEach(filtered) { e in FilmCard(film: e.film, showRecommendationActions: false) }
                    }
                } else {
                    LazyVStack(spacing: 12) { ForEach(filtered) { e in FilmRow(film: e.film, subtitle: status(e), entry: e) } }
                }
            }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.navigationTitle("Arşivim").searchable(text: $query, prompt: "Arşivinde ara")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { gridLayout.toggle() } label: { Image(systemName: gridLayout ? "list.bullet" : "square.grid.2x2") }
                        .accessibilityLabel("Görünümü değiştir").accessibilityIdentifier("archive-layout")
                    NavigationLink(value: ContentCategory.all) { Image(systemName: "plus") }.accessibilityLabel("Arşive yapım ekle")
                }
            }
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
