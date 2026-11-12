import XCTest
@testable import Izlence

final class ArchiveTests: XCTestCase {
    private func bytes(_ root: JSON) throws -> Data { try JSONSerialization.data(withJSONObject: root) }
    func testAndroidRoundTripKeepsSameNumberMovieAndTVSeparate() throws {
        var movie = Entry(film: Film(number: 550, title: "Film")); movie.note = String(repeating: "Uzun not 🎬\n", count: 4000); movie.score = 9; movie.favorite = true
        var tv = Entry(film: Film(number: 550, title: "Dizi", type: "tv")); tv.tracking = true; tv.season = 2; tv.episode = 4; tv.watchedAt = Date(timeIntervalSince1970: 1700000000)
        var source = Library(); source.entries = [movie.id: movie, tv.id: tv]; source.memory = "Bilim kurgu sever"; source.preferences.region = "DE"
        let exported = try BackupCodec.encode(source); let target = try BackupCodec.decode(exported)
        XCTAssertEqual(target.entries.count, 2); XCTAssertEqual(target.entries[movie.id]?.note, movie.note)
        XCTAssertEqual(target.entries[movie.id]?.score, 9); XCTAssertEqual(target.entries[tv.id]?.episode, 4)
        XCTAssertEqual(target.preferences.region, "DE"); XCTAssertEqual(target.memory, source.memory)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: exported) as? JSON)
        XCTAssertNil(root["keys"]); XCTAssertEqual((root["movies"] as? JSON)?.count, 2)
    }
    func testBrowserBackupImportsFlagsNotesDatesAndProgress() throws {
        let source: JSON = ["movies": ["tv-1396": ["id": 1396, "title": "Breaking Bad", "mtype": "tv", "lists": ["favorite": true, "watchlist": true], "myRating": 10, "note": "Notum", "progress": ["s": 3, "e": 5], "addedAt": "2024-01-02T12:30:40.123Z"]], "keys": ["tmdb": "NEVER_IMPORT", "google": "NEVER_IMPORT", "lang": "en-US"]]
        let result = try BackupCodec.decode(bytes(source)); let entry = try XCTUnwrap(result.entries["tv-1396"])
        XCTAssertTrue(entry.favorite); XCTAssertEqual(entry.score, 10); XCTAssertEqual(entry.note, "Notum")
        XCTAssertEqual(entry.season, 3); XCTAssertEqual(entry.episode, 5); XCTAssertEqual(result.preferences.language, "en-US")
        XCTAssertEqual(Calendar(identifier: .gregorian).component(.year, from: entry.addedAt), 2024)
    }
    func testInvalidBackupRejectsInsteadOfReturningEmptyArchive() throws {
        XCTAssertThrowsError(try BackupCodec.decode(Data("{}".utf8)))
        XCTAssertThrowsError(try BackupCodec.decode(bytes(["movies": ["20": ["id": 30, "title": "Mismatch"]]])))
        let e = Entry(film: Film(number: 1, title: "Duplicate"))
        XCTAssertThrowsError(try BackupCodec.decode(bytes(["format": "izlence-native-v2", "entries": [e.json, e.json]])))
        XCTAssertThrowsError(try BackupCodec.decode(Data(repeating: 0x20, count: BackupCodec.limit + 1)))
    }
    func testBOMAndImagePaths() throws {
        let source = try bytes(["movies": [:]])
        XCTAssertNoThrow(try BackupCodec.decode(Data([0xef, 0xbb, 0xbf]) + source))
        XCTAssertEqual(Film.path("/safe123.jpg"), "/safe123.jpg")
        XCTAssertEqual(Film.path("https://evil.example/image.png"), "")
        XCTAssertEqual(Film.path("/../key"), "")
    }
    func testCSVHandlesQuotedCommasMultilineAndDuplicates() throws {
        let text = "\u{FEFF}Const,Title,Your Rating,Date Rated\r\ntt0133093,\"The, Matrix\",9,2024-02-03\r\ntt0133093,Duplicate,2,2020-01-01\r\ntt0111161,\"Multi\nline \"\"title\"\"\",10,2025-01-01\r\n"
        let rows = try IMDbCSV.parse(text)
        XCTAssertEqual(rows.count, 2); let first = try XCTUnwrap(rows.first); let second = try XCTUnwrap(rows.dropFirst().first)
        XCTAssertEqual(first.score, 9); XCTAssertNotNil(first.watchedDate)
        XCTAssertEqual(second.imdb, "tt0111161"); XCTAssertEqual(second.score, 10)
        XCTAssertThrowsError(try IMDbCSV.parse("Const,Title\ntt0133093,\"Broken"))
    }
    func testNewEpisodeUsesAirDateAndProgress() {
        var f = Film(number: 1, title: "Dizi", type: "tv"); f.lastEpisode = Episode(season: 2, episode: 3, date: "2020-01-01")
        var entry = Entry(film: f); entry.tracking = true; entry.season = 2; entry.episode = 2
        XCTAssertTrue(entry.hasNewEpisode); entry.episode = 3; XCTAssertFalse(entry.hasNewEpisode)
        entry.film.lastEpisode = Episode(season: 3, episode: 1, date: "2999-01-01"); XCTAssertFalse(entry.hasNewEpisode)
    }
    @MainActor func testStorePersistsAndInvalidImportPreservesArchive() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = AppStore(directory: folder, testing: false, loadKeys: false)
        var entry = Entry(film: Film(number: 157336, title: "Interstellar")); entry.note = "Korunacak"; entry.favorite = true
        store.save(entry); XCTAssertNil(store.error)
        XCTAssertThrowsError(try store.restore(Data("{}".utf8), replace: true))
        let reopened = AppStore(directory: folder, testing: false, loadKeys: false)
        XCTAssertEqual(reopened.entries.first?.note, "Korunacak")
        var other = Library(); let new = Entry(film: Film(number: 2, title: "Yeni")); other.entries[new.id] = new
        try reopened.restore(BackupCodec.encode(other), replace: false); XCTAssertEqual(reopened.entries.count, 2)
        XCTAssertEqual(reopened.library.entries[entry.id]?.note, "Korunacak")
    }
    @MainActor func testCorruptDiskIsNotSilentlyOverwritten() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("library-v2.json"); let invalid = Data("damaged".utf8)
        try invalid.write(to: file)
        let store = AppStore(directory: folder, testing: false, loadKeys: false); store.save(Entry(film: Film(number: 1, title: "A")))
        XCTAssertNotNil(store.error); XCTAssertEqual(try Data(contentsOf: file), invalid)
        try store.restore(BackupCodec.encode(Library()), replace: true)
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: folder.path).contains { $0.hasPrefix("recovery-") })
    }
}
