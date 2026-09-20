import Foundation

public struct SuccessiveRR: Codable, Sendable, Identifiable, Equatable {
    public var id: Int
    public var first: Double
    public var second: Double
    public init(id: Int, first: Double, second: Double) {
        self.id = id; self.first = first; self.second = second
    }
}

public struct BeatShape: Codable, Sendable, Identifiable, Equatable {
    public var id: Int
    public var time: Double
    public var amplitude: Double
    public var deviation: Double
}

public struct ReviewEvent: Codable, Sendable, Identifiable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case rr = "RR 离群", shortLong = "短—长 RR 组合", repeating = "重复短—长组合"
        case amplitude = "振幅离群", shape = "局部形态偏离"
    }
    public var time: Double
    public var kind: Kind
    public var detail: String
    public var id: String { "\(kind.rawValue)-\(time)" }
}

/// Descriptive features only. RR intervals are never reclassified as normal-to-normal intervals.
public struct RhythmReview: Codable, Sendable, Equatable {
    public var pairs: [SuccessiveRR]
    public var rrRMSSD: Double?
    public var beats: [BeatShape]
    public var template: [VoltagePoint]
    public var events: [ReviewEvent]

    public static func make(waveform: Waveform, analysis: ECGAnalysis) -> RhythmReview {
        let rr = analysis.intervals
        let pairs = zip(rr, rr.dropFirst()).compactMap { left, right -> SuccessiveRR? in
            // IDs retain the original peak sequence, including rejected gaps.
            guard right.id == left.id + 1,
                  abs((right.time - right.milliseconds / 1000) - left.time) < 0.01 else { return nil }
            return SuccessiveRR(id: right.id, first: left.milliseconds, second: right.milliseconds)
        }
        let rmssd = pairs.isEmpty ? nil : sqrt(pairs.reduce(0) { $0 + pow($1.second - $1.first, 2) } / Double(pairs.count))
        var events = analysis.outliers.map { ReviewEvent(time: $0.time, kind: .rr, detail: "RR \(Int($0.milliseconds.rounded())) ms") }
        if rr.count >= 12, let median = Statistics.median(rr.map(\.milliseconds)), median > 0 {
            var starts: [Int] = []
            for i in 0..<max(0, rr.count - 1) {
                let short = rr[i], long = rr[i + 1]
                guard long.id == short.id + 1 else { continue }
                if short.milliseconds < median * 0.8 && long.milliseconds > median * 1.2 {
                    starts.append(i)
                    events.append(ReviewEvent(time: short.time, kind: .shortLong, detail: "\(Int(short.milliseconds)) / \(Int(long.milliseconds)) ms；以本条 RR 中位数为基准"))
                }
            }
            for i in starts where starts.contains(i + 2) && starts.contains(i + 4) {
                guard rr[i + 4].id == rr[i].id + 4, !starts.contains(i - 2) else { continue }
                events.append(ReviewEvent(time: rr[i].time, kind: .repeating, detail: "至少 3 组连续重复；不能据此判定二联律或早搏类型"))
            }
        }

        let points = waveform.points
        func sample(at time: Double) -> Double? {
            var lo = 0, hi = points.count
            while lo < hi { let mid = (lo + hi) / 2; if points[mid].time < time { lo = mid + 1 } else { hi = mid } }
            guard lo > 0, lo < points.count else { return nil }
            let a = points[lo - 1], b = points[lo]
            guard b.time - a.time <= 3 / waveform.samplingFrequency else { return nil }
            let weight = (time - a.time) / (b.time - a.time)
            return a.millivolts + weight * (b.millivolts - a.millivolts)
        }
        let offsets = (0...70).map { -0.12 + Double($0) * 0.004 }
        var snippets: [(id: Int, time: Double, values: [Double])] = []
        for (id, time) in analysis.peakTimes.enumerated() {
            let start = time - 0.12, end = time + 0.16
            guard start >= 0, end <= waveform.duration,
                  !analysis.windows.contains(where: { !$0.usable && $0.start < end && $0.end > start }) else { continue }
            let values = offsets.compactMap { sample(at: time + $0) }
            guard values.count == offsets.count else { continue }
            let baseline = Statistics.median(Array(values.prefix(8))) ?? 0
            snippets.append((id, time, values.map { $0 - baseline }))
        }
        var beats: [BeatShape] = [], template: [VoltagePoint] = []
        if snippets.count >= 12 {
            let medianShape = offsets.indices.map { index in Statistics.median(snippets.map { $0.values[index] }) ?? 0 }
            template = zip(offsets, medianShape).map { VoltagePoint(time: $0, millivolts: $1) }
            let energy = max(0.001, medianShape.reduce(0) { $0 + $1 * $1 })
            for snippet in snippets {
                let error = zip(snippet.values, medianShape).reduce(0) { $0 + pow($1.0 - $1.1, 2) }
                beats.append(BeatShape(id: snippet.id, time: snippet.time, amplitude: snippet.values[30], deviation: sqrt(error / energy)))
            }
            func outlier(_ value: Double, values: [Double], floor: Double) -> Bool {
                let center = Statistics.median(values) ?? 0
                let mad = Statistics.median(values.map { abs($0 - center) }) ?? 0
                return abs(0.6745 * (value - center) / max(mad, floor)) > 3.5
            }
            for beat in beats {
                if outlier(beat.amplitude, values: beats.map(\.amplitude), floor: 0.03) {
                    events.append(ReviewEvent(time: beat.time, kind: .amplitude, detail: String(format: "局部基线校正振幅 %.2f mV", beat.amplitude)))
                }
                if outlier(beat.deviation, values: beats.map(\.deviation), floor: 0.05) {
                    events.append(ReviewEvent(time: beat.time, kind: .shape, detail: "R 峰前 120 ms 至后 160 ms 与本条中位模板偏离"))
                }
            }
        }
        return RhythmReview(pairs: pairs, rrRMSSD: rmssd, beats: beats, template: template,
                            events: events.sorted { $0.time == $1.time ? $0.kind.rawValue < $1.kind.rawValue : $0.time < $1.time })
    }
}
