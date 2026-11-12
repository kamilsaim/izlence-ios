import XCTest

final class NavigationTests: XCTestCase {
    @MainActor func testHomeRecommendationActionsRemoveWatchedAndDismissedCards() throws {
        let app = XCUIApplication(); app.launchArguments = ["-ui-testing"]; app.launch()
        let dune = app.buttons.matching(identifier: "recommendation-menu-movie-693134").firstMatch
        XCTAssertTrue(dune.waitForExistence(timeout: 15)); dune.tap()
        app.buttons["recommendation-watched"].tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: dune)
        wait(for: [gone], timeout: 5)
        let interstellar = app.buttons.matching(identifier: "recommendation-menu-movie-157336").firstMatch
        XCTAssertTrue(interstellar.waitForExistence(timeout: 5)); interstellar.tap()
        app.buttons["recommendation-dismiss"].tap()
        let hidden = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: interstellar)
        wait(for: [hidden], timeout: 5)
        capture("09-oneri-secimleri")
        app.tabBars.buttons["Arşivim"].tap()
        XCTAssertTrue(app.buttons["film-movie-693134"].firstMatch.waitForExistence(timeout: 5))
        app.tabBars.buttons["Profil"].tap()
        XCTAssertTrue(app.buttons["Gizlediğim önerileri sıfırla (1)"].exists)
    }
    @MainActor func testHomeCategoryShortcutsAndArchiveControls() throws {
        let app = XCUIApplication(); app.launchArguments = ["-ui-testing"]
        for (key, label) in [("movie", "Film"), ("tv", "Dizi"), ("documentary", "Belgesel"), ("all", "Tümü")] {
            app.launch()
            XCTAssertTrue(app.staticTexts["Bu akşam ne izlesek?"].waitForExistence(timeout: 15))
            let shortcut = app.buttons["home-category-\(key)"]
            for _ in 0..<4 { if shortcut.exists && shortcut.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(shortcut.isHittable); shortcut.tap()
            XCTAssertTrue(app.textFields["search-field"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.segmentedControls.buttons[label].isSelected)
            app.terminate()
        }
        app.launch(); app.tabBars.buttons["Arşivim"].tap()
        for key in ["all", "movie", "tv", "documentary"] {
            let category = app.buttons["archive-category-\(key)"]
            XCTAssertTrue(category.waitForExistence(timeout: 5)); category.tap(); XCTAssertTrue(category.isSelected)
        }
        app.buttons["archive-layout"].tap(); app.buttons["archive-layout"].tap()
        app.buttons["Arşive yapım ekle"].tap()
        XCTAssertTrue(app.textFields["search-field"].waitForExistence(timeout: 5))
    }
    @MainActor func testOfflineNavigationArchiveAndScreenshots() throws {
        let app = XCUIApplication(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertTrue(app.staticTexts["Bu akşam ne izlesek?"].waitForExistence(timeout: 15))
        capture("01-ana-sayfa")
        app.tabBars.buttons["Keşfet"].tap()
        let search = app.textFields["search-field"]; XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); search.typeText("Interstellar\n")
        let result = app.buttons["film-movie-157336"].firstMatch; XCTAssertTrue(result.waitForExistence(timeout: 5)); result.tap()
        let watched = app.buttons["flag-watched"]; XCTAssertTrue(watched.waitForExistence(timeout: 5)); watched.tap()
        app.buttons["flag-favorite"].tap()
        capture("02-yapim-ayrintisi")
        let edit = app.buttons["edit-note"]; if !edit.isHittable { app.swipeUp() }; edit.tap()
        let note = app.textViews["note-editor"]; XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("iPhone test notum")
        app.buttons["save-note"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Arşivim"].tap()
        XCTAssertTrue(app.buttons["film-movie-157336"].firstMatch.waitForExistence(timeout: 5)); capture("03-arsivim")
        app.tabBars.buttons["Listeler"].tap(); app.buttons["Favoriler"].tap()
        XCTAssertTrue(app.buttons["film-movie-157336"].firstMatch.exists); capture("04-listeler")
        app.tabBars.buttons["Profil"].tap(); capture("05-profil")
        app.buttons["API ayarlarım"].tap(); XCTAssertTrue(app.secureTextFields["Google AI anahtarı"].waitForExistence(timeout: 5)); capture("06-api-ayarlari")
    }
    @MainActor func testLargeTextAndLandscapeLaunch() throws {
        let app = XCUIApplication(); app.launchArguments = ["-ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]; app.launch()
        XCTAssertTrue(app.staticTexts["Bu akşam ne izlesek?"].waitForExistence(timeout: 15)); capture("07-buyuk-yazi")
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("08-yatay")
        XCUIDevice.shared.orientation = .portrait
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
