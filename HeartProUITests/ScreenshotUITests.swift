import XCTest

/// Real app screens with the built-in, explicitly labelled synthetic examples.
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testEnglishScreenshots() throws { try captureJourney(language: "en", locale: "en_US") }
    @MainActor func testChineseScreenshots() throws { try captureJourney(language: "zh-Hans", locale: "zh_CN") }
    @MainActor func testJapaneseScreenshots() throws { try captureJourney(language: "ja", locale: "ja_JP") }
    @MainActor func testKoreanScreenshots() throws { try captureJourney(language: "ko", locale: "ko_KR") }
    @MainActor func testGermanScreenshots() throws { try captureJourney(language: "de", locale: "de_DE") }
    @MainActor func testSpanishScreenshots() throws { try captureJourney(language: "es", locale: "es_ES") }

    @MainActor private func captureJourney(language: String, locale: String) throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--light", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 60))
        capture("\(language)-01-history")
        app.buttons["dailyOverview"].tap()
        XCTAssertTrue(app.segmentedControls["insightsSection"].waitForExistence(timeout: 10))
        capture("\(language)-02-daily")
        app.segmentedControls["insightsSection"].buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.segmentedControls["trendRange"].waitForExistence(timeout: 10))
        app.segmentedControls["trendRange"].buttons.element(boundBy: 2).tap()
        capture("\(language)-03-trends")
        app.navigationBars.buttons.firstMatch.tap()
        let record = app.buttons["ecgRecord-0"]
        for _ in 0..<5 { if record.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(record.isHittable); record.tap()
        XCTAssertTrue(app.buttons["measureWaveform"].waitForExistence(timeout: 15))
        capture("\(language)-04-waveform")
        app.buttons["addNote"].tap()
        XCTAssertTrue(app.buttons["saveNote"].waitForExistence(timeout: 10))
        let coffee = app.buttons["symptom-coffee"]
        for _ in 0..<5 { if coffee.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(coffee.isHittable); coffee.tap()
        capture("\(language)-05-note")
        app.buttons["saveNote"].tap()
        XCTAssertTrue(app.buttons["addNote"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["settings"].tap()
        let privacy = app.descendants(matching: .any).matching(identifier: "privacyPolicy").firstMatch
        for _ in 0..<5 { if privacy.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(privacy.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "supportWebsite").firstMatch.exists)
        // A link can be hittable while only a few pixels are visible at the bottom.
        // Frame the About section, including policy and version, for the screenshot.
        app.swipeUp()
        XCTAssertTrue(privacy.isHittable)
        capture("\(language)-06-privacy-settings")
        app.terminate()
    }

    @MainActor private func capture(_ name: String) {
        // Allow SwiftUI chart and material rendering to finish before recording a store asset.
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
