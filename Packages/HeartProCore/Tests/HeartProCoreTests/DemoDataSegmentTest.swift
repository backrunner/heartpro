import Foundation
import Testing
@testable import HeartProCore

@Test func demoDataHasPWaveDetection() throws {
    let wave = DemoData.waveform()
    let analysis = try SignalAnalyzer.analyze(wave)
    let segments = try #require(analysis.segments)

    let pStat = segments.statistics(.pDuration)
    let prStat = segments.statistics(.prDuration)

    #expect(segments.beats.count > 20, "Should have many beats")
    #expect(pStat.count > 10, "P wave should be detected in demo data, got \(pStat.count)/\(pStat.total)")
    #expect(prStat.count > 10, "PR interval should be detected in demo data, got \(prStat.count)/\(prStat.total)")

    if pStat.count == 0 {
        Issue.record("Missing P wave reasons: \(segments.missingReasons(.p))")
    }
}
