import Foundation
import Testing
@testable import HeartProCore

@Test func hrvUsesSampleDeviationAndAdjacentPairs() throws {
    let result = try #require(Statistics.hrv(contiguousNN: [800, 810, 790, 820]))
    #expect(abs(result.sdnn - 12.9099444874) < 0.00001)
    #expect(abs(result.rmssd - sqrt(1400.0 / 3)) < 0.00001)
    #expect(Statistics.hrv(contiguousNN: [800]) == nil)
    #expect(Statistics.hrv(contiguousNN: [800, .nan]) == nil)
}

@Test func detectorHandlesBothPolarities() throws {
    let wave = DemoData.waveform(bpm: 72)
    let inverted = Waveform(samplingFrequency: wave.samplingFrequency, points: wave.points.map { VoltagePoint(time: $0.time, millivolts: -$0.millivolts) })
    let a = try SignalAnalyzer.analyze(wave), b = try SignalAnalyzer.analyze(inverted)
    #expect(abs(try #require(a.averageBPM) - 72) < 1)
    #expect(a.peakTimes == b.peakTimes)
    #expect(a.outliers.isEmpty)
}

@Test func invalidAndFlatSignalsNeverProduceAHealthyResult() throws {
    let flat = Waveform(samplingFrequency: 256, points: (0..<2560).map { VoltagePoint(time: Double($0) / 256, millivolts: 0) })
    let result = try SignalAnalyzer.analyze(flat)
    #expect(result.averageBPM == nil)
    #expect(result.qualityFraction == 0)
    #expect(result.peakTimes.isEmpty)
    let bad = Waveform(samplingFrequency: 0, points: flat.points)
    #expect(throws: SignalError.self) { try SignalAnalyzer.analyze(bad) }
}

@Test func noRRIntervalBridgesMissingSignal() throws {
    var wave = DemoData.waveform()
    wave.points.removeAll { $0.time > 10 && $0.time < 12 }
    let result = try SignalAnalyzer.analyze(wave)
    #expect(result.qualityFraction < 1)
    #expect(result.intervals.allSatisfy { !($0.time >= 12 && $0.time - $0.milliseconds / 1000 <= 10) })
}

@Test func envelopePreservesNarrowExtrema() {
    let points = (0..<1000).map { VoltagePoint(time: Double($0) / 1000, millivolts: $0 == 401 ? 2 : $0 == 402 ? -1 : 0) }
    let output = Waveform(samplingFrequency: 1000, points: points).envelope(to: 1, columns: 20)
    #expect(output.contains { $0.millivolts == 2 })
    #expect(output.contains { $0.millivolts == -1 })
    #expect(output.count <= 40)
    #expect(zip(output.dropFirst(), output).allSatisfy { $0.time >= $1.time })
}

@Test func productionScoresAreNeverSynthesizedAndEmptyDaysAreNotZero() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let real = ECGRecord(date: date, duration: 30, samplingFrequency: 256, sampleCount: 7680, appleBPM: 70, classification: .sinus, demoScore: 99)
    #expect(real.referenceScore == nil)
    #expect(DailySummary(records: [real], date: date).score == nil)
    #expect(DailySummary(records: [], date: date).bpm == nil)
}

@Test func dailyGroupingUsesCalendarAcrossDST() throws {
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
    let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))
    let start = calendar.startOfDay(for: date)
    let end = try #require(calendar.date(byAdding: .day, value: 1, to: start))
    #expect(end.timeIntervalSince(start) == 23 * 3600)
    let record = ECGRecord(date: end.addingTimeInterval(-1), duration: 30, samplingFrequency: 256, sampleCount: 7680, appleBPM: 70, classification: .sinus)
    #expect(DailySummary(records: [record], date: date, calendar: calendar).records.count == 1)
    #expect(DailySummary(records: [record], date: end, calendar: calendar).records.isEmpty)
}

@Test func syntheticExperienceHasThreeTodayRecordsAndNeverRealData() {
    let now = Date.now
    let records = DemoData.records(now: now)
    #expect(records.count > 30)
    #expect(records.allSatisfy { $0.isDemo })
    let summary = DailySummary(records: records, date: now)
    #expect(summary.records.count == 3)
    #expect(summary.score == 100)
}

@Test func rrPairsDoNotCrossRejectedSignalAndNeverBecomeNN() throws {
    var wave = DemoData.waveform()
    wave.points.removeAll { $0.time > 10 && $0.time < 12 }
    let result = try SignalAnalyzer.analyze(wave)
    let review = try #require(result.review)
    #expect(review.pairs.count < max(0, result.intervals.count - 1))
    for pair in review.pairs {
        let left = try #require(result.intervals.first { $0.id == pair.id - 1 })
        let right = try #require(result.intervals.first { $0.id == pair.id })
        #expect(abs(right.time - right.milliseconds / 1000 - left.time) < 0.01)
    }
    #expect(result.version == ECGAnalysis.currentVersion)
}

@Test func repeatedShortLongSequencesAreDescriptiveCandidates() throws {
    let wave = DemoData.waveform()
    var result = try SignalAnalyzer.analyze(wave)
    var time = 0.0
    result.intervals = (0..<18).map { i in
        let duration = i.isMultiple(of: 2) ? 600.0 : 1000.0
        time += duration / 1000
        return RRInterval(id: i, time: time, milliseconds: duration)
    }
    let review = RhythmReview.make(waveform: wave, analysis: result)
    #expect(review.events.filter { $0.kind == .shortLong }.count == 9)
    #expect(review.events.filter { $0.kind == .repeating }.count == 1)
    #expect(abs(try #require(review.rrRMSSD) - 400) < 0.001)
}

@Test func morphologyRejectsFlatAndDetectsIsolatedAmplitudeChange() throws {
    var wave = DemoData.waveform()
    let original = try SignalAnalyzer.analyze(wave)
    #expect(original.review?.events.isEmpty == true)
    let time = try #require(original.peakTimes.dropFirst(12).first)
    for i in wave.points.indices where abs(wave.points[i].time - time) < 0.05 { wave.points[i].millivolts *= 1.8 }
    let modified = try SignalAnalyzer.analyze(wave)
    #expect(modified.review?.events.contains { $0.kind == .amplitude && abs($0.time - time) < 0.02 } == true)
    #expect(modified.review?.template.count == 71)
    #expect(modified.review?.beats.count == original.review?.beats.count)
}

@Test func oldNotesDecodeAndDurationHasAnExplicitEnd() throws {
    let original = JournalNote(recordID: UUID(), date: Date(timeIntervalSince1970: 100), text: "memo", duration: 120)
    #expect(original.endDate.timeIntervalSince(original.date) == 120)
    var dictionary = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
    dictionary.removeValue(forKey: "duration")
    let old = try JSONDecoder().decode(JournalNote.self, from: JSONSerialization.data(withJSONObject: dictionary))
    #expect(old.duration == nil)
    #expect(old.endDate == old.date)
}
