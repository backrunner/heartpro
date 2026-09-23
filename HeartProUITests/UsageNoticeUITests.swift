import XCTest

final class UsageNoticeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testNoticePrecedesHealthAccessPersistsAndCanBeReopened() {
        let app = XCUIApplication()
        let arguments = ["--uitesting", "--skip-guide", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchArguments = arguments + ["--reset-notice"]
        app.launch()
        XCTAssertTrue(app.staticTexts["usageNoticeTitle"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["connectHealth"].exists)
        XCTAssertFalse(app.buttons["enterDemo"].exists)
        XCTAssertTrue(app.staticTexts["usageNoticeEmergency"].exists)
        capture("zh-usage-notice")
        app.buttons["acknowledgeUsageNotice"].tap()
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = arguments
        app.launch()
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["acknowledgeUsageNotice"].exists)
        app.buttons["settings"].tap()
        let notice = app.buttons["openUsageNotice"]
        for _ in 0..<8 { if notice.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(notice.isHittable)
        notice.tap()
        XCTAssertTrue(app.staticTexts["usageNoticeTitle"].waitForExistence(timeout: 5))
        app.buttons["acknowledgeUsageNotice"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))
    }

    @MainActor func testNoticeSupportsEveryLanguageAndLargeText() {
        for language in ["en", "ja", "ko", "de", "es"] {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting", "--reset-notice", "--skip-guide", "--large-text", "--dark", "-AppleLanguages", "(\(language))"]
            app.launch()
            XCTAssertTrue(app.staticTexts["usageNoticeTitle"].waitForExistence(timeout: 20), language)
            let emergency = app.staticTexts["usageNoticeEmergency"]
            let continueButton = app.buttons["acknowledgeUsageNotice"]
            for _ in 0..<8 {
                if emergency.frame.maxY <= continueButton.frame.minY && emergency.frame.minY >= app.frame.minY + 40 { break }
                app.swipeUp()
            }
            XCTAssertTrue(emergency.isHittable, language)
            XCTAssertLessThanOrEqual(emergency.frame.maxY, continueButton.frame.minY, language)
            XCTAssertGreaterThanOrEqual(emergency.frame.minY, app.frame.minY + 40, language)
            XCTAssertTrue(continueButton.isHittable, language)
            capture("\(language)-large-usage-notice")
            app.buttons["acknowledgeUsageNotice"].tap()
            XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 10), language)
            app.terminate()
        }
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
