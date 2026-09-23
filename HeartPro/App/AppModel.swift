import SwiftUI
import SwiftData
import HeartProCore

@MainActor @Observable final class AppModel {
    let repository: ECGRepository
    let health = HealthKitGateway()
    var records: [ECGRecord] = []
    var notes: [JournalNote] = []
    var hrvSamples: [HRVSample] = []
    var todayHealth = HeartHealthSnapshot()
    var healthErrorMessage: String?
    var hasRequestedHeartHealth = false
    var dataRevision = 0
    var isLoadingHRV = false
    var totalCount = 0
    var hasMore = true
    var isLoading = false
    var isPreparingDemo = false
    var isConnecting = false
    var isSyncing = false
    var syncMessage = L10n.text("所有数据，仅在你的设备上")
    var errorMessage: String?
    var lastSynced: Date?
    var isDemo = false
    var hasConnected = false
    var hasAcknowledgedUsageNotice = false
    var selectedTab = 0
    private var demoRecords: [ECGRecord] = []
    private var demoNotes: [JournalNote] = []
    private var syncTask: Task<Void, Never>?
    private var writeTasks: Set<UUID> = []
    private var generation = 0
    var isWritingNotes: Bool { !writeTasks.isEmpty }

    init(container: ModelContainer) { repository = ECGRepository(modelContainer: container) }
    init(repository: ECGRepository) { self.repository = repository }

    func start() async {
        ReportExporter.cleanExpiredReports()
        do {
            hasConnected = try await repository.checkpoint("connected") != nil
            hasRequestedHeartHealth = try await repository.checkpoint("heart-health-access-v1") != nil
            if let bytes = try await repository.checkpoint("today-health") {
                todayHealth = (try? JSONDecoder().decode(HeartHealthSnapshot.self, from: bytes))?.day(.now) ?? HeartHealthSnapshot()
            }
            try await repository.requeueOutdatedAnalysis()
            await reload()
        } catch { errorMessage = error.localizedDescription }
        if ProcessInfo.processInfo.arguments.contains("--demo") { await enterDemo() }
    }

    func enterDemo() async {
        guard !isPreparingDemo else { return }
        isPreparingDemo = true; defer { isPreparingDemo = false }
        await stopSync(); generation += 1; isDemo = true
        if demoRecords.isEmpty { demoRecords = await Task.detached(priority: .userInitiated) { DemoData.records() }.value }
        if ProcessInfo.processInfo.arguments.contains("--rhythm-demo"), !demoRecords.isEmpty {
            let wave = DemoData.rhythmExample()
            demoRecords[0].duration = wave.duration; demoRecords[0].samplingFrequency = wave.samplingFrequency
            demoRecords[0].sampleCount = wave.points.count; demoRecords[0].appleBPM = nil
            demoRecords[0].analysis = try? SignalAnalyzer.analyze(wave)
            demoRecords[0].preview = wave.envelope(to: 6, columns: 420)
        }
        await reload()
    }

    func leaveDemo() async { generation += 1; isDemo = false; await reload() }

    func reload() async {
        let currentGeneration = generation
        do {
            let limit = max(30, records.count)
            if isDemo { records = demoRecords.prefix(limit).map(\.lightweight); notes = demoNotes; totalCount = demoRecords.count }
            else {
                let page = try await repository.page(limit: limit)
                let storedNotes = try await repository.notes()
                let count = try await repository.count()
                guard currentGeneration == generation else { return }
                records = page; notes = storedNotes; totalCount = count
            }
            hasMore = records.count < totalCount
            dataRevision += 1
        } catch { errorMessage = error.localizedDescription }
    }

    func loadMore() async {
        guard !isLoading, hasMore, let last = records.last else { return }
        let currentGeneration = generation
        isLoading = true; defer { isLoading = false }
        do {
            let next = isDemo ? demoRecords.dropFirst(records.count).prefix(30).map(\.lightweight) : try await repository.page(before: RecordCursor(date: last.date, key: last.id.uuidString))
            guard currentGeneration == generation else { return }
            let existing = Set(records.map(\.id)); records += next.filter { !existing.contains($0.id) }
            hasMore = !next.isEmpty && records.count < totalCount
        } catch { errorMessage = error.localizedDescription }
    }

