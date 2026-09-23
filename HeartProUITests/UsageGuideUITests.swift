import XCTest

final class UsageGuideUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testFirstEntryCompletionPersistenceAndSettingsReplay() {
        let app = XCUIApplication()
        let arguments = ["--uitesting", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchArguments = arguments + ["--reset-guide"]
        app.launchHeartPro()
        XCTAssertTrue(app.staticTexts["先看今天，再看趋势"].waitForExistence(timeout: 15))
        app.buttons["guideNext"].tap()
        XCTAssertTrue(app.staticTexts["找到一条心电，读懂一次测量"].exists)
        app.buttons["guidePrevious"].tap()
        XCTAssertTrue(app.staticTexts["先看今天，再看趋势"].exists)
        for _ in 0..<3 { app.buttons["guideNext"].tap() }
        XCTAssertTrue(app.staticTexts["看懂心跳变化，记下测量时的状态"].exists)
        app.buttons["guideNext"].tap()
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = arguments
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["guideNext"].exists)
        app.buttons["settings"].tap()
        let guide = app.buttons["openUsageGuide"]
        for _ in 0..<4 { if guide.isHittable { break }; app.swipeUp() }
        guide.tap()
        XCTAssertTrue(app.staticTexts["先看今天，再看趋势"].waitForExistence(timeout: 5))
        app.buttons["guideClose"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 5))
    }

    @MainActor func testGuideWithLargeTextCanBeClosedAndReopened() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-guide", "--large-text", "--dark", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["guideNext"].waitForExistence(timeout: 15))
        for _ in 0..<3 { app.buttons["guideNext"].tap() }
        XCTAssertTrue(app.buttons["guidePrevious"].isHittable)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "guide-large-de"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["guideClose"].tap()
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 5))
    }
}
