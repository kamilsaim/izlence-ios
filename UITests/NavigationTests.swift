import XCTest

final class NavigationTests: XCTestCase {
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
