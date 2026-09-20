import Foundation

public enum SignalError: Error, LocalizedFailure {
    case invalidSamplingRate, invalidSamples, incomplete, tooShort
    public var messageKey: String {
        switch self {
        case .invalidSamplingRate: "采样频率缺失或无效。"
        case .invalidSamples: "波形中有无效电压或不连续的时间顺序。"
        case .incomplete: "波形尚未完整读取，请重试。"
        case .tooShort: "记录太短，无法完成参考统计。"
        }
    }
}

/// Research-only deterministic detector. No clinical score or diagnostic classification.
public enum SignalAnalyzer {
    public static func analyze(_ waveform: Waveform) throws -> ECGAnalysis {
        let fs = waveform.samplingFrequency
        guard fs.isFinite, fs >= 50, fs <= 4000 else { throw SignalError.invalidSamplingRate }
        let points = waveform.points
        guard points.count >= Int(fs * 3) else { throw SignalError.tooShort }
        guard points.allSatisfy({ $0.time.isFinite && $0.millivolts.isFinite }),
              zip(points.dropFirst(), points).allSatisfy({ $0.time > $1.time }) else { throw SignalError.invalidSamples }
        let duration = waveform.duration
        let volts = points.map(\.millivolts)
        let baselineRadius = max(1, Int(fs * 0.12))
        var prefix = [Double](repeating: 0, count: volts.count + 1)
        for i in volts.indices { prefix[i + 1] = prefix[i] + volts[i] }
        let centered = volts.indices.map { i in
            let lower = max(0, i - baselineRadius), upper = min(volts.count, i + baselineRadius + 1)
            return volts[i] - (prefix[upper] - prefix[lower]) / Double(upper - lower)
        }
        var windows: [SignalWindow] = []
        for start in stride(from: 0.0, to: duration, by: 2.0) {
            let end = min(duration, start + 2)
            let indices = points.indices.filter { points[$0].time >= start && points[$0].time < end }
            let values = indices.map { volts[$0] }
            let spread = (values.max() ?? 0) - (values.min() ?? 0)
            let gap = indices.dropFirst().contains { points[$0].time - points[$0 - 1].time > 3 / fs }
            let extreme = values.filter { abs($0) > 5 }.count
            let density = Double(indices.count) / max(1, (end - start) * fs)
            let usable = spread > 0.04 && spread < 10 && !gap && density > 0.9 && extreme < max(1, values.count / 20)
            windows.append(SignalWindow(start: start, end: end, usable: usable))
        }
        func good(_ time: Double) -> Bool { windows.contains { $0.usable && time >= $0.start && time < $0.end } }
        let absolute = centered.map(abs)
        let sorted = absolute.sorted()
        let high = sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.99))]
        let threshold = max(0.12, high * 0.48)
        let refractory = max(1, Int(fs * 0.28))
        var indices: [Int] = []
        for i in 1..<(absolute.count - 1) where absolute[i] >= threshold && absolute[i] >= absolute[i - 1] && absolute[i] > absolute[i + 1] {
            guard good(points[i].time), points[i].time > 0.25, points[i].time < duration - 0.25 else { continue }
            if let last = indices.last, i - last < refractory {
                if absolute[i] > absolute[last] { indices[indices.count - 1] = i }
            } else { indices.append(i) }
        }
        var rr: [RRInterval] = []
        for i in 1..<max(1, indices.count) {
            let left = points[indices[i - 1]].time, right = points[indices[i]].time
            let touchesBad = windows.contains { !$0.usable && $0.start < right && $0.end > left }
            guard !touchesBad else { continue }
            rr.append(RRInterval(id: i, time: right, milliseconds: (right - left) * 1000))
        }
        let median = Statistics.median(rr.map(\.milliseconds)) ?? 0
        let mad = Statistics.median(rr.map { abs($0.milliseconds - median) }) ?? 0
        // Conservative resolution floor prevents division by zero and noisy constant-RR alarms.
        let scale = max(mad, 20, 2000 / fs)
        if rr.count >= 12 {
            for i in rr.indices { rr[i].isOutlier = abs(0.6745 * (rr[i].milliseconds - median) / scale) > 3.5 }
        }
        let rrValues = rr.map(\.milliseconds)
        let mean = rrValues.isEmpty ? nil : rrValues.reduce(0, +) / Double(rrValues.count)
        let fraction = windows.filter(\.usable).reduce(0) { $0 + $1.end - $1.start } / max(duration, 0.001)
        let reason = fraction < 0.8 ? "部分片段信号不足，统计仅覆盖可用区间。" : "本地节律检测尚未完成 Watch 同域验证，仅供研究参考。"
        var result = ECGAnalysis(peakTimes: indices.map { points[$0].time }, intervals: rr, windows: windows,
                           averageBPM: mean.map { 60_000 / $0 },
                           minimumBPM: rrValues.max().map { 60_000 / $0 },
                           maximumBPM: rrValues.min().map { 60_000 / $0 },
                           qualityFraction: fraction, duration: duration, reason: reason)
        result.review = RhythmReview.make(waveform: waveform, analysis: result)
        result.segments = SegmentAnalyzer.analyze(waveform, analysis: result)
        result.rhythmAssessment = EctopyAnalyzer.analyze(waveform, analysis: result)
        return result
    }
}
