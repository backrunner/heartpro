import Foundation
import Testing
@testable import HeartProCore

@Test func localizationResolvesRegionsAndFallsBackToEnglish() {
    #expect(L10n.resolve(["es-MX"]) == "es")
    #expect(L10n.resolve(["de_AT"]) == "de")
    #expect(L10n.resolve(["zh-Hant-TW"]) == "zh-Hans")
    #expect(L10n.resolve(["fr-FR", "ja-JP"]) == "ja")
    #expect(L10n.resolve(["fr-FR"]) == "en")
    #expect(L10n.text("暂时无法测量", language: "en-GB") == "Unable to measure")
    #expect(L10n.text("暂时无法测量", language: "ja") == "測定できません")
    #expect(L10n.text("暂时无法测量", language: "ko") == "측정할 수 없음")
    #expect(L10n.text("暂时无法测量", language: "de") == "Nicht messbar")
    #expect(L10n.text("暂时无法测量", language: "es") == "No se puede medir")
    #expect(L10n.text("暂时无法测量", language: "zh-Hans") == "暂时无法测量")
}

@Test func interpolationReordersArgumentsAndPreservesTheirContents() {
    #expect(L10n.text("\(34) 次心跳中，\(33) 次可测", language: "en") == "Measurable beats: 33 of 34")
    #expect(L10n.text("\(1.25, specifier: "%.2f") 秒", language: "de") == "1,25 s")
    #expect(L10n.text("\(1.25, specifier: "%.2f") 秒", language: "en") == "1.25 s")
    let userText = "{1} 100% café 日本語 한글"
    #expect(L10n.text("将写入：\(userText)", language: "en") == "Will save: " + userText)
}

@Test func languageChangesPresentationWithoutChangingSavedAnalysis() throws {
    let analysis = try SignalAnalyzer.analyze(DemoData.waveform())
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
    let before = try encoder.encode(analysis)
    let reason = "心搏前缘／基线不完整，或跨越低质量片段和采样缺口"
    for language in L10n.languages {
        try L10n.withLanguage(language) { () throws -> Void in
            #expect(!AnalysisText.readable(reason).isEmpty)
            if language != "zh-Hans" {
                #expect(AnalysisText.readable(reason) != L10n.withLanguage("zh-Hans") { AnalysisText.readable(reason) })
                #expect(SegmentAnalysis.method != L10n.withLanguage("zh-Hans") { SegmentAnalysis.method })
            }
            let after = try encoder.encode(analysis)
            #expect(after == before)
            #expect(analysis.version == ECGAnalysis.currentVersion)
        }
    }
}

@Test func savedFailuresAreTranslatedWhenDisplayed() {
    let error = SignalError.incomplete
    #expect(error.messageKey == "波形尚未完整读取，请重试。")
    L10n.withLanguage("de") {
        #expect(error.localizedDescription == "Die Kurve wurde noch nicht vollständig geladen. Bitte erneut versuchen.")
        #expect(AnalysisText.readable(error.messageKey) == error.localizedDescription)
    }
    L10n.withLanguage("ja") {
        #expect(error.localizedDescription == "波形の読み込みが未完了です。再試行してください。")
    }
}
