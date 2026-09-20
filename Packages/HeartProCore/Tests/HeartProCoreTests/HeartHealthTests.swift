import Foundation
import Testing
@testable import HeartProCore

@Test func ecgHRVUsesKnownFormulaForContinuousRecording() throws {
    let analysis = try SignalAnalyzer.analyze(DemoData.waveform(bpm: 68))
    let result = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(result.unavailable == nil)
    #expect(result.duration >= 20)
    #expect(result.intervals.count >= 20)
    #expect(result.pairs.count == result.intervals.count - 1)
    let expected = try #require(Statistics.hrv(contiguousNN: result.intervals.map(\.milliseconds)))
    #expect(abs(try #require(result.sdnn) - expected.sdnn) < 1e-10)
    #expect(abs(try #require(result.rmssd) - expected.rmssd) < 1e-10)
    #expect(result.omittedCount == analysis.intervals.count - result.intervals.count)
    #expect(result.sd1 != nil && result.sd2 != nil)
}

@Test func ecgHRVRejectsUnsuitableClassificationsQualityAndTooLittleSignal() throws {
    var analysis = try SignalAnalyzer.analyze(DemoData.waveform())
    for classification in [SourceClassification.atrialFibrillation, .poorReading, .unknown, .inconclusive, .highHeartRate, .lowHeartRate] {
        let result = ECGHRV.estimate(analysis: analysis, classification: classification)
        #expect(result.unavailable == .classification)
        #expect(result.sdnn == nil && result.pairs.isEmpty)
    }
    analysis.qualityFraction = 0.5
    #expect(ECGHRV.estimate(analysis: analysis, classification: .sinus).unavailable == .quality)
    analysis.qualityFraction = 1
    analysis.rhythmAssessment?.limitation = .irregularRhythm
    #expect(ECGHRV.estimate(analysis: analysis, classification: .sinus).unavailable == .rhythm)
    analysis.rhythmAssessment?.limitation = nil
    analysis.intervals = Array(analysis.intervals.prefix(10))
    #expect(ECGHRV.estimate(analysis: analysis, classification: .sinus).unavailable == .duration)
}

@Test func ecgHRVNeverBridgesRejectedBeatOrMissingInterval() throws {
    var analysis = try SignalAnalyzer.analyze(DemoData.waveform(seconds: 60))
    let middle = analysis.intervals.count / 2
    let rejected = analysis.intervals[middle].id
    analysis.rhythmAssessment?.beats[rejected].candidate = .narrow
    let result = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(result.sdnn != nil)
    #expect(!result.intervals.contains { $0.id == rejected || $0.id == rejected + 1 })
    #expect(result.intervals.contains { $0.id < rejected })
    #expect(result.intervals.contains { $0.id > rejected + 1 })
    #expect(!result.pairs.contains { (rejected...rejected + 2).contains($0.id) })
    analysis.rhythmAssessment?.beats[rejected].candidate = nil
    analysis.intervals.remove(at: middle)
    let gap = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(gap.sdnn != nil)
    #expect(gap.intervals.count < analysis.intervals.count)
    #expect(!gap.pairs.contains { $0.id == rejected || $0.id == rejected + 1 })
}

@Test func ecgHRVThirtySecondsRetainsBothSidesOfAnExcludedInterval() throws {
    var analysis = try SignalAnalyzer.analyze(DemoData.waveform())
    let middle = analysis.intervals.count / 2
    analysis.intervals[middle].isOutlier = true
    let excluded = analysis.intervals[middle].id
    let result = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(result.unavailable == nil)
    #expect(result.duration >= 20 && result.duration < 30)
    #expect(result.intervals.contains { $0.id < excluded })
    #expect(result.intervals.contains { $0.id > excluded })
    #expect(!result.pairs.contains { $0.id == excluded || $0.id == excluded + 1 })
    let expectedSD = try #require(Statistics.sampleSD(result.intervals.map(\.milliseconds)))
    let expectedRMSSD = sqrt(result.pairs.reduce(0) { $0 + pow($1.second - $1.first, 2) } / Double(result.pairs.count))
    #expect(abs(try #require(result.sdnn) - expectedSD) < 1e-10)
    #expect(abs(try #require(result.rmssd) - expectedRMSSD) < 1e-10)
}

