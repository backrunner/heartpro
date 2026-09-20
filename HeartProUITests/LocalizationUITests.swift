import XCTest

final class LocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testGermanWithAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-guide", "--demo", "--light", "--large-text", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30))
        app.buttons["ecgRecord-0"].tap()
        let qrs = app.buttons["segment-qrs"]
        scrollTo(qrs, app: app)
        capture("de-large-segments")
        qrs.tap()
        let metric = app.buttons["segmentMetric-qrs"]
        scrollTo(metric, app: app)
        capture("de-large-qrs")
        metric.tap()
        let rPeak = app.buttons["QRS-Beginn bis R-Spitze"]
        XCTAssertTrue(rPeak.waitForExistence(timeout: 5))
        rPeak.tap()
        XCTAssertEqual(metric.value as? String, "QRS-Beginn bis R-Spitze")
        let beats = app.buttons["segmentBeats-qrs"]
        scrollTo(beats, app: app); beats.tap()
        XCTAssertTrue(app.navigationBars["QRS-Komplex"].waitForExistence(timeout: 5))
        capture("de-large-beat")
        app.buttons["Fertig"].tap()
        app.terminate()
    }

    @MainActor func testEveryLanguageThroughAnalysisAndHRV() throws {
        let languages: [(code: String, locale: String, done: String, p: String, unavailable: String, amplitude: String)] = [
            ("en", "en_US", "Done", "P wave", "Unable to measure", "P-wave amplitude"),
            ("ja", "ja_JP", "完了", "P波", "測定できません", "P波の振幅"),
            ("ko", "ko_KR", "완료", "P파", "측정할 수 없음", "P파 진폭"),
            ("de", "de_DE", "Fertig", "P-Welle", "Nicht messbar", "P-Amplitude"),
            ("es", "es_ES", "Listo", "Onda P", "No se puede medir", "Amplitud de P"),
            ("zh-Hans", "zh_CN", "完成", "P 波", "暂时无法测量", "P 波幅度")
        ]
        for language in languages {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting", "--skip-guide", "--demo", language.code == "ko" ? "--dark" : "--light",
                                   "-AppleLanguages", "(\(language.code))", "-AppleLocale", language.locale]
            app.launch()
            XCTAssertTrue(app.buttons["ecgRecord-0"].waitForExistence(timeout: 30), language.code)
            capture("\(language.code)-timeline")
            app.buttons["settings"].tap()
            XCTAssertTrue(app.buttons["appLanguage"].waitForExistence(timeout: 5))
            capture("\(language.code)-settings")
            app.buttons[language.done].tap()
            app.buttons["ecgRecord-0"].tap()
            XCTAssertTrue(app.buttons["measureWaveform"].waitForExistence(timeout: 5))
            capture("\(language.code)-ecg")
            let rules = app.buttons["rhythmRules"]
            scrollTo(rules, app: app)
            capture("\(language.code)-rhythm")
            rules.tap()
            XCTAssertTrue(app.buttons[language.done].waitForExistence(timeout: 5))
            capture("\(language.code)-rhythm-rules")
            app.buttons[language.done].tap()
            let p = app.buttons["segment-p"]
            scrollTo(p, app: app)
            XCTAssertTrue(p.label.contains(language.p), p.label)
            capture("\(language.code)-segments")
            p.tap()
            let metric = app.buttons["segmentMetric-p"]
            scrollTo(metric, app: app); metric.tap()
            app.buttons[language.amplitude].tap()
            XCTAssertEqual(metric.value as? String, language.amplitude)
            let beats = app.buttons["segmentBeats-p"]
            scrollTo(beats, app: app); beats.tap()
            XCTAssertTrue(app.navigationBars[language.p].waitForExistence(timeout: 5))
            app.buttons["previousBeat"].tap()
            XCTAssertFalse(app.buttons["previousBeat"].isEnabled)
            let status = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", language.unavailable)).firstMatch
            XCTAssertTrue(status.waitForExistence(timeout: 5), language.code)
            capture("\(language.code)-unavailable")
            app.buttons[language.done].tap()
            let help = app.buttons["hrvHelp"]
            scrollTo(help, app: app)
            XCTAssertFalse(app.buttons["segment-u"].exists, language.code)
            capture("\(language.code)-hrv")
            help.tap()
            XCTAssertTrue(app.buttons[language.done].waitForExistence(timeout: 5))
            capture("\(language.code)-hrv-help")
            app.buttons[language.done].tap()
            let health = app.buttons["healthHRV"]
            scrollTo(health, app: app); health.tap()
            XCTAssertTrue(app.segmentedControls["insightsSection"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["trendMetric-bpm"].exists, language.code)
            XCTAssertTrue(app.buttons["trendMetric-hrv"].exists, language.code)
            XCTAssertFalse(app.buttons["trendMetric-score"].exists, language.code)
            capture("\(language.code)-trends")
            app.terminate()
        }
    }

    @MainActor private func scrollTo(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<22 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 0.35)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