    func records(on date: Date) async -> [ECGRecord] {
        if isDemo { return DailySummary(records: demoRecords, date: date).records.map(\.lightweight) }
        let start = Calendar.current.startOfDay(for: date)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        do { return try await repository.records(from: start, to: end) }
        catch { errorMessage = error.localizedDescription; return [] }
    }

    func records(from start: Date, to end: Date) async -> [ECGRecord] {
        if isDemo { return demoRecords.filter { $0.date >= start && $0.date < end } }
        do { return try await repository.records(from: start, to: end, detailed: false) }
        catch { errorMessage = error.localizedDescription; return [] }
    }

    func connect() async {
        guard !isSyncing, !isConnecting else { return }
        if isDemo { await leaveDemo() }
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await health.requestHeartHealthAccess()
            try await repository.saveCheckpoint("connected", data: Data([1]))
            try await repository.saveCheckpoint("heart-health-access-v1", data: Data([1]))
            hasConnected = true
            hasRequestedHeartHealth = true
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }

    func refresh() {
        guard !isDemo, hasConnected, !isSyncing else { return }
        isSyncing = true
        syncTask = Task { await sync() }
    }
    func cancelSync() { syncTask?.cancel() }
    private func stopSync() async {
        let running = syncTask
        running?.cancel()
        await running?.value
        syncTask = nil
    }

    private func sync() async {
        isSyncing = true; defer { isSyncing = false }
        do {
            await loadHRV()
            try Task.checkCancellation()
            syncMessage = L10n.text("正在读取最近的心电图…")
            let recent = try await health.recent()
            try Task.checkCancellation(); try await repository.apply(records: recent)
            await reload()
            var hasMoreChanges = true
            while hasMoreChanges {
                try Task.checkCancellation()
                let anchor = try await repository.checkpoint("ecg-anchor")
                let batch = try await health.changes(anchor: anchor)
                try Task.checkCancellation()
                try await repository.apply(records: batch.records, deleted: batch.deleted, anchor: batch.anchor)
                hasMoreChanges = batch.hasMore
                totalCount = try await repository.count(); syncMessage = L10n.text("已索引 \(totalCount) 条心电图")
            }
            await reload()
            var completed = 0
            while true {
                let pending = try await repository.pending()
                if pending.isEmpty { break }
                for id in pending {
                    try Task.checkCancellation()
                    syncMessage = L10n.text("正在整理波形，已处理 \(completed) 条")
                    do {
                        let wave = try await health.waveform(id)
                        let result = try await Task.detached(priority: .utility) { try SignalAnalyzer.analyze(wave) }.value
                        try Task.checkCancellation()
                        try await repository.complete(id, waveform: wave, analysis: result)
                    } catch is CancellationError { throw CancellationError() }
                    catch { try await repository.failed(id, message: (error as? any LocalizedFailure)?.messageKey ?? error.localizedDescription) }
                    completed += 1
                    if let index = records.firstIndex(where: { $0.id == id }), let value = try await repository.listRecord(id) {
                        records[index] = value
                    }
                }
            }
            lastSynced = .now; syncMessage = L10n.text("已更新 \(totalCount) 条记录")
            await reload()
        } catch is CancellationError { syncMessage = L10n.text("整理已暂停，下次打开继续") }
        catch { syncMessage = L10n.text("同步暂未完成"); errorMessage = error.localizedDescription }
    }

    func waveform(for record: ECGRecord) async throws -> Waveform {
        if record.isDemo {
            if ProcessInfo.processInfo.arguments.contains("--rhythm-demo"), record.id == demoRecords.first?.id { return DemoData.rhythmExample() }
            return DemoData.waveform(bpm: record.bpm ?? 68)
        }
        if let value = try await repository.waveform(record.id) { return value }
        return try await health.waveform(record.id)
    }

