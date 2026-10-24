import XCTest

final class UsageGuideUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testEveryLanguageCanOpenSourcesFromOperationalGuide() {
        for language in ["zh-Hans", "en", "ja", "ko", "de", "es"] {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting", "--reset-guide", language == "de" ? "--dark" : "--light",
                                   "-AppleLanguages", "(\(language))"]
            if language == "de" { app.launchArguments.append("--large-text") }
            app.launchHeartPro()
            XCTAssertTrue(app.buttons["guideNext"].waitForExistence(timeout: 20), language)
            for _ in 0..<3 { app.buttons["guideNext"].tap() }
            let sourceButton = app.buttons["openHealthReferences"]
            for _ in 0..<8 { if sourceButton.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(sourceButton.isHittable, language)
            let guide = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            guide.name = "operational-guide-" + language; guide.lifetime = .keepAlways; add(guide)
            sourceButton.tap()
            let catalog = app.descendants(matching: .any)["healthReferenceCatalog"].firstMatch
            XCTAssertTrue(catalog.waitForExistence(timeout: 5), language)
            let apple = catalog.descendants(matching: .any)["healthReference-A1"].firstMatch
            for _ in 0..<8 { if apple.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(apple.isHittable, language)
            let sources = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            sources.name = "health-sources-" + language; sources.lifetime = .keepAlways; add(sources)
            let sdnn = catalog.descendants(matching: .any)["healthReference-A3"].firstMatch
            for _ in 0..<16 { if sdnn.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(sdnn.isHittable, language)
            let end = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            end.name = "health-sources-bottom-" + language; end.lifetime = .keepAlways; add(end)
            app.terminate()
        }
    }

    @MainActor func testFirstEntryCompletionPersistenceAndSettingsReplay() {
        let app = XCUIApplication()
        let arguments = ["--uitesting", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchArguments = arguments + ["--reset-guide"]
        app.launchHeartPro()
        XCTAssertTrue(app.staticTexts["查看当日记录与趋势"].waitForExistence(timeout: 15))
        app.buttons["guideNext"].tap()
        XCTAssertTrue(app.staticTexts["按日期打开一条记录"].exists)
        app.buttons["guidePrevious"].tap()
        XCTAssertTrue(app.staticTexts["查看当日记录与趋势"].exists)
        for _ in 0..<3 { app.buttons["guideNext"].tap() }
        XCTAssertTrue(app.staticTexts["添加备忘与分享报告"].exists)
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
        XCTAssertTrue(app.staticTexts["查看当日记录与趋势"].waitForExistence(timeout: 5))
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
