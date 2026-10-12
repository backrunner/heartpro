import XCTest

final class RhythmUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor func testGermanLargeTextCandidates() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--rhythm-demo", "--light", "--large-text", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        scrollTo(app.buttons["ecgRecord-0"], app: app)
        app.buttons["ecgRecord-0"].tap()
        let narrow = app.buttons["ectopy-8"]
        scrollTo(narrow, app: app)
        XCTAssertTrue(narrow.label.contains("schmalem"))
        capture("de-large-premature-candidates")
        narrow.tap()
        XCTAssertTrue(app.buttons["measureWaveform"].isHittable)
        let rules = app.buttons["rhythmRules"]
        scrollTo(rules, app: app)
        XCTAssertEqual(rules.frame.width, rules.frame.height, accuracy: 1)
        XCTAssertGreaterThanOrEqual(rules.frame.width, 44)
        rules.tap()
        XCTAssertTrue(app.buttons["Fertig"].waitForExistence(timeout: 5))
        capture("de-large-rhythm-rules")
        app.buttons["Fertig"].tap()
        let u = app.buttons["segment-u"]
        scrollTo(u, app: app); u.tap()
        let beats = app.buttons["segmentBeats-u"]
        scrollTo(beats, app: app); beats.tap()
        XCTAssertTrue(app.navigationBars["U-Wellenkandidaten"].waitForExistence(timeout: 5))
        capture("de-large-u-candidate")
    }
    @MainActor func testCandidatesRulesUWaveAndOriginalTrace() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--rhythm-demo", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        let narrow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'ectopy-' AND label CONTAINS '波形较窄'")).firstMatch
        scrollTo(narrow, app: app)
        capture("premature-candidates")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'ectopy-' AND label CONTAINS '波形较宽'")).firstMatch.exists)
        narrow.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '定位 '")).firstMatch.waitForExistence(timeout: 5))
        capture("premature-original-waveform")
        let rules = app.buttons["rhythmRules"]
        scrollTo(rules, app: app)
        XCTAssertEqual(rules.frame.width, rules.frame.height, accuracy: 1)
        XCTAssertGreaterThanOrEqual(rules.frame.width, 44)
        rules.tap()
        XCTAssertTrue(app.navigationBars["评分与检测说明"].waitForExistence(timeout: 5))
        capture("rhythm-score-rules")
        app.buttons["rhythmDetailedRules"].tap()
        capture("rhythm-detailed-rules")
        app.buttons["完成"].tap()
        let u = app.buttons["segment-u"]
        scrollTo(u, app: app); u.tap()
        let beats = app.buttons["segmentBeats-u"]
        scrollTo(beats, app: app); beats.tap()
        XCTAssertTrue(app.navigationBars["U 波（疑似）"].waitForExistence(timeout: 5))
        capture("u-candidate-waveform")
    }
    @MainActor private func scrollTo(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<25 { if element.isHittable { return }; app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
