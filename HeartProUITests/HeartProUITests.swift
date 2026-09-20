import XCTest

final class HeartProUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testSegmentAnalysisAndBeatWaveformNavigation() throws {
        let app = launch(["--demo", "--light"])
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        let p = app.buttons.matching(identifier: "segment-p").matching(NSPredicate(format: "label BEGINSWITH %@", "P 波")).firstMatch
        scrollTo(p, app: app)
        attachment(app, name: "24-segments-grouped-light")
        p.tap()
        attachment(app, name: "20-segment-p-summary")
        let metric = app.buttons["segmentMetric-p"]
        scrollTo(metric, app: app); metric.tap()
        app.buttons["P 波幅度"].tap()
        XCTAssertEqual(metric.value as? String, "P 波幅度")
        attachment(app, name: "30-segment-metric-selection")
        let beats = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "查看每次心跳")).firstMatch
        scrollTo(beats, app: app); beats.tap()
        XCTAssertTrue(app.navigationBars["P 波"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["segmentBeatWaveform"].exists)
        attachment(app, name: "21-segment-p-beat")
        app.buttons["下一次心跳"].tap()
        XCTAssertTrue((app.buttons["选择心跳"].value as? String)?.hasPrefix("第 3/") == true)
        app.buttons["选择心跳"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "第 1 次心跳")).firstMatch.tap()
        XCTAssertTrue((app.buttons["选择心跳"].value as? String)?.hasPrefix("第 1/") == true)
        XCTAssertFalse(app.buttons["上一次心跳"].isEnabled)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "这次心跳附近的波形不完整")).firstMatch.exists)
        attachment(app, name: "31-unmeasured-beat")
        app.buttons["下一次心跳"].tap()
        let locate = app.buttons["locateSegmentBeat"]
        scrollTo(locate, app: app); locate.tap()
        XCTAssertTrue(app.navigationBars["心电详情"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "定位 ")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["measureWaveform"].isHittable)
        attachment(app, name: "23-segment-locate-full-waveform")
        // Collapse the expanded P results before traversing the remaining full-record cards.
        scrollTo(p, app: app); p.tap()
        for kind in ["pr", "prSegment", "qrs", "st", "t", "qt", "qtc", "tp", "rr"] {
            let card = app.buttons["segment-\(kind)"]
            scrollTo(card, app: app)
            XCTAssertTrue(card.isHittable)
            if kind == "qtc" {
                card.tap()
                let bazett = app.staticTexts["QTc（Bazett）"].firstMatch
                scrollTo(bazett, app: app)
                attachment(app, name: "22-segment-qtc")
            }
        }
        let healthHRV = app.buttons["Apple 健康 HRV, 查看 SDNN 趋势"]
        let hrvLink = app.staticTexts["Apple 健康 HRV"]
        scrollTo(hrvLink, app: app)
        XCTAssertFalse(app.buttons["segment-u"].exists)
        attachment(app, name: "25-variability-light")
        if healthHRV.exists { healthHRV.tap() } else { hrvLink.tap() }
        XCTAssertTrue(app.segmentedControls["insightsSection"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["还没有可比较的数据"].exists)
    }

    @MainActor func testAccessibilityTextLayout() throws {
        let app = launch(["--demo", "--light", "--large-text"])
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        attachment(app, name: "14-large-text-timeline")
        let record = app.buttons["ecgRecord-0"]; scrollTo(record, app: app); record.tap()
        XCTAssertTrue(app.buttons["addNote"].waitForExistence(timeout: 5))
        attachment(app, name: "15-large-text-detail")
        let p = app.buttons["segment-p"]
        scrollTo(p, app: app)
        attachment(app, name: "26-segments-large-text")
        p.tap()
        let beats = app.buttons["segmentBeats-p"]
        scrollTo(beats, app: app); beats.tap()
        XCTAssertTrue(app.navigationBars["P 波"].waitForExistence(timeout: 5))
        attachment(app, name: "27-segment-beat-large-text")
        app.buttons["完成"].tap()
        app.buttons["addNote"].tap()
        attachment(app, name: "16-large-text-note")
        app.terminate()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--light", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        XCTAssertTrue(app.buttons["measureWaveform"].waitForExistence(timeout: 5))
        attachment(app, name: "02-ecg-detail")
        app.buttons["放大波形"].tap()
        XCTAssertTrue(app.staticTexts["1.5×"].exists)
        attachment(app, name: "17-waveform-zoom")
        app.terminate()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--dark", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        XCTAssertTrue(app.buttons["measureWaveform"].waitForExistence(timeout: 5))
        attachment(app, name: "11-detail-dark")
    }

    @MainActor func testDetailOwnsMemoEditingAndWaveformMeasurement() throws {
        let app = launch(["--demo", "--light"])
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.tabBars.buttons["备忘"].exists)
        attachment(app, name: "01-timeline")
        app.buttons["ecgRecord-0"].tap()
        XCTAssertTrue(app.navigationBars["心电详情"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["voltageAxis"].exists)
        attachment(app, name: "02-ecg-detail")
        app.buttons["measureWaveform"].tap()
        let plot = app.scrollViews["fullWaveform"]
        plot.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()
        plot.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["measurementResult"].waitForExistence(timeout: 5))
        attachment(app, name: "03-measurement")
        app.buttons["addNote"].tap()
        let coffee = app.buttons["symptom-coffee"]
        scrollTo(coffee, app: app); coffee.tap()
        attachment(app, name: "04-note-editor")
        app.buttons["saveNote"].tap()
        XCTAssertTrue(app.navigationBars["心电详情"].waitForExistence(timeout: 5))
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "editNote-")).firstMatch
        scrollTo(edit, app: app)
        XCTAssertTrue(edit.exists)
        attachment(app, name: "05-note-in-detail")
        edit.tap()
        XCTAssertTrue(app.navigationBars["编辑备忘"].waitForExistence(timeout: 5))
        let text = app.textFields["noteText"]
        scrollTo(text, app: app); text.tap(); text.typeText("ECG-specific memo")
        app.buttons["saveNote"].tap()
        XCTAssertTrue(app.staticTexts["ECG-specific memo"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        let second = app.buttons["ecgRecord-1"]; scrollTo(second, app: app); second.tap()
        XCTAssertFalse(app.staticTexts["ECG-specific memo"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["ecgRecord-0"].tap()
        scrollTo(edit, app: app); edit.tap()
        let delete = app.buttons["删除本地备忘"]; scrollTo(delete, app: app); delete.tap()
        app.sheets.buttons["删除本地备忘"].tap()
        XCTAssertTrue(app.navigationBars["心电详情"].waitForExistence(timeout: 5))
        XCTAssertFalse(edit.exists)
    }

    @MainActor func testDailyTrendsAndSettings() throws {
        let app = launch(["--demo", "--light"])
        XCTAssertTrue(app.buttons["dailyOverview"].waitForExistence(timeout: 30))
        app.buttons["dailyOverview"].tap()
        XCTAssertTrue(app.navigationBars["每日心脏健康"].waitForExistence(timeout: 5))
        attachment(app, name: "06-daily")
        app.buttons["前一天或上一时段"].tap()
        app.buttons["后一天或下一时段"].tap()
        app.segmentedControls["insightsSection"].buttons["趋势"].tap()
        XCTAssertFalse(app.buttons["参考分"].exists)
        for title in ["日", "周", "月", "年"] {
            app.segmentedControls["trendRange"].buttons[title].tap()
        }
        attachment(app, name: "07-year-trend")
        app.buttons["健康 SDNN"].tap()
        XCTAssertTrue(app.staticTexts["还没有可比较的数据"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["settings"].tap()
        attachment(app, name: "08-settings")
        let methods = app.buttons["关于分析"]
        scrollTo(methods, app: app); methods.tap()
        XCTAssertTrue(app.navigationBars["分析方法"].waitForExistence(timeout: 5))
        attachment(app, name: "09-methods")
    }

    @MainActor func testDarkWelcomeAndAnalysisPanels() throws {
        let app = launch(["--dark"])
        XCTAssertTrue(app.buttons["enterDemo"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["connectHealth"].exists)
        XCTAssertTrue(app.buttons["connectHealth"].label.contains("连接 Apple 健康"))
        XCTAssertFalse(app.staticTexts["94"].exists)
        attachment(app, name: "00-welcome-dark")
        app.buttons["enterDemo"].tap()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        attachment(app, name: "10-timeline-dark")
        app.buttons["ecgRecord-0"].tap()
        attachment(app, name: "11-detail-dark")
        let morphology = app.buttons["morphologyPanel"]
        alignNearTop(morphology, app: app); morphology.tap()
        XCTAssertTrue(app.staticTexts["参考波形"].exists)
        attachment(app, name: "12-morphology-dark")
        let segment = app.buttons["segment-pr"]
        scrollTo(segment, app: app)
        attachment(app, name: "28-segments-grouped-dark")
        let hrv = app.staticTexts["Apple 健康 HRV"]
        scrollTo(hrv, app: app)
        attachment(app, name: "13-variability-dark")
        let info = app.buttons["hrvHelp"]
        // Bring the heading back into view after reaching the bottom of the panel.
        if !info.isHittable { app.swipeDown() }
        info.tap()
        XCTAssertTrue(app.staticTexts["本次 ECG 的 HRV"].firstMatch.waitForExistence(timeout: 5))
        attachment(app, name: "29-hrv-explanation-dark")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.navigationBars["心电详情"].waitForExistence(timeout: 5))
    }

    @MainActor private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--skip-guide", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"] + arguments; app.launch(); return app
    }
    @MainActor private func scrollTo(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<14 { if element.isHittable { return }; app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func alignNearTop(_ element: XCUIElement, app: XCUIApplication) {
        scrollTo(element, app: app)
        let top = app.navigationBars.firstMatch.frame.maxY + 16
        let distance = element.frame.minY - top
        guard distance > 20 else { return }
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let startY = min(app.frame.maxY - 60, element.frame.maxY + 20)
        let start = origin.withOffset(CGVector(dx: app.frame.width - 10, dy: startY))
        let end = origin.withOffset(CGVector(dx: app.frame.width - 10, dy: max(top, startY - distance)))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    @MainActor private func attachment(_ app: XCUIApplication, name: String) {
        // XCTest can consider SwiftUI idle while the short disclosure transition is still fading.
        Thread.sleep(forTimeInterval: 0.35)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
