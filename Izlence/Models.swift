import Foundation

typealias JSON = [String: Any]

enum ArchiveError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
}

struct Film: Identifiable, Hashable {
    var number: Int
    var type: String = "movie"
    var title: String
    var original = ""
    var year = ""
    var rating: Double = 0
    var overview = ""
    var poster = ""
    var backdrop = ""
    var genres: [String] = []
    var genreIDs: [Int] = []
    var directors: [String] = []
    var cast: [String] = []
    var runtime = 0
    var seasons = 0
    var episodes = 0
    var episodeRuntime = 0
    var seasonEpisodes: [Int: Int] = [:]
    var lastEpisode: Episode?
    var nextEpisode: Episode?
    var imdbID = ""
    var trailer = ""
    var collectionID = 0
    var collectionName = ""
    var providerIDs: [Int] = []
    var providers: [String] = []
    var providerLink = ""
    var photos: [String] = []
    var fetchedAt: Double = 0
    var id: String { "\(type)-\(number)" }
    var webID: String { type == "tv" ? "tv-\(number)" : String(number) }
    var label: String { type == "tv" ? "Dizi" : genreIDs.contains(99) ? "Belgesel" : "Film" }

    static func path(_ value: String) -> String {
        value.range(of: #"^/[A-Za-z0-9._-]+$"#, options: .regularExpression) != nil ? value : ""
    }
    init(number: Int, title: String, type: String = "movie") {
        self.number = number; self.title = title; self.type = type
    }
    init(_ j: JSON) throws {
        number = j.int("id"); title = j.text("title"); type = j.text("type", "movie")
        guard number > 0, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, ["tv", "movie"].contains(type) else {
            throw ArchiveError.invalid("Yedekte geçersiz yapım var.")
        }
        original = j.text("original"); year = j.text("year"); rating = j.double("rating")
        overview = j.text("overview"); poster = Self.path(j.text("poster")); backdrop = Self.path(j.text("backdrop"))
        genres = j["genres"] as? [String] ?? []; genreIDs = j["genreIds"] as? [Int] ?? []
        directors = j["directorNames"] as? [String] ?? j.text("director").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        cast = j["castNames"] as? [String] ?? []; runtime = j.int("runtime"); seasons = j.int("seasons")
        episodes = j.int("episodes"); episodeRuntime = j.int("episodeRuntime")
        seasonEpisodes = (j["seasonEpisodes"] as? JSON ?? [:]).reduce(into: [:]) { result, item in
            if let season = Int(item.key), let count = item.value as? Int { result[season] = max(0, count) }
        }
        lastEpisode = (j["lastEpisode"] as? JSON).map(Episode.init)
        nextEpisode = (j["nextEpisode"] as? JSON).map(Episode.init)
        imdbID = j.text("imdbId"); trailer = j.text("trailer"); collectionID = j.int("collectionId")
        collectionName = j.text("collectionName"); providerIDs = j["providerIds"] as? [Int] ?? []
        providers = j["providerNames"] as? [String] ?? []; providerLink = j.text("providerLink")
        photos = (j["photos"] as? [String] ?? []).map(Self.path).filter { !$0.isEmpty }
        fetchedAt = j.double("fetchedAt")
    }
    static func tmdb(_ j: JSON, type: String? = nil, region: String = "TR") throws -> Film {
        let kind = type ?? j.text("media_type", j["name"] != nil ? "tv" : "movie")
        let credits = j["credits"] as? JSON ?? [:]
        let names = j["genres"] as? [JSON] ?? []
        let ids = names.isEmpty ? j["genre_ids"] as? [Int] ?? [] : names.map { $0.int("id") }
        let makers = kind == "tv" ? j["created_by"] as? [JSON] ?? [] : (credits["crew"] as? [JSON] ?? []).filter { $0.text("job") == "Director" }
        let watch = j["watch/providers"] as? JSON ?? [:]
        let available = (watch["results"] as? JSON)?[region] as? JSON ?? [:]
        let providers = ["flatrate", "free", "ads"].flatMap { available[$0] as? [JSON] ?? [] }
        let collection = j["belongs_to_collection"] as? JSON ?? [:]
        var f = try Film(["id": j.int("id"), "type": kind, "title": j.text(kind == "tv" ? "name" : "title"),
            "original": j.text(kind == "tv" ? "original_name" : "original_title"),
            "year": String(j.text(kind == "tv" ? "first_air_date" : "release_date").prefix(4)),
            "rating": j.double("vote_average"), "poster": j.text("poster_path"), "backdrop": j.text("backdrop_path"),
            "overview": j.text("overview"), "genres": names.map { $0.text("name") }, "genreIds": ids,
            "directorNames": makers.map { $0.text("name") }, "castNames": (credits["cast"] as? [JSON] ?? []).prefix(6).map { $0.text("name") },
            "runtime": j.int("runtime"), "seasons": j.int("number_of_seasons"), "episodes": j.int("number_of_episodes"),
            "episodeRuntime": (j["episode_run_time"] as? [Int])?.first ?? 0,
            "imdbId": j.text("imdb_id", (j["external_ids"] as? JSON)?.text("imdb_id") ?? ""),
            "collectionId": collection.int("id"), "collectionName": collection.text("name"),
            "providerIds": providers.map { $0.int("provider_id") }, "providerNames": providers.map { $0.text("provider_name") },
            "providerLink": available.text("link")])
        f.seasonEpisodes = Dictionary(uniqueKeysWithValues: (j["seasons"] as? [JSON] ?? []).filter { $0.int("season_number") > 0 }.map { ($0.int("season_number"), $0.int("episode_count")) })
        f.lastEpisode = (j["last_episode_to_air"] as? JSON).map { Episode(season: $0.int("season_number"), episode: $0.int("episode_number"), date: $0.text("air_date"), name: $0.text("name")) }
        f.nextEpisode = (j["next_episode_to_air"] as? JSON).map { Episode(season: $0.int("season_number"), episode: $0.int("episode_number"), date: $0.text("air_date"), name: $0.text("name")) }
        f.trailer = ((j["videos"] as? JSON)?["results"] as? [JSON] ?? []).first { $0.text("site") == "YouTube" && $0.text("type") == "Trailer" }?.text("key") ?? ""
        f.photos = ((j["images"] as? JSON)?["backdrops"] as? [JSON] ?? []).prefix(10).map { Self.path($0.text("file_path")) }
        if j["credits"] != nil { f.fetchedAt = Date().timeIntervalSince1970 * 1000 }
        return f
    }
    var json: JSON {
        ["id": number, "type": type, "title": title, "original": original, "year": year, "rating": rating,
         "overview": overview, "poster": poster, "backdrop": backdrop, "genres": genres, "genreIds": genreIDs,
         "directorNames": directors, "castNames": cast, "runtime": runtime, "seasons": seasons, "episodes": episodes,
         "episodeRuntime": episodeRuntime, "seasonEpisodes": Dictionary(uniqueKeysWithValues: seasonEpisodes.map { (String($0.key), $0.value) }),
         "lastEpisode": lastEpisode?.json ?? NSNull(), "nextEpisode": nextEpisode?.json ?? NSNull(),
         "imdbId": imdbID, "trailer": trailer, "collectionId": collectionID, "collectionName": collectionName,
         "providerIds": providerIDs, "providerNames": providers, "providerLink": providerLink, "photos": photos, "fetchedAt": fetchedAt]
    }
}

struct Episode: Hashable {
    var season: Int; var episode: Int; var date = ""; var name = ""
    init(season: Int, episode: Int, date: String = "", name: String = "") { self.season = season; self.episode = episode; self.date = date; self.name = name }
    init(_ j: JSON) { self.init(season: j.int("season"), episode: j.int("episode"), date: j.text("date"), name: j.text("name")) }
    var json: JSON { ["season": season, "episode": episode, "date": date, "name": name] }
}

struct Entry: Identifiable {
    var film: Film
    var watched = false; var favorite = false; var watchlist = false
    var note = ""; var score = 0
    var addedAt = Date(); var watchedAt: Date?; var updatedAt = Date()
    var season = 1; var episode = 0; var tracking = false
    var id: String { film.id }
    var hasNewEpisode: Bool {
        guard tracking, let last = film.lastEpisode, !last.date.isEmpty, last.date <= String(ISO8601DateFormatter().string(from: Date()).prefix(10)) else { return false }
        return last.season > season || last.season == season && last.episode > episode
    }
    var json: JSON {
        ["film": film.json, "watched": watched, "favorite": favorite, "watchlist": watchlist,
         "note": note, "score": score, "addedAt": addedAt.timeIntervalSince1970 * 1000,
         "updatedAt": updatedAt.timeIntervalSince1970 * 1000, "watchedAt": watchedAt.map { $0.timeIntervalSince1970 * 1000 } as Any? ?? NSNull(),
         "progress": tracking ? ["s": season, "e": episode] : NSNull()]
    }
}

struct Preferences: Equatable {
    var language = "tr-TR"; var region = "TR"; var providers: [Int] = []; var model = "auto"
    var json: JSON { ["language": language, "region": region, "providers": providers, "model": model] }
}
struct Pick: Identifiable {
    var film: Film; var reason: String
    var id: String { film.id }
    var json: JSON { ["title": film.title, "year": Int(film.year) ?? 0, "type": film.type, "reason": reason, "film": film.json] }
}
struct Collection: Identifiable { var id: Int; var name: String; var parts: [Film] }
struct Library {
    var entries: [String: Entry] = [:]
    var preferences = Preferences()
    var dismissed: Set<String> = []
    var memory = ""; var model = ""; var aiPicks: [Pick] = []
    var recommendations: [Pick] = []; var collections: [Collection] = []
    var round = 0
}

extension Dictionary where Key == String, Value == Any {
    func text(_ key: String, _ fallback: String = "") -> String { self[key] as? String ?? fallback }
    func int(_ key: String) -> Int { (self[key] as? NSNumber)?.intValue ?? Int(text(key)) ?? 0 }
    func double(_ key: String) -> Double { let value = (self[key] as? NSNumber)?.doubleValue ?? Double(text(key)) ?? 0; return value.isFinite ? value : 0 }
    func flag(_ key: String) -> Bool { self[key] as? Bool ?? false }
}

enum BackupCodec {
    static let limit = 32 * 1024 * 1024
    static func date(_ value: Any?) -> Date? {
        if let n = value as? NSNumber { return Date(timeIntervalSince1970: n.doubleValue / 1000) }
        guard let text = value as? String else { return nil }
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: text) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: text) { return d }
        let day = DateFormatter(); day.locale = Locale(identifier: "en_US_POSIX"); day.timeZone = TimeZone(secondsFromGMT: 0); day.dateFormat = "yyyy-MM-dd"
        return day.date(from: String(text.prefix(10)))
    }
    static func decode(_ bytes: Data) throws -> Library {
        guard bytes.count <= limit else { throw ArchiveError.invalid("Yedek 32 MB sınırını aşıyor.") }
        let clean = bytes.starts(with: [0xef, 0xbb, 0xbf]) ? bytes.dropFirst(3) : bytes[...]
        guard let root = try JSONSerialization.jsonObject(with: Data(clean)) as? JSON else { throw ArchiveError.invalid("Geçerli bir İzlence yedeği seç.") }
        var result = Library()
        var rows: [JSON] = []
        if ["izlence-native-v2", "izlence-native-preview-v1"].contains(root.text("format")), let native = root["entries"] as? [JSON] {
            rows = native
        } else if let movies = root["movies"] as? [String: JSON] {
            for (key, m) in movies {
                let type = m.text("mtype", key.hasPrefix("tv-") ? "tv" : "movie")
                let expected = type == "tv" ? "tv-\(m.int("id"))" : String(m.int("id"))
                guard key == expected else { throw ArchiveError.invalid("Yapım kimliği yedekle eşleşmiyor.") }
                let col = m["col"] as? JSON ?? [:]
                let film: JSON = ["id": m.int("id"), "title": m.text("title"), "type": type, "original": m.text("original_title"),
                    "year": String(m.text("release_date").prefix(4)), "poster": m.text("poster_path"), "backdrop": m.text("backdrop_path"),
                    "rating": m.double("vote_average"), "genreIds": m["genre_ids"] ?? [], "directorNames": m["directors"] ?? [],
                    "castNames": m["cast"] ?? [], "runtime": m.int("runtime"), "seasons": m.int("seasons"), "episodes": m.int("episodes"),
                    "episodeRuntime": m.int("epRuntime"), "collectionId": col.int("id"), "collectionName": col.text("name")]
                let lists = m["lists"] as? JSON ?? [:]
                rows.append(["film": film, "watched": lists.flag("watched"), "favorite": lists.flag("favorite"), "watchlist": lists.flag("watchlist"),
                    "score": m.int("myRating"), "note": m.text("note"), "progress": m["progress"] ?? NSNull(), "addedAt": m["addedAt"] ?? NSNull(), "watchedAt": m["watchedAt"] ?? NSNull()])
            }
        } else { throw ArchiveError.invalid("Geçerli bir İzlence JSON yedeği seç.") }
        guard rows.count <= 100_000 else { throw ArchiveError.invalid("Yedekte çok fazla yapım var.") }
        for row in rows {
            guard let f = row["film"] as? JSON else { throw ArchiveError.invalid("Yapım bilgisi eksik.") }
            let film = try Film(f)
            guard result.entries[film.id] == nil else { throw ArchiveError.invalid("Yedekte yinelenen yapım var.") }
            var e = Entry(film: film); e.watched = row.flag("watched"); e.favorite = row.flag("favorite"); e.watchlist = row.flag("watchlist")
            e.note = row.text("note"); e.score = min(10, max(0, row.int("score"))); e.addedAt = date(row["addedAt"]) ?? Date()
            e.watchedAt = date(row["watchedAt"]); e.updatedAt = date(row["updatedAt"]) ?? e.addedAt
            if let p = row["progress"] as? JSON { e.tracking = true; e.season = max(1, p.int("s")); e.episode = max(0, p.int("e")) }
            result.entries[e.id] = e
        }
        let native = root["native"] as? JSON ?? [:]; let keys = root["keys"] as? JSON ?? [:]
        let prefs = native["preferences"] as? JSON ?? ["language": keys.text("lang", "tr-TR"), "region": String(keys.text("lang", "tr-TR").suffix(2)), "providers": keys["providers"] ?? [], "model": keys.text("gmodel", "auto")]
        result.preferences = Preferences(language: prefs.text("language", "tr-TR"), region: prefs.text("region", "TR"), providers: prefs["providers"] as? [Int] ?? [], model: prefs.text("model", "auto"))
        result.dismissed = Set((root["dismissed"] as? [String] ?? []).map { $0.hasPrefix("tv-") || $0.hasPrefix("movie-") ? $0 : "movie-\($0)" })
        result.memory = String(root.text("aiMemory").prefix(1200)); result.model = native.text("aiModel"); result.round = native.int("recommendationRound")
        func picks(_ key: String) throws -> [Pick] { try (native[key] as? [JSON] ?? []).compactMap { j in
            guard let f = j["film"] as? JSON else { return nil }; return Pick(film: try Film(f), reason: j.text("reason"))
        } }
        result.aiPicks = try picks("aiPicks"); result.recommendations = try picks("recommendations")
        for (key, value) in root["collections"] as? [String: JSON] ?? [:] {
            guard let id = Int(key), id > 0, !result.collections.contains(where: { $0.id == id }) else { throw ArchiveError.invalid("Geçersiz veya yinelenen seri kimliği.") }
            let parts = try (value["parts"] as? [JSON] ?? []).map { j in try j["type"] != nil ? Film(j) : Film.tmdb(j, type: "movie") }
            result.collections.append(Collection(id: id, name: value.text("name"), parts: parts))
        }
        return result
    }
    static func encode(_ library: Library) throws -> Data {
        var movies: [String: JSON] = [:]
        let iso = ISO8601DateFormatter()
        for e in library.entries.values {
            let f = e.film
            movies[f.webID] = ["id": f.number, "key": f.webID, "mtype": f.type, "title": f.title, "original_title": f.original,
                "release_date": f.year, "vote_average": f.rating, "poster_path": f.poster, "backdrop_path": f.backdrop,
                "genre_ids": f.genreIDs, "directors": f.directors, "cast": f.cast, "runtime": f.runtime, "seasons": f.seasons,
                "episodes": f.episodes, "epRuntime": f.episodeRuntime, "col": ["id": f.collectionID, "name": f.collectionName],
                "lists": ["watched": e.watched, "favorite": e.favorite, "watchlist": e.watchlist], "myRating": e.score,
                "note": e.note, "addedAt": iso.string(from: e.addedAt), "watchedAt": e.watchedAt.map { iso.string(from: $0) } as Any? ?? NSNull(),
                "progress": e.tracking ? ["s": e.season, "e": e.episode] : NSNull()]
        }
        let collections = Dictionary(uniqueKeysWithValues: library.collections.map { (String($0.id), ["name": $0.name, "parts": $0.parts.map(\.json)] as JSON) })
        let root: JSON = ["format": "izlence-native-v2", "version": 1, "app": ["name": "İzlence", "version": "1.0.0-ios"],
            "updatedAt": iso.string(from: Date()), "movies": movies, "entries": library.entries.values.sorted { $0.id < $1.id }.map(\.json),
            "collections": collections, "dismissed": library.dismissed.sorted(), "aiMemory": library.memory,
            "native": ["preferences": library.preferences.json, "aiPicks": library.aiPicks.map(\.json), "recommendations": library.recommendations.map(\.json), "aiModel": library.model, "recommendationRound": library.round]]
        let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        guard bytes.count <= limit else { throw ArchiveError.invalid("Arşiv 32 MB sınırını aşıyor.") }; return bytes
    }
}
