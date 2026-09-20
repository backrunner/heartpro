import Foundation

public struct VoltagePoint: Codable, Sendable, Equatable {
    public var time: Double
    public var millivolts: Double
    public init(time: Double, millivolts: Double) { self.time = time; self.millivolts = millivolts }
}

public struct Waveform: Codable, Sendable, Equatable {
    public var samplingFrequency: Double
    public var points: [VoltagePoint]
    public init(samplingFrequency: Double, points: [VoltagePoint]) {
        self.samplingFrequency = samplingFrequency; self.points = points
    }
    public var duration: Double { points.last?.time ?? 0 }

    /// Preserve both extrema in their original temporal order. Never used for analysis.
    public func envelope(from start: Double = 0, to end: Double, columns: Int) -> [VoltagePoint] {
        guard end > start, columns > 0 else { return [] }
        let visible = points.filter { $0.time >= start && $0.time <= end }
        guard visible.count > columns * 2 else { return visible }
        var bins = [[VoltagePoint]](repeating: [], count: columns)
        for point in visible {
            let index = min(columns - 1, max(0, Int((point.time - start) / (end - start) * Double(columns))))
            bins[index].append(point)
        }
        return bins.flatMap { bin -> [VoltagePoint] in
            guard let low = bin.min(by: { $0.millivolts < $1.millivolts }),
                  let high = bin.max(by: { $0.millivolts < $1.millivolts }) else { return [] }
            if low.time == high.time { return [low] }
            return [low, high].sorted { $0.time < $1.time }
        }
    }
}

public enum SourceClassification: String, Codable, Sendable {
    case sinus, atrialFibrillation, highHeartRate, lowHeartRate, inconclusive, poorReading, unknown
    public var title: String {
        switch self {
        case .sinus: L10n.text("窦性心律")
        case .atrialFibrillation: L10n.text("房颤分类")
        case .highHeartRate: L10n.text("心率偏高")
        case .lowHeartRate: L10n.text("心率偏低")
        case .inconclusive: L10n.text("未能分类")
        case .poorReading: L10n.text("记录质量不佳")
        case .unknown: L10n.text("无分类信息")
        }
    }
}

public struct ECGRecord: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var duration: Double
    public var samplingFrequency: Double
    public var sampleCount: Int
    public var appleBPM: Double?
    public var classification: SourceClassification
    public var source: String
    public var isDemo: Bool
    public var preview: [VoltagePoint]
    public var analysis: ECGAnalysis?
    public var failure: String?
    public var demoScore: Int?
    public var listSummary: ECGListSummary?

    public init(id: UUID = UUID(), date: Date, duration: Double, samplingFrequency: Double,
                sampleCount: Int, appleBPM: Double?, classification: SourceClassification,
                source: String = "Apple Watch", isDemo: Bool = false,
                preview: [VoltagePoint] = [], analysis: ECGAnalysis? = nil,
                failure: String? = nil, demoScore: Int? = nil) {
        self.id = id; self.date = date; self.duration = duration
        self.samplingFrequency = samplingFrequency; self.sampleCount = sampleCount
        self.appleBPM = appleBPM; self.classification = classification; self.source = source
        self.isDemo = isDemo; self.preview = preview; self.analysis = analysis
        self.failure = failure; self.demoScore = demoScore
    }
    public var bpm: Double? { appleBPM ?? analysis?.averageBPM ?? listSummary?.averageBPM }
    public var rhythmAssessment: RhythmAssessment? {
        guard analysis?.version == ECGAnalysis.currentVersion else { return nil }
        return analysis?.rhythmAssessment?.restricted(for: classification)
    }
    /// A descriptive research score. Never use legacy illustrative demo scores.
    public var referenceScore: Int? { rhythmAssessment?.score }
    public var isAnalyzed: Bool { analysis != nil || listSummary != nil }
    public var lightweight: ECGRecord {
        var copy = self
        if let analysis { copy.listSummary = ECGListSummary(analysis: analysis, classification: classification) }
        copy.analysis = nil
        return copy
    }
}

public struct RRInterval: Codable, Sendable, Identifiable, Equatable {
    public var id: Int
    public var time: Double
    public var milliseconds: Double
    public var isOutlier: Bool
    public init(id: Int, time: Double, milliseconds: Double, isOutlier: Bool = false) {
        self.id = id; self.time = time; self.milliseconds = milliseconds; self.isOutlier = isOutlier
    }
}

public struct SignalWindow: Codable, Sendable, Equatable {
    public var start: Double
    public var end: Double
    public var usable: Bool
}

