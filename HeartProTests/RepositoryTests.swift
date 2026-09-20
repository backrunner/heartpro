import XCTest
import SwiftData
import HeartProCore
import HealthKit
@testable import HeartPro

final class RepositoryTests: XCTestCase {
    func testAuthorizationBundleIncludesAllThreeReadTypes() {
        XCTAssertEqual(HealthKitGateway.readTypes, [HKObjectType.electrocardiogramType(), HKQuantityType(.heartRate), HKQuantityType(.heartRateVariabilitySDNN)])
    }

    func testLightPagesAndDirectDateLookupKeepFullDetailAvailable() async throws {
        let repository = ECGRepository(modelContainer: try ECGRepository.container(inMemory: true))
        let start = Calendar.current.startOfDay(for: .now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: start)!
        let older = Calendar.current.date(byAdding: .day, value: -500, to: start)!
        let dates = (0..<80).map { start.addingTimeInterval(Double($0)) } + [yesterday, older]
        let records = dates.map { ECGRecord(date: $0, duration: 30, samplingFrequency: 256, sampleCount: 7680, appleBPM: nil, classification: .sinus) }
        try await repository.apply(records: records)
        let wave = DemoData.waveform(), analysis = try SignalAnalyzer.analyze(wave)
        try await repository.complete(records.last!.id, waveform: wave, analysis: analysis)
        let oldEnd = Calendar.current.date(byAdding: .day, value: 1, to: older)!
        let day = try await repository.records(from: older, to: oldEnd)
        XCTAssertEqual(day.count, 1)
        XCTAssertNil(day[0].analysis)
        XCTAssertTrue(day[0].isAnalyzed)
        XCTAssertNotNil(day[0].bpm)
        XCTAssertFalse(day[0].preview.isEmpty)
        let full = try await repository.record(day[0].id)
        XCTAssertEqual(full?.analysis, analysis)
        let today = try await repository.records(from: start, to: Calendar.current.date(byAdding: .day, value: 1, to: start)!)
        XCTAssertEqual(today.count, 80)
        let previous = try await repository.records(from: yesterday, to: start)
        XCTAssertEqual(previous.map(\.date), [yesterday])
        try await repository.clear()
    }

    @MainActor func testRefreshPreservesLoadedHistoryAndClearRemovesHealthCache() async throws {
        let container = try ECGRepository.container(inMemory: true)
        let model = AppModel(container: container)
        let records = (0..<75).map { ECGRecord(date: Date.now.addingTimeInterval(-Double($0) * 60), duration: 30, samplingFrequency: 256, sampleCount: 7680, appleBPM: 65, classification: .sinus) }
        try await model.repository.apply(records: records)
        await model.reload(); await model.loadMore()
        XCTAssertEqual(model.records.count, 60)
        await model.reload()
        XCTAssertEqual(model.records.count, 60)
        XCTAssertTrue(model.hasMore)
        model.todayHealth = HeartHealthSnapshot(heartRates: [HeartRateBucket(date: .now, end: .now, average: 70, minimum: 50, maximum: 100)])
        await model.clearLocalData()
        XCTAssertTrue(model.todayHealth.heartRates.isEmpty)
        XCTAssertTrue(model.records.isEmpty)
        XCTAssertFalse(model.hasConnected)
    }

    func testReplayPaginationAndDeletionPreserveNotes() async throws {
        let container = try ECGRepository.container(inMemory: true)
        let repository = ECGRepository(modelContainer: container)
        let date = Date.now
        let records = (0..<65).map { _ in ECGRecord(date: date, duration: 30, samplingFrequency: 256, sampleCount: 7680, appleBPM: 65, classification: .sinus) }
        try await repository.apply(records: records, anchor: Data([1]))
        try await repository.apply(records: records, anchor: Data([2]))
        let count = try await repository.count(); XCTAssertEqual(count, 65)
        let first = try await repository.page()
        let last = try XCTUnwrap(first.last)
        let second = try await repository.page(before: RecordCursor(date: last.date, key: last.id.uuidString))
        XCTAssertEqual(first.count, 30); XCTAssertEqual(second.count, 30)
        XCTAssertTrue(Set(first.map(\.id)).isDisjoint(with: Set(second.map(\.id))))
        let secondLast = try XCTUnwrap(second.last)
        let third = try await repository.page(before: RecordCursor(date: secondLast.date, key: secondLast.id.uuidString))
        XCTAssertEqual(third.count, 5)
        XCTAssertEqual(Set((first + second + third).map(\.id)), Set(records.map(\.id)))
        let note = JournalNote(recordID: records[0].id, date: date, text: "本地备忘")
        try await repository.saveNote(note)
        try await repository.apply(records: [], deleted: [records[0].id], anchor: Data([3]))
        let saved = try await repository.notes(); XCTAssertEqual(saved, [note])
        let deleted = try await repository.record(records[0].id); XCTAssertNil(deleted)
        let checkpoint = try await repository.checkpoint("ecg-anchor"); XCTAssertEqual(checkpoint, Data([3]))
    }

    func testOutdatedNoteCannotReplaceNewRevision() async throws {
        let repository = ECGRepository(modelContainer: try ECGRepository.container(inMemory: true))
        var note = JournalNote(recordID: UUID(), date: .now, text: "new", revision: 3)
        try await repository.saveNote(note)
        note.revision = 2; note.text = "stale"
        try await repository.saveNote(note)
        let notes = try await repository.notes(); XCTAssertEqual(notes.first?.text, "new")
    }

    func testAnalysisUpgradeAndFailureRetryKeepNotes() async throws {
        let repository = ECGRepository(modelContainer: try ECGRepository.container(inMemory: true))
        let wave = DemoData.waveform()
        let record = ECGRecord(date: .now, duration: 30, samplingFrequency: 256, sampleCount: wave.points.count, appleBPM: 68, classification: .sinus)
        try await repository.apply(records: [record])
        var old = try SignalAnalyzer.analyze(wave); old.version = "0.1.0-research"; old.review = nil
        try await repository.complete(record.id, waveform: wave, analysis: old)
        try await repository.requeueOutdatedAnalysis()
        var pending = try await repository.pending(); XCTAssertEqual(pending, [record.id])
        try await repository.failed(record.id, message: "Interrupted")
        pending = try await repository.pending(); XCTAssertTrue(pending.isEmpty)
        let note = JournalNote(recordID: record.id, date: .now, text: "preserve", duration: 60)
        try await repository.saveNote(note)
        try await repository.requeueFailed()
        pending = try await repository.pending(); XCTAssertEqual(pending, [record.id])
        try await repository.complete(record.id, waveform: wave, analysis: SignalAnalyzer.analyze(wave))
        try await repository.requeueOutdatedAnalysis()
        pending = try await repository.pending(); XCTAssertTrue(pending.isEmpty)
        let saved = try await repository.notes(recordID: record.id); XCTAssertEqual(saved, [note])
        try await repository.clear()
    }
}