@Test func ecgHRVSlowThirtySecondRecordingDoesNotRequireTwentyIntervalsOrRhythmScore() throws {
    var analysis = try SignalAnalyzer.analyze(DemoData.waveform(bpm: 45))
    // The rhythm score has separate coverage rules; their failure is not an HRV veto.
    analysis.rhythmAssessment?.limitation = .insufficientBeats
    analysis.rhythmAssessment?.score = nil
    let result = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(result.unavailable == nil)
    #expect(result.intervals.count < 20)
    #expect(result.duration >= 20)
    #expect(result.rmssd != nil && !result.pairs.isEmpty)
}

@Test func ecgHRVDoesNotBridgeTimeGapsOrUseNoisyIntervals() throws {
    var analysis = try SignalAnalyzer.analyze(DemoData.waveform())
    let middle = analysis.intervals.count / 2
    let changedID = analysis.intervals[middle].id
    analysis.intervals[middle].time += 0.2
    let result = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(result.sdnn != nil)
    #expect(!result.pairs.contains { $0.id == changedID || $0.id == changedID + 1 })
    analysis.intervals[middle].milliseconds = .nan
    let invalid = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(invalid.sdnn?.isFinite == true)
    #expect(!invalid.intervals.contains { $0.id == changedID })
    for index in analysis.intervals.indices where index % 2 == 0 { analysis.intervals[index].isOutlier = true }
    let fragmented = ECGHRV.estimate(analysis: analysis, classification: .sinus)
    #expect(fragmented.unavailable == .duration)
    #expect(fragmented.pairs.isEmpty && fragmented.sdnn == nil)
}

@Test func adultReferencesRespectLimitsAndAvoidUnsupportedRanges() {
    #expect(ECGSegment.p.adultReference.position(119) == .within)
    #expect(ECGSegment.p.adultReference.position(120) == .above)
    #expect(ECGSegment.qrs.adultReference.position(120) == .above)
    #expect(ECGSegment.pr.adultReference.position(119) == .below)
    #expect(ECGSegment.pr.adultReference.position(120) == .within)
    #expect(ECGSegment.pr.adultReference.position(200) == .within)
    #expect(ECGSegment.pr.adultReference.position(201) == .above)
    #expect(ECGSegment.qtc.adultReference.position(455) == .contextRequired)
    #expect(ECGSegment.st.adultReference.position(0.2) == .contextRequired)
    #expect(ECGSegment.pr.adultReference.position(.nan) == .contextRequired)
}

@Test func dailyHealthPreservesMissingValuesAndCalendarDays() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
    let end = try #require(calendar.date(byAdding: .day, value: 1, to: start))
    #expect(end.timeIntervalSince(start) == 25 * 3600)
    let snapshot = HeartHealthSnapshot(heartRates: [
        HeartRateBucket(date: start, end: end, average: 70, minimum: 50, maximum: 120),
        HeartRateBucket(date: end, end: end.addingTimeInterval(86400), average: 71, minimum: 52, maximum: 118)
    ])
    #expect(snapshot.day(start, calendar: calendar).heartRates.count == 1)
    #expect(snapshot.day(start, calendar: calendar).hrv.isEmpty)
    #expect(snapshot.day(start.addingTimeInterval(-86400), calendar: calendar).heartRates.isEmpty)
}

@Test func lightweightRecordsKeepSummaryWithoutBeatPayload() throws {
    let record = try #require(DemoData.records().first)
    let light = record.lightweight
    #expect(light.analysis == nil && light.isAnalyzed)
    #expect(light.bpm == record.bpm)
    #expect(light.preview == record.preview)
    let bytes = try JSONEncoder().encode(light)
    #expect(try JSONDecoder().decode(ECGRecord.self, from: bytes) == light)
    #expect(bytes.count < (try JSONEncoder().encode(record)).count / 3)
}
