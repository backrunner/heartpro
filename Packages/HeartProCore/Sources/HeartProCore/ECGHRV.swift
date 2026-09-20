import Foundation

/// Ultra-short research estimate, not a validated normal-beat classifier.
/// Pool eligible intervals within this recording; successive pairs never cross gaps.
/// The 20 s / 12 interval / 10 pair gates are product quality rules, not clinical validation.
public struct ECGHRV: Sendable, Equatable {
    public enum Unavailable: Sendable { case analysis, classification, quality, rhythm, duration }
    public var sdnn: Double?
    public var rmssd: Double?
    public var sd1: Double?
    public var sd2: Double?
    public var intervals: [RRInterval] = []
    public var pairs: [SuccessiveRR] = []
    public var totalCount = 0
    public var unavailable: Unavailable?
    public var duration: Double { intervals.reduce(0) { $0 + $1.milliseconds / 1000 } }
    public var omittedCount: Int { totalCount - intervals.count }

    public static func estimate(analysis: ECGAnalysis?, classification: SourceClassification) -> Self {
        var result = Self()
        guard let analysis, analysis.version == ECGAnalysis.currentVersion else {
            result.unavailable = .analysis; return result
        }
        result.totalCount = analysis.intervals.count
        guard classification == .sinus else { result.unavailable = .classification; return result }
        guard analysis.qualityFraction >= 0.8, analysis.validDuration >= 20 else {
            result.unavailable = .quality; return result
        }
        guard let rhythm = analysis.rhythmAssessment,
              rhythm.limitation != .irregularRhythm, rhythm.limitation != .unstableReference,
              rhythm.limitation != .sourceClassification else {
            result.unavailable = .rhythm; return result
        }
        let eligible = Set(rhythm.beats.filter { $0.exclusion == nil && !$0.needsReview }.map(\.id))
        var retained: [RRInterval] = []
        var pairs: [SuccessiveRR] = []
        var previous: RRInterval?
        for interval in analysis.intervals {
            let start = interval.time - interval.milliseconds / 1000
            let clean = interval.milliseconds.isFinite && (300...2000).contains(interval.milliseconds)
                && interval.time.isFinite && start >= 0 && interval.time <= analysis.duration
                && !interval.isOutlier
                && eligible.contains(interval.id - 1) && eligible.contains(interval.id)
                && !analysis.windows.contains { !$0.usable && $0.start < interval.time && $0.end > start }
            guard clean else { previous = nil; continue }
            // A removed interval must not create an artificial adjacent pair.
            if let previous, interval.id == previous.id + 1, abs(start - previous.time) <= 0.01 {
                pairs.append(SuccessiveRR(id: interval.id, first: previous.milliseconds, second: interval.milliseconds))
            }
            retained.append(interval)
            previous = interval
        }
        guard retained.count >= 12, retained.reduce(0, { $0 + $1.milliseconds }) >= 20_000,
              pairs.count >= 10, let sdnn = Statistics.sampleSD(retained.map(\.milliseconds)) else {
            result.unavailable = .duration; return result
        }
        result.intervals = retained; result.sdnn = sdnn; result.pairs = pairs
        // Research filtering does not establish clinically confirmed normal-to-normal beats.
        result.rmssd = sqrt(pairs.reduce(0) { $0 + pow($1.second - $1.first, 2) } / Double(pairs.count))
        result.sd1 = Statistics.sampleSD(pairs.map { ($0.second - $0.first) / sqrt(2) })
        result.sd2 = Statistics.sampleSD(pairs.map { ($0.second + $0.first) / sqrt(2) })
        return result
    }

    public var explanation: String {
        switch unavailable {
        case .analysis: L10n.text("等待完整 ECG 分析后计算 HRV。")
        case .classification: L10n.text("本次来源分类不是窦性心律，暂不估算 HRV。仍可查看上方 RR 间隔。")
        case .quality: L10n.text("清晰信号不足，暂不估算 HRV。请保持静止、贴合手表后重新测量。")
        case .rhythm: L10n.text("本次节律或波形不够稳定，暂不估算 HRV，避免把不规则心跳当作心率变异性。")
        case .duration: L10n.text("这次清晰的心跳间隔不足。保持静止、贴合手表，再测一次 30 秒心电。")
        case nil: L10n.text("这是本次短时测量的 HRV 估算，适合与相同时长、相似状态下的记录比较。")
        }
    }
}
