import Foundation
import SwiftData
import HeartProCore

@Model final class RecordEntity {
    #Index<RecordEntity>([\.date, \.key])
    @Attribute(.unique) var id: UUID
    var date: Date
    var key: String
    var payload: Data
    var preview: Data?
    @Attribute(.externalStorage) var analysis: Data?
    var pending: Bool
    var analysisVersion: String?
    init(_ record: ECGRecord) throws {
        id = record.id; date = record.date; key = record.id.uuidString
        payload = try JSONEncoder().encode(record); pending = true
    }
}

@Model final class NoteEntity {
    @Attribute(.unique) var id: UUID
    var recordID: UUID
    var date: Date
    var payload: Data
    init(_ note: JournalNote) throws {
        id = note.id; recordID = note.recordID; date = note.date; payload = try JSONEncoder().encode(note)
    }
}

@Model final class CheckpointEntity {
    @Attribute(.unique) var key: String
    var data: Data
    init(key: String, data: Data) { self.key = key; self.data = data }
}

struct RecordCursor: Sendable { var date: Date; var key: String }

@ModelActor actor ECGRepository {
    private var writesSincePrune = 0
    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([RecordEntity.self, NoteEntity.self, CheckpointEntity.self])
        if inMemory { return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)) }
        let root = try protectedDirectory()
        let configuration = ModelConfiguration(schema: schema, url: root.appendingPathComponent("HeartPro.store"), cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: configuration)
        for url in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        }
        return container
    }

    static func protectedDirectory() throws -> URL {
        var root = URL.applicationSupportDirectory.appendingPathComponent("HeartPro", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try root.setResourceValues(values)
        return root
    }

    private func entity(_ id: UUID) throws -> RecordEntity? {
        var query = FetchDescriptor<RecordEntity>(predicate: #Predicate { $0.id == id })
        query.fetchLimit = 1
        return try modelContext.fetch(query).first
    }

    private func decode(_ entity: RecordEntity, detailed: Bool = true, preview: Bool = false) throws -> ECGRecord {
        var value = try JSONDecoder().decode(ECGRecord.self, from: entity.payload)
        if detailed || preview {
            value.preview = try entity.preview.map { try JSONDecoder().decode([VoltagePoint].self, from: $0) } ?? []
        }
        if detailed {
            value.analysis = try entity.analysis.map { try JSONDecoder().decode(ECGAnalysis.self, from: $0) }
        }
        return value
    }

    func apply(records: [ECGRecord], deleted: [UUID] = [], anchor: Data? = nil) throws {
        do {
            for record in records where try entity(record.id) == nil { modelContext.insert(try RecordEntity(record)) }
            for id in deleted { if let record = try entity(id) { modelContext.delete(record) } }
            if let anchor { try setCheckpoint("ecg-anchor", data: anchor) }
            try modelContext.save()
        } catch { modelContext.rollback(); throw error }
        for id in deleted { try? FileManager.default.removeItem(at: waveformURL(id)) }
    }

    func page(before: RecordCursor? = nil, limit: Int = 30) throws -> [ECGRecord] {
        var query = FetchDescriptor<RecordEntity>(sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.key, comparator: .lexical, order: .reverse)])
        if let before {
            let date = before.date, key = before.key
            query.predicate = #Predicate { $0.date < date || ($0.date == date && $0.key < key) }
        }
        query.fetchLimit = limit
        return try modelContext.fetch(query).map { try decode($0, detailed: false, preview: true) }
    }

    func records(from start: Date, to end: Date, detailed: Bool = false) throws -> [ECGRecord] {
        let query = FetchDescriptor<RecordEntity>(predicate: #Predicate { $0.date >= start && $0.date < end }, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(query).map { try decode($0, detailed: detailed, preview: true) }
    }

    func record(_ id: UUID) throws -> ECGRecord? { try entity(id).map { try decode($0) } }
    func listRecord(_ id: UUID) throws -> ECGRecord? { try entity(id).map { try decode($0, detailed: false, preview: true) } }
    func count() throws -> Int { try modelContext.fetchCount(FetchDescriptor<RecordEntity>()) }
    func hasUnfinishedAnalyses() throws -> Bool {
        var query = FetchDescriptor<RecordEntity>()
        query.propertiesToFetch = [\.pending, \.payload]
        for row in try modelContext.fetch(query) {
            if row.pending { return true }
            if try decode(row, detailed: false).failure != nil { return true }
        }
        return false
    }

    func pending() throws -> [UUID] {
        var query = FetchDescriptor<RecordEntity>(predicate: #Predicate { $0.pending }, sortBy: [SortDescriptor(\.date, order: .reverse)])
        query.fetchLimit = 100
        return try modelContext.fetch(query).map(\.id)
    }

    func complete(_ id: UUID, waveform: Waveform, analysis: ECGAnalysis) throws {
        guard let row = try entity(id) else { return }
        let encoder = PropertyListEncoder(); encoder.outputFormat = .binary
        let data = try encoder.encode(waveform)
        try data.write(to: waveformURL(id), options: [.atomic, .completeFileProtection])
        row.analysis = try JSONEncoder().encode(analysis)
        row.preview = try JSONEncoder().encode(waveform.envelope(to: 6, columns: 180))
        row.analysisVersion = analysis.version
        var summary = try decode(row, detailed: false)
        // Keep only small metadata in summary queries, not the full waveform or beat list.
        summary.failure = nil
        summary.listSummary = ECGListSummary(analysis: analysis, classification: summary.classification)
        row.payload = try JSONEncoder().encode(summary)
        row.pending = false
        do { try modelContext.save() } catch { modelContext.rollback(); throw error }
        writesSincePrune += 1
        if writesSincePrune >= 20 { try pruneWaveforms(keeping: id); writesSincePrune = 0 }
    }

    func failed(_ id: UUID, message: String) throws {
        guard let row = try entity(id) else { return }
        var record = try decode(row, detailed: false); record.failure = message
        row.payload = try JSONEncoder().encode(record); row.pending = false
        try modelContext.save()
    }

    func requeue(_ id: UUID) throws {
        guard let row = try entity(id) else { return }; row.pending = true; try modelContext.save()
    }

    func requeueOutdatedAnalysis() throws {
        for row in try modelContext.fetch(FetchDescriptor<RecordEntity>()) {
            if let version = row.analysisVersion {
                if version != ECGAnalysis.currentVersion { row.pending = true }
                continue
            }
            guard let data = row.analysis else { continue }
            let result = try? JSONDecoder().decode(ECGAnalysis.self, from: data)
            if result?.version != ECGAnalysis.currentVersion { row.pending = true }
            if let result {
                var summary = try decode(row, detailed: false)
                summary.listSummary = ECGListSummary(analysis: result, classification: summary.classification)
                row.payload = try JSONEncoder().encode(summary)
                row.analysisVersion = result.version
            }
        }
        try modelContext.save()
    }

    func requeueFailed() throws {
        for row in try modelContext.fetch(FetchDescriptor<RecordEntity>()) {
            if try decode(row, detailed: false).failure != nil { row.pending = true }
        }
        try modelContext.save()
    }

    private func waveformURL(_ id: UUID) throws -> URL {
        try Self.protectedDirectory().appendingPathComponent("\(id.uuidString).ecg")
    }
    func waveform(_ id: UUID) throws -> Waveform? {
        let url = try waveformURL(id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let waveform = try PropertyListDecoder().decode(Waveform.self, from: Data(contentsOf: url))
        try FileManager.default.setAttributes([.modificationDate: Date.now], ofItemAtPath: url.path)
        return waveform
    }

    private func pruneWaveforms(keeping id: UUID) throws {
        let urls = try FileManager.default.contentsOfDirectory(at: Self.protectedDirectory(), includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
        var entries: [(url: URL, size: Int, date: Date)] = []
        for url in urls where url.pathExtension == "ecg" {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            entries.append((url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast))
        }
        var bytes = entries.reduce(0) { $0 + $1.size }
        for entry in entries.sorted(by: { $0.date < $1.date }) where bytes > 256 * 1024 * 1024 && entry.url.lastPathComponent != "\(id.uuidString).ecg" {
            try FileManager.default.removeItem(at: entry.url); bytes -= entry.size
        }
    }

    func checkpoint(_ key: String) throws -> Data? {
        try modelContext.fetch(FetchDescriptor<CheckpointEntity>(predicate: #Predicate { $0.key == key })).first?.data
    }
    private func setCheckpoint(_ key: String, data: Data) throws {
        if let row = try modelContext.fetch(FetchDescriptor<CheckpointEntity>(predicate: #Predicate { $0.key == key })).first { row.data = data }
        else { modelContext.insert(CheckpointEntity(key: key, data: data)) }
    }
    func saveCheckpoint(_ key: String, data: Data) throws { try setCheckpoint(key, data: data); try modelContext.save() }

    func saveNote(_ note: JournalNote) throws {
        let id = note.id
        let row = try modelContext.fetch(FetchDescriptor<NoteEntity>(predicate: #Predicate { $0.id == id })).first
        if let row {
            let previous = try JSONDecoder().decode(JournalNote.self, from: row.payload)
            guard note.revision >= previous.revision else { return }
            row.date = note.date; row.payload = try JSONEncoder().encode(note)
        } else { modelContext.insert(try NoteEntity(note)) }
        try modelContext.save()
    }
    func notes(recordID: UUID? = nil) throws -> [JournalNote] {
        var query = FetchDescriptor<NoteEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        if let id = recordID { query.predicate = #Predicate { $0.recordID == id } }
        return try modelContext.fetch(query).map { try JSONDecoder().decode(JournalNote.self, from: $0.payload) }
    }
    func deleteNote(_ id: UUID) throws {
        try modelContext.delete(model: NoteEntity.self, where: #Predicate { $0.id == id }); try modelContext.save()
    }
    func clear() throws {
        try modelContext.delete(model: RecordEntity.self)
        try modelContext.delete(model: NoteEntity.self)
        try modelContext.delete(model: CheckpointEntity.self)
        try modelContext.save()
        let files = try FileManager.default.contentsOfDirectory(at: Self.protectedDirectory(), includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "ecg" { try FileManager.default.removeItem(at: file) }
    }
}
