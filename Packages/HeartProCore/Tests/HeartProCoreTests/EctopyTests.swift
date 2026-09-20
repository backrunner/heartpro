import Foundation
import Testing
@testable import HeartProCore

private func ectopyFixture(events: [Int: Bool] = [:], varying: Bool = false, fs: Double = 500) -> Waveform {
    let peaks = (1..<30).map { index -> (Double, Bool) in
        let time = Double(index) + (events[index] == nil ? 0 : -0.35) + (varying ? 0.06 * sin(Double(index) * 0.4) : 0)
        return (time, events[index] == true)
    }
    return Waveform(samplingFrequency: fs, points: (0..<Int(31 * fs)).map { i in
        let t = Double(i) / fs
        var value = 0.0
        for (r, wide) in peaks where abs(t - r) < 0.5 {
            let x = t - r
            let knots: [(Double, Double)] = wide
                ? [(-0.10, 0), (-0.02, -1.2), (0, -1.4), (0.11, 0), (0.18, 0), (0.28, 0.25), (0.4, 0)]
                : [(-0.24, 0), (-0.19, 0.1), (-0.14, 0), (-0.04, 0), (0, 1), (0.04, 0), (0.15, 0), (0.27, 0.25), (0.40, 0)]
            for (a, b) in zip(knots, knots.dropFirst()) where x >= a.0 && x < b.0 {
                value += a.1 + (b.1 - a.1) * (x - a.0) / (b.0 - a.0)
            }
        }
        return VoltagePoint(time: t, millivolts: value)
    })
}

@Test func prematureBeatCandidatesUseTimingAndMorphology() throws {
    for fs in [250.0, 500, 1000] {
        let result = try #require(SignalAnalyzer.analyze(ectopyFixture(events: [9: false, 19: true], fs: fs)).rhythmAssessment)
        let narrow = try #require(result.candidates.first { abs($0.time - 8.65) < 0.03 })
        let wide = try #require(result.candidates.first { abs($0.time - 18.65) < 0.03 })
        #expect(narrow.candidate == .narrow)
        #expect(wide.candidate == .wide)
        #expect(result.candidates.count == 2)
        #expect(result.flagged.count == 2, "Do not count the following pause as another event")
        #expect(result.score == Int((100 * (1 - 2.0 / Double(result.evaluated.count))).rounded()))
        #expect(narrow.referenceRR == 1000)
    }
}

@Test func regularAndGradualRhythmsDoNotBecomePrematureBeats() throws {
    for varying in [false, true] {
        let result = try #require(SignalAnalyzer.analyze(ectopyFixture(varying: varying)).rhythmAssessment)
        #expect(result.candidates.isEmpty)
        #expect(result.score == 100)
    }
}

@Test func repeatingWideCandidatesDoNotRequireAFalseNormalScore() throws {
    let events = Dictionary(uniqueKeysWithValues: stride(from: 3, through: 27, by: 2).map { ($0, true) })
    let result = try #require(SignalAnalyzer.analyze(ectopyFixture(events: events)).rhythmAssessment)
    #expect(result.candidates.filter { $0.candidate == .wide }.count >= 8)
    #expect(result.score == nil)
    #expect(result.limitation == .unstableReference)
}

@Test func isolatedImpulseDoesNotBecomeAPrematureBeatOrContaminateAdjacentRR() throws {
    var wave = ectopyFixture()
    for i in wave.points.indices where abs(wave.points[i].time - 8.65) < 0.004 { wave.points[i].millivolts += 2 }
    let result = try #require(SignalAnalyzer.analyze(wave).rhythmAssessment)
    #expect(result.candidates.isEmpty)
    #expect(result.evaluated.allSatisfy { abs($0.time - 8.65) > 0.05 })
}

@Test func gapsNoiseShortRecordsAndAFNeverReceiveAnUnqualifiedScore() throws {
    var wave = ectopyFixture(events: [9: false])
    wave.points.removeAll { $0.time >= 8.4 && $0.time < 8.8 }
    let gap = try #require(SignalAnalyzer.analyze(wave).rhythmAssessment)
    #expect(gap.candidates.allSatisfy { abs($0.time - 8.65) > 0.3 })
    let short = try #require(SignalAnalyzer.analyze(DemoData.waveform(seconds: 10)).rhythmAssessment)
    #expect(short.score == nil)
    #expect(short.limitation == .insufficientSignal)
    let good = try SignalAnalyzer.analyze(ectopyFixture())
    let record = ECGRecord(date: .now, duration: 31, samplingFrequency: 500, sampleCount: 15500,
                           appleBPM: 60, classification: .atrialFibrillation, analysis: good, demoScore: 99)
    #expect(record.referenceScore == nil)
    #expect(record.rhythmAssessment?.candidates.isEmpty == true)
    #expect(record.rhythmAssessment?.limitation == .sourceClassification)
    var noise = ectopyFixture()
    for i in noise.points.indices { noise.points[i].millivolts += 0.2 * sin(noise.points[i].time * 2 * .pi * 83) }
    #expect(try SignalAnalyzer.analyze(noise).rhythmAssessment?.score == nil)
}

@Test func rhythmStorageKeepsOldResultsDecodableAndIgnoresIllustrativeScores() throws {
    let analysis = try SignalAnalyzer.analyze(ectopyFixture(events: [9: false]))
    let bytes = try JSONEncoder().encode(analysis)
    #expect(try JSONDecoder().decode(ECGAnalysis.self, from: bytes) == analysis)
    var dictionary = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    dictionary.removeValue(forKey: "rhythmAssessment"); dictionary["version"] = "0.3.0-research"
    let old = try JSONDecoder().decode(ECGAnalysis.self, from: JSONSerialization.data(withJSONObject: dictionary))
    let record = ECGRecord(date: .now, duration: 31, samplingFrequency: 500, sampleCount: 15500,
                           appleBPM: 60, classification: .sinus, isDemo: true, analysis: old, demoScore: 99)
    #expect(record.referenceScore == nil)
    #expect(old.rhythmAssessment == nil)
}
