import Foundation

/// HealthKit aggregates, not ECG-derived heart rates. Missing buckets remain missing.
public struct HeartRateBucket: Codable, Sendable, Equatable, Identifiable {
    public var date: Date
    public var end: Date
    public var average: Double
    public var minimum: Double
    public var maximum: Double
    public var id: Date { date }
    public init(date: Date, end: Date, average: Double, minimum: Double, maximum: Double) {
        self.date = date; self.end = end; self.average = average
        self.minimum = minimum; self.maximum = maximum
    }
}

public struct HeartHealthSnapshot: Codable, Sendable, Equatable {
    public var heartRates: [HeartRateBucket]
    public var hrv: [HRVSample]
    public init(heartRates: [HeartRateBucket] = [], hrv: [HRVSample] = []) {
        self.heartRates = heartRates; self.hrv = hrv
    }
    public func day(_ date: Date, calendar: Calendar = .current) -> Self {
        Self(heartRates: heartRates.filter { calendar.isDate($0.date, inSameDayAs: date) },
             hrv: hrv.filter { calendar.isDate($0.date, inSameDayAs: date) })
    }
}

/// Persisted in the small list payload so browsing never decodes per-beat analysis.
public struct ECGListSummary: Codable, Sendable, Equatable {
    public var version: String
    public var averageBPM: Double?
    public var reviewCount: Int
    public var limitedSignal: Bool
    public init(analysis: ECGAnalysis, classification: SourceClassification) {
        version = analysis.version; averageBPM = analysis.averageBPM
        reviewCount = analysis.rhythmAssessment?.restricted(for: classification).flagged.count ?? 0
        limitedSignal = analysis.qualityFraction < 0.8
    }
}
