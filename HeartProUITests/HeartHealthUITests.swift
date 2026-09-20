import XCTest

final class HeartHealthUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testLandingHistoryFilterAndDailyHeartHealth() throws {
        let app = launch(demo: false)
        XCTAssertTrue(app.buttons["connectHealth"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["更了解自己的心跳"].exists)
        capture("health-landing")
        app.buttons["enterDemo"].tap()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        capture("health-timeline")
        XCTAssertFalse(app.staticTexts["类似 I 导联"].exists)
        XCTAssertFalse(app.staticTexts["100% 可分析"].exists)
        XCTAssertFalse(app.staticTexts["节律参考分 100"].exists)
        app.buttons["timelineCalendar"].tap()
        XCTAssertTrue(app.datePickers["historyDatePicker"].waitForExistence(timeout: 5))
        capture("health-calendar")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["clearDateFilter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["nextHistoryDay"].isEnabled)
        app.buttons["previousHistoryDay"].tap()
        XCTAssertTrue(app.buttons["nextHistoryDay"].isEnabled)
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 5))
        capture("health-history-day")
        app.buttons["clearDateFilter"].tap()
        app.buttons["dailyOverview"].tap()
        XCTAssertTrue(app.navigationBars["每日心脏健康"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["日常平均心率"].exists)
        capture("health-daily")
        app.segmentedControls["insightsSection"].buttons["趋势"].tap()
        XCTAssertTrue(app.buttons["trendMetric-bpm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["时段平均心率的中位数"].exists)
        capture("health-trends")
    }

    @MainActor func testReferencesAndECGHRVPlot() throws {
        let app = launch(demo: true)
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        let pr = app.buttons["segment-pr"]
        scrollTo(pr, app: app); pr.tap()
        let reference = app.staticTexts["成人参考：PR 120–200 ms"]
        scrollTo(reference, app: app)
        XCTAssertTrue(reference.exists)
        capture("health-pr-reference")
        // Collapse using the same header before continuing down the document.
        if !pr.isHittable { app.swipeDown() }
        pr.tap()
        let hrv = app.buttons["hrvHelp"]
        scrollTo(hrv, app: app)
        let plot = app.otherElements["ecgHRVPlot"]
        scrollTo(plot, app: app)
        XCTAssertTrue(plot.exists)
        capture("health-ecg-hrv")
        XCTAssertTrue(app.staticTexts["RMSSD"].exists)
        app.swipeDown()
        scrollTo(hrv, app: app); hrv.tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5))
        capture("health-hrv-method")
    }

    @MainActor func testWaveformFullscreenRotationAndSharedViewport() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch(demo: true)
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        XCTAssertTrue(app.buttons["expandWaveform"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["waveformAnnotations"].exists)
        XCTAssertFalse(app.staticTexts["Apple 分类"].exists)
        XCTAssertFalse(app.staticTexts["25 mm/s · 10 mm/mV"].exists)
        app.buttons["expandWaveform"].tap()
        let close = app.buttons["closeFullscreenWaveform"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 8), .completed)
        let fullscreen = app.otherElements["fullscreenWaveform"]
        XCTAssertTrue(fullscreen.otherElements["waveformAnnotations"].exists)
        let zoom = fullscreen.staticTexts["waveformZoom"]
        let previousZoom = zoom.label
        fullscreen.buttons["放大波形"].tap()
        XCTAssertNotEqual(zoom.label, previousZoom)
        let fullscreenZoom = zoom.label
        capture("detail-fullscreen-waveform")
        close.tap()
        XCTAssertTrue(app.buttons["expandWaveform"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["waveformZoom"].label, fullscreenZoom)
        let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.height > app.frame.width
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portrait], timeout: 8), .completed)
        capture("detail-inline-waveform")
    }

    @MainActor func testLargeGermanHistoryAndDailyHealth() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--large-text", "--dark", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        capture("health-large-de-timeline")
        app.buttons["dailyOverview"].tap()
        XCTAssertTrue(app.navigationBars["Tägliche Herzgesundheit"].waitForExistence(timeout: 5))
        capture("health-large-de-daily")
    }

    @MainActor private func launch(demo: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"] + (demo ? ["--demo"] : [])
        app.launch(); return app
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