    func detailedRecord(_ record: ECGRecord) async throws -> ECGRecord {
        if record.isDemo { return demoRecords.first { $0.id == record.id } ?? record }
        return try await repository.record(record.id) ?? record
    }

    func heartHealth(from start: Date, to end: Date, hourly: Bool = false) async throws -> HeartHealthSnapshot {
        if isDemo { return DemoData.heartHealth(from: start, to: end, hourly: hourly) }
        guard hasConnected else { return HeartHealthSnapshot() }
        async let rates = health.heartRates(from: start, to: end, hourly: hourly)
        async let hrv = health.readHRV(from: start, to: end)
        return try await HeartHealthSnapshot(heartRates: rates, hrv: hrv)
    }

    func retry(_ record: ECGRecord) async {
        guard !record.isDemo else { return }
        do { try await repository.requeue(record.id); refresh() }
        catch { errorMessage = error.localizedDescription }
    }

    func saveNote(_ note: JournalNote) async -> Bool {
        do {
            if isDemo {
                if let index = demoNotes.firstIndex(where: { $0.id == note.id }) { demoNotes[index] = note }
                else { demoNotes.append(note) }
                notes = demoNotes.sorted { $0.date > $1.date }; return true
            }
            try await repository.saveNote(note); notes = try await repository.notes()
            if note.healthRequested { await writeNote(note) }
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func writeNote(_ note: JournalNote) async {
        guard !isDemo, !writeTasks.contains(note.id) else { return }
        writeTasks.insert(note.id); defer { writeTasks.remove(note.id) }
        var updated = note
        do {
            try await health.authorizeSymptoms(note.pendingSymptoms)
            for symptom in note.pendingSymptoms {
                try await health.write(symptom, note: note)
                updated.writtenSymptoms.append(symptom)
                updated.healthError = nil
                try await repository.saveNote(updated)
            }
        } catch { updated.healthError = (error as? any LocalizedFailure)?.messageKey ?? error.localizedDescription; try? await repository.saveNote(updated) }
        do { notes = try await repository.notes() } catch { errorMessage = error.localizedDescription }
    }

    func deleteNote(_ note: JournalNote) async {
        do {
            if isDemo { demoNotes.removeAll { $0.id == note.id }; notes = demoNotes }
            else { try await repository.deleteNote(note.id); notes = try await repository.notes() }
        } catch { errorMessage = error.localizedDescription }
    }

    func retryFailedAnalyses() async {
        do { try await repository.requeueFailed(); refresh() }
        catch { errorMessage = error.localizedDescription }
    }

    func loadHRV() async {
        guard !isDemo, hasConnected, !isLoadingHRV else { return }
        isLoadingHRV = true; defer { isLoadingHRV = false }
        let currentGeneration = generation
        do {
            let start = Calendar.current.startOfDay(for: .now)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
            let snapshot = try await heartHealth(from: start, to: end)
            guard !Task.isCancelled, generation == currentGeneration, !isDemo else { return }
            try await repository.saveCheckpoint("today-health", data: JSONEncoder().encode(snapshot))
            todayHealth = snapshot; hrvSamples = snapshot.hrv; healthErrorMessage = nil
            dataRevision += 1
        } catch is CancellationError { }
        catch { healthErrorMessage = error.localizedDescription }
    }

    func clearLocalData() async {
        guard !isWritingNotes else { errorMessage = L10n.text("请等待症状写入完成后再清理。"); return }
        await stopSync()
        generation += 1
        do {
            try ReportExporter.clearLocalReports()
            try await repository.clear(); hasConnected = false; hasRequestedHeartHealth = false
            hrvSamples = []; todayHealth = HeartHealthSnapshot(); healthErrorMessage = nil; lastSynced = nil
            await reload()
        } catch { errorMessage = error.localizedDescription }
    }
}
