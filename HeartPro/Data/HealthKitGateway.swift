import Foundation
import HealthKit
import HeartProCore

struct HealthChanges: Sendable {
    var records: [ECGRecord]
    var deleted: [UUID]
    var anchor: Data
    var hasMore: Bool
}

enum HealthAccessError: LocalizedFailure {
    case unavailable, missing, writeDenied
    var messageKey: String {
        switch self {
        case .unavailable: "此设备暂不支持 Apple 健康。你仍可以体验演示或查看已保存的记录。"
        case .missing: "这条心电图当前不可读取。请检查 Apple 健康中的记录和读取权限。"
        case .writeDenied: "没有获得此症状的写入权限。本地备忘已保留。"
        }
    }
}

actor HealthKitGateway {
    private let store = HKHealthStore()
    private let ecgType = HKObjectType.electrocardiogramType()

    static var readTypes: Set<HKObjectType> {
        [HKObjectType.electrocardiogramType(), HKQuantityType(.heartRate), HKQuantityType(.heartRateVariabilitySDNN)]
    }

    func requestHeartHealthAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthAccessError.unavailable }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    func recent() async throws -> [ECGRecord] {
        let query = HKSampleQueryDescriptor(predicates: [.electrocardiogram()], sortDescriptors: [SortDescriptor(\HKElectrocardiogram.startDate, order: .reverse)], limit: 30)
        return try await query.result(for: store).map(metadata)
    }

    func changes(anchor data: Data?) async throws -> HealthChanges {
        // Corrupt local checkpoints restart an idempotent full import rather than skipping history.
        let anchor = data.flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: $0) }
        let query = HKAnchoredObjectQueryDescriptor(predicates: [.electrocardiogram()], anchor: anchor, limit: 200)
        let batch = try await query.result(for: store)
        let encoded = try NSKeyedArchiver.archivedData(withRootObject: batch.newAnchor, requiringSecureCoding: true)
        return HealthChanges(records: batch.addedSamples.map(metadata), deleted: batch.deletedObjects.map(\.uuid),
                             anchor: encoded, hasMore: batch.addedSamples.count + batch.deletedObjects.count >= 200)
    }

    func waveform(_ id: UUID) async throws -> Waveform {
        let predicate = HKQuery.predicateForObject(with: id)
        let query = HKSampleQueryDescriptor(predicates: [.electrocardiogram(predicate)], sortDescriptors: [], limit: 1)
        guard let sample = try await query.result(for: store).first else { throw HealthAccessError.missing }
        var points: [VoltagePoint] = []; points.reserveCapacity(sample.numberOfVoltageMeasurements)
        for try await value in HKElectrocardiogramQueryDescriptor(sample).results(for: store) {
            try Task.checkCancellation()
            guard let voltage = value.quantity(for: .appleWatchSimilarToLeadI) else { throw SignalError.invalidSamples }
            points.append(VoltagePoint(time: value.timeSinceSampleStart, millivolts: voltage.doubleValue(for: HKUnit.voltUnit(with: .milli))))
        }
        guard points.count == sample.numberOfVoltageMeasurements else { throw SignalError.incomplete }
        let fs = sample.samplingFrequency?.doubleValue(for: HKUnit.hertz()) ?? 0
        return Waveform(samplingFrequency: fs, points: points)
    }

    private func metadata(_ sample: HKElectrocardiogram) -> ECGRecord {
        let classification: SourceClassification
        switch sample.classification {
        case .sinusRhythm: classification = .sinus
        case .atrialFibrillation: classification = .atrialFibrillation
        case .inconclusiveHighHeartRate: classification = .highHeartRate
        case .inconclusiveLowHeartRate: classification = .lowHeartRate
        case .inconclusivePoorReading: classification = .poorReading
        case .inconclusiveOther: classification = .inconclusive
        default: classification = .unknown
        }
        return ECGRecord(id: sample.uuid, date: sample.startDate, duration: sample.endDate.timeIntervalSince(sample.startDate),
                         samplingFrequency: sample.samplingFrequency?.doubleValue(for: .hertz()) ?? 0,
                         sampleCount: sample.numberOfVoltageMeasurements,
                         appleBPM: sample.averageHeartRate?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                         classification: classification, source: sample.sourceRevision.source.name)
    }

    func readHRV(from start: Date, to end: Date) async throws -> [HRVSample] {
        let type = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKSampleQueryDescriptor(predicates: [.quantitySample(type: type, predicate: predicate)], sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)])
        return try await query.result(for: store).filter { $0.startDate < end }.map {
            HRVSample(id: $0.uuid, date: $0.startDate, milliseconds: $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)), source: $0.sourceRevision.source.name)
        }.filter { $0.milliseconds.isFinite && $0.milliseconds > 0 }
    }

    func heartRates(from start: Date, to end: Date, hourly: Bool = false) async throws -> [HeartRateBucket] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(.heartRate), predicate: predicate),
            options: [.discreteAverage, .discreteMin, .discreteMax], anchorDate: start,
            intervalComponents: hourly ? DateComponents(hour: 1) : DateComponents(day: 1))
        let collection = try await query.result(for: store)
        let unit = HKUnit.count().unitDivided(by: .minute())
        return collection.statistics().compactMap { stats in
            guard stats.startDate >= start, stats.startDate < end,
                  let average = stats.averageQuantity()?.doubleValue(for: unit),
                  let low = stats.minimumQuantity()?.doubleValue(for: unit),
                  let high = stats.maximumQuantity()?.doubleValue(for: unit),
                  average.isFinite, low.isFinite, high.isFinite, low > 0, low <= average, average <= high else { return nil }
            return HeartRateBucket(date: stats.startDate, end: stats.endDate, average: average, minimum: low, maximum: high)
        }.sorted { $0.date < $1.date }
    }

    private func type(for symptom: Symptom) -> HKCategoryType? {
        let identifier: HKCategoryTypeIdentifier
        switch symptom {
        case .palpitations: identifier = .rapidPoundingOrFlutteringHeartbeat
        case .skipped: identifier = .skippedHeartbeat
        case .chest: identifier = .chestTightnessOrPain
        case .breath: identifier = .shortnessOfBreath
        case .dizziness: identifier = .dizziness
        case .fainting: identifier = .fainting
        default: return nil
        }
        return HKCategoryType(identifier)
    }

    func authorizeSymptoms(_ symptoms: [Symptom]) async throws {
        let types = Set(symptoms.compactMap { type(for: $0) })
        guard !types.isEmpty else { return }
        // Symptoms are only written; no feature reads symptom history.
        try await store.requestAuthorization(toShare: types, read: [])
    }

    func write(_ symptom: Symptom, note: JournalNote) async throws {
        guard let type = type(for: symptom) else { return }
        guard store.authorizationStatus(for: type) == .sharingAuthorized else { throw HealthAccessError.writeDenied }
        let value: Int
        if symptom == .fainting { value = HKCategoryValuePresence.present.rawValue }
        else {
            value = switch note.severity {
            case 2: HKCategoryValueSeverity.moderate.rawValue
            case 3: HKCategoryValueSeverity.severe.rawValue
            default: HKCategoryValueSeverity.mild.rawValue
            }
        }
        let metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: "app.heartpro.note.\(note.id.uuidString).\(symptom.rawValue)",
            HKMetadataKeySyncVersion: note.revision
        ]
        let sample = HKCategorySample(type: type, value: value, start: note.date, end: note.endDate, metadata: metadata)
        try await store.save(sample)
    }
}
