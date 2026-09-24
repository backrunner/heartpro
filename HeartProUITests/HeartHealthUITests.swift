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
        XCTAssertTrue(app.navigationBars["每日记录"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["日常平均心率"].exists)
        capture("health-daily")
        app.segmentedControls["insightsSection"].buttons["趋势"].tap()
        XCTAssertTrue(app.staticTexts["trendTitle-bpm"].waitForExistence(timeout: 5))
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
        app.launchHeartPro()
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        capture("health-large-de-timeline")
        app.buttons["dailyOverview"].tap()
        XCTAssertTrue(app.navigationBars["Tägliche Aufzeichnungen"].waitForExistence(timeout: 5))
        capture("health-large-de-daily")
        app.segmentedControls["insightsSection"].buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.segmentedControls["trendRange"].waitForExistence(timeout: 5))
        app.segmentedControls["trendRange"].buttons.element(boundBy: 1).tap()
        capture("health-large-de-weekly-trend")
        let date = app.buttons["insightsDate"].label
        swipePeriod(app.scrollViews["insightsContent"], forward: false)
        waitForDateChange(app, from: date)
        capture("health-large-de-previous-quarter")
        let sdnnTitle = app.staticTexts["trendTitle-hrv"]
        scrollTo(sdnnTitle, app: app)
        app.scrollViews["insightsContent"].swipeUp()
        capture("health-large-de-stacked-sdnn")
    }

    @MainActor func testWholeDailyContentSwipesAndVerticalScrolling() {
        let app = launch(demo: true)
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        app.buttons["dailyOverview"].tap()
        let date = app.buttons["insightsDate"]
        XCTAssertTrue(date.waitForExistence(timeout: 5))
        let today = date.label
        XCTAssertFalse(app.buttons["nextInsightsPeriod"].isEnabled)
        let chart = app.otherElements["dailyHeartRateChart"]
        scrollTo(chart, app: app)
        swipePeriod(chart, forward: false)
        waitForDateChange(app, from: today)
        XCTAssertTrue(app.buttons["nextInsightsPeriod"].isEnabled)
        swipePeriod(chart, forward: true)
        waitForDate(app, equalTo: today)
        swipePeriod(chart, forward: true)
        XCTAssertEqual(date.label, today)
        let record = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "dailyECG-")).firstMatch
        let content = app.scrollViews["insightsContent"]
        let tabBar = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame : .zero
        let visibleBottom = tabBar.minY > content.frame.midY ? tabBar.minY : content.frame.maxY
        for _ in 0..<8 {
            if record.isHittable && record.frame.maxY < visibleBottom - 20 { break }
            content.swipeUp()
        }
        XCTAssertTrue(record.isHittable)
        XCTAssertLessThan(record.frame.maxY, visibleBottom - 20)
        XCTAssertEqual(date.label, today, "Vertical scrolling must not change the date")
        capture("health-daily-records-before-swipe")
        swipePeriod(record, forward: false)
        waitForDateChange(app, from: today)
        capture("health-daily-records-after-swipe")
        XCTAssertTrue(app.navigationBars["每日记录"].exists, "Swiping a record must not open it")
        scrollTo(record, app: app)
        record.tap()
        XCTAssertTrue(app.buttons["expandWaveform"].waitForExistence(timeout: 10), "A normal tap must still open the ECG")
    }

    @MainActor func testTrendWindowsChartSwipesSelectionAndEmptyContent() {
        let app = launch(demo: true)
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        app.buttons.matching(identifier: "趋势").firstMatch.tap()
        let range = app.segmentedControls["trendRange"]
        XCTAssertTrue(range.waitForExistence(timeout: 5))
        let chart = app.otherElements["heartHealthTrendChart-bpm"]
        XCTAssertEqual(range.buttons.count, 3)
        for (title, count) in [("日", 14), ("周", 13), ("月", 12)] {
            range.buttons[title].tap()
            let ready = NSPredicate { _, _ in chart.exists && chart.label.contains("\(count) 个有效数据点") }
            expectation(for: ready, evaluatedWith: nil)
            waitForExpectations(timeout: 10)
            let current = app.buttons["insightsDate"].label
            XCTAssertFalse(app.buttons["nextInsightsPeriod"].isEnabled)
            capture("health-trend-\(count)-buckets")
            swipePeriod(chart, forward: false)
            waitForDateChange(app, from: current)
            let previous = app.buttons["insightsDate"].label
            app.buttons["nextInsightsPeriod"].tap()
            waitForDate(app, equalTo: current)
            app.buttons["previousInsightsPeriod"].tap()
            waitForDate(app, equalTo: previous)
            swipePeriod(chart, forward: true)
            waitForDate(app, equalTo: current)
        }
        range.buttons["日"].tap()
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        chart.tap()
        XCTAssertTrue(app.buttons["selectedTrendPoint-bpm"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["trendMetric-bpm"].exists)
        XCTAssertFalse(app.buttons["trendMetric-hrv"].exists)
        let emptySDNN = app.staticTexts["还没有可比较的数据"]
        scrollTo(emptySDNN, app: app)
        XCTAssertTrue(app.staticTexts["trendTitle-bpm"].exists)
        XCTAssertTrue(app.staticTexts["trendTitle-hrv"].exists)
        XCTAssertTrue(emptySDNN.isHittable)
        capture("health-stacked-sdnn")
        let current = app.buttons["insightsDate"].label
        swipePeriod(emptySDNN, forward: false)
        waitForDateChange(app, from: current)
        XCTAssertFalse(app.buttons["selectedTrendPoint-bpm"].exists)
        capture("health-empty-trend-after-swipe")
        scrollTo(emptySDNN, app: app)
        swipePeriod(emptySDNN, forward: true)
        waitForDate(app, equalTo: current)
        // The blank margin outside the cards is part of the page gesture surface.
        let content = app.scrollViews["insightsContent"]
        content.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.65))
            .press(forDuration: 0.05, thenDragTo: content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)))
        waitForDateChange(app, from: current)
    }

    @MainActor func testSDNNLinkScrollsToStackedTrend() {
        let app = launch(demo: true)
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        let health = app.buttons["healthHRV"]
        scrollTo(health, app: app)
        health.tap()
        let title = app.staticTexts["trendTitle-hrv"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        expectation(for: NSPredicate { _, _ in
            title.isHittable && title.frame.minY >= app.buttons["insightsDate"].frame.maxY
        }, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.staticTexts["trendTitle-bpm"].exists)
        XCTAssertFalse(app.buttons["trendMetric-hrv"].exists)
        capture("health-sdnn-link-stacked-trend")
    }

    @MainActor private func swipePeriod(_ element: XCUIElement, forward: Bool) {
        // Keep a full page swipe even when the target is a narrow empty-state label.
        let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let halfDistance = max(100, element.frame.width * 0.3)
        let start = center.withOffset(CGVector(dx: forward ? halfDistance : -halfDistance, dy: 0))
        let end = center.withOffset(CGVector(dx: forward ? -halfDistance : halfDistance, dy: 0))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor private func waitForDateChange(_ app: XCUIApplication, from previous: String) {
        expectation(for: NSPredicate { _, _ in app.buttons["insightsDate"].label != previous }, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
    }

    @MainActor private func waitForDate(_ app: XCUIApplication, equalTo expected: String) {
        expectation(for: NSPredicate { _, _ in app.buttons["insightsDate"].label == expected }, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
    }

    @MainActor private func launch(demo: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"] + (demo ? ["--demo"] : [])
        app.launchHeartPro(); return app
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