public struct ECGAnalysis: Codable, Sendable, Equatable {
    public static let currentVersion = "0.6.0-research"
    public var version = Self.currentVersion
    public var peakTimes: [Double]
    public var intervals: [RRInterval]
    public var windows: [SignalWindow]
    public var averageBPM: Double?
    public var minimumBPM: Double?
    public var maximumBPM: Double?
    public var qualityFraction: Double
    public var duration: Double
    public var reason: String?
    public var review: RhythmReview?
    /// Optional so records saved before segment analysis remain decodable.
    public var segments: SegmentAnalysis?
    public var rhythmAssessment: RhythmAssessment?
    public var validDuration: Double { windows.filter(\.usable).reduce(0) { $0 + $1.end - $1.start } }
    public var outliers: [RRInterval] { intervals.filter(\.isOutlier) }
    public var rrSD: Double? { Statistics.sampleSD(intervals.map(\.milliseconds)) }
    // RR variability is deliberately NOT presented as validated normal-to-normal HRV.
}

public enum Symptom: String, Codable, CaseIterable, Sendable, Identifiable {
    case none, palpitations, skipped, chest, breath, dizziness, fainting, fatigue, exercise, coffee, stress, sleep
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .none: L10n.text("无明显不适")
        case .palpitations: L10n.text("心悸")
        case .skipped: L10n.text("漏跳感")
        case .chest: L10n.text("胸闷 / 胸痛")
        case .breath: L10n.text("气短")
        case .dizziness: L10n.text("头晕")
        case .fainting: L10n.text("晕厥")
        case .fatigue: L10n.text("疲劳")
        case .exercise: L10n.text("运动后")
        case .coffee: L10n.text("咖啡因")
        case .stress: L10n.text("压力较大")
        case .sleep: L10n.text("睡眠不足")
        }
    }
    public var canWriteToHealth: Bool { [.palpitations, .skipped, .chest, .breath, .dizziness, .fainting].contains(self) }
    public var needsAttention: Bool { [.chest, .breath, .fainting].contains(self) }
}

public struct JournalNote: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var recordID: UUID
    public var date: Date
    public var text: String
    public var symptoms: [Symptom]
    public var severity: Int
    public var revision: Int
    public var healthRequested: Bool
    public var writtenSymptoms: [Symptom]
    public var healthError: String?
    /// Nil means the user did not supply a duration; older stored notes decode as nil.
    public var duration: TimeInterval?
    public init(id: UUID = UUID(), recordID: UUID, date: Date, text: String = "", symptoms: [Symptom] = [],
                severity: Int = 1, revision: Int = 1, healthRequested: Bool = false,
                writtenSymptoms: [Symptom] = [], healthError: String? = nil, duration: TimeInterval? = nil) {
        self.id = id; self.recordID = recordID; self.date = date; self.text = text
        self.symptoms = symptoms; self.severity = severity; self.revision = revision
        self.healthRequested = healthRequested; self.writtenSymptoms = writtenSymptoms; self.healthError = healthError
        self.duration = duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
    }
    public var endDate: Date { date.addingTimeInterval(duration ?? 0) }
    public var pendingSymptoms: [Symptom] { symptoms.filter { $0.canWriteToHealth && !writtenSymptoms.contains($0) } }
}

public struct HRVSample: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var milliseconds: Double
    public var source: String
    public init(id: UUID, date: Date, milliseconds: Double, source: String) {
        self.id = id; self.date = date; self.milliseconds = milliseconds; self.source = source
    }
}

public enum Statistics {
    public static func median(_ values: [Double]) -> Double? {
        let sorted = values.filter(\.isFinite).sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
    public static func sampleSD(_ values: [Double]) -> Double? {
        guard values.count > 1, values.allSatisfy(\.isFinite) else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        return sqrt(values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1))
    }
    /// Input must already be a validated contiguous NN sequence. Never joins disjoint runs.
    public static func hrv(contiguousNN: [Double]) -> (sdnn: Double, rmssd: Double)? {
        guard contiguousNN.count >= 2, contiguousNN.allSatisfy({ $0.isFinite && $0 > 0 }),
              let sdnn = sampleSD(contiguousNN) else { return nil }
        let differences = zip(contiguousNN.dropFirst(), contiguousNN).map { pow($0 - $1, 2) }
        return (sdnn, sqrt(differences.reduce(0, +) / Double(differences.count)))
    }
}

public struct DailySummary: Sendable {
    public var records: [ECGRecord]
    public init(records: [ECGRecord], date: Date, calendar: Calendar = .current) {
        self.records = records.filter { calendar.isDate($0.date, inSameDayAs: date) }.sorted { $0.date > $1.date }
    }
    public var score: Int? { Statistics.median(records.compactMap { $0.referenceScore.map(Double.init) }).map { Int($0.rounded()) } }
    public var bpm: Double? { Statistics.median(records.compactMap(\.bpm)) }
    public var analyzedCount: Int { records.filter(\.isAnalyzed).count }
    public var seconds: Double { records.reduce(0) { $0 + $1.duration } }
}
