import Foundation

public enum ECGSegment: String, Codable, CaseIterable, Sendable, Identifiable {
    case p, pr, prSegment, qrs, st, t, qt, qtc, tp, rr, u
    // Keep all stored cases decodable, but only expose implemented measurements.
    // A supported segment remains visible when this particular recording cannot be measured.
    public static let supportedCases: [ECGSegment] = [.p, .pr, .prSegment, .qrs, .st, .t, .qt, .qtc, .tp, .rr]
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .p: L10n.text("P 波")
        case .pr: L10n.text("PR 间期")
        case .prSegment: L10n.text("PR 段")
        case .qrs: L10n.text("QRS 波群")
        case .st: L10n.text("ST 段 / J 点")
        case .t: L10n.text("T 波")
        case .qt: L10n.text("QT 间期")
        case .qtc: L10n.text("QTc（校正 QT）")
        case .tp: L10n.text("TP 段")
        case .rr: L10n.text("RR / PP 间期")
        case .u: L10n.text("U 波候选")
        }
    }
    public var explanation: String {
        switch self {
        case .p: L10n.text("P 波反映心房的电活动，通常出现在 QRS 波群之前。这里看它持续多久、波峰有多高，以及波形朝上还是朝下。")
        case .pr: L10n.text("从 P 波开始到 QRS 波群开始，称为 PR 间期。这段时间帮助我们观察电信号从心房传到心室的过程。")
        case .prSegment: L10n.text("P 波结束后，到 QRS 波群开始前的短间隔。这里看它持续多久，以及波形相对参考水平线的位置。")
        case .qrs: L10n.text("QRS 通常是心电图里较高、较尖的一组波形，反映心室的电活动。这里看整组持续多久，以及 Q、R、S 各部分的大小。")
        case .st: L10n.text("ST 段位于 QRS 和 T 波之间，QRS 结束的位置叫 J 点。这里看波形相对参考水平线偏高还是偏低，以及变化的方向。")
        case .t: L10n.text("T 波反映心室电活动的恢复过程。这里看它持续多久、波峰大小，以及前后两部分的形状。")
        case .qt: L10n.text("从 QRS 开始到 T 波结束，称为 QT 间期。它包括心室电活动开始到恢复的整个过程。")
        case .qtc: L10n.text("心率快慢会影响 QT。QTc 根据心跳间隔作了换算，便于比较。下面列出两种常用算法，结果可能略有差别。")
        case .tp: L10n.text("一次心跳的 T 波结束，到下一次 P 波开始的间隔。这段波形通常比较平缓，可用来确定测量时的参考水平线。")
        case .rr: L10n.text("RR 是相邻两个 R 波峰之间的时间，PP 则看相邻两个 P 波峰。它们分别反映心室和心房电活动的间隔。")
        case .u: L10n.text("T 波之后重复出现的小波形，可能是 U 波。这里只显示与 T 波和下一次 P 波分开的候选，仍需结合原图确认。")
        }
    }
    public var reference: String {
        switch self {
        case .p: L10n.text("成人 P 波常用参考为短于 120 ms。波峰的大小还与记录的导联有关。")
        case .pr: L10n.text("成人常用参考为 120–200 ms。年龄、心率和测量方法都会影响结果。")
        case .prSegment: L10n.text("PR 段通常接近参考水平线。参考线的位置和信号处理方式会影响测量。")
        case .qrs: L10n.text("成人 QRS 常用参考为短于 120 ms。Q、R、S 的识别还需要结合原波形复核。")
        case .st: L10n.text("接触、姿势和信号处理都可能改变 ST 的样子。手表心电不能据此判断或排除心肌缺血。")
        case .t: L10n.text("从不同导联看，T 波的方向和大小可能不同，不能只凭一个数值判断是否正常。")
        case .qt: L10n.text("QT 会随心率变化，不能用一个固定范围判断所有记录。")
        case .qtc: L10n.text("心率很快或很慢时，校正的偏差可能更大。解读还需结合年龄、性别和所用方法。")
        case .tp: L10n.text("心跳较快时，这段间隔可能很短，甚至难以与相邻波形分开。")
        case .rr: L10n.text("这些数字描述心跳间隔的变化，尚未区分正常心跳与其他类型，不能直接当作 HRV。")
        case .u: L10n.text("小波形也可能来自干扰或 T 波的另一部分；候选不代表已经确认 U 波。")
        }
    }
    public var measurementDetails: String {
        switch self {
        case .p: L10n.text("测量 P 波的开始、结束和峰值位置。波形太小、起止位置不清，或与旁边的波形重叠时，会留空相应数值。")
        case .pr: L10n.text("使用同一次心跳的 P 波起点和 QRS 起点。任一位置不清楚时，不计算 PR 间期。PR 间期包括 P 波本身和后面的 PR 段。")
        case .prSegment: L10n.text("从 P 波终点量到 QRS 起点；电位是这段波形相对局部 TP 参考线的平均值。正数表示在参考线上方，负数表示在下方。")
        case .qrs: L10n.text("先估计 QRS 的开始和结束，再寻找主峰前后的反向波形，作为 Q、S 的候选。数值保留原来的正负方向；如果主峰朝下，Q、R、S 的命名需要人工复核。单导联无法判断电轴或胸前导联的 R 波变化。")
        case .st: L10n.text("以 QRS 终点估计 J 点，再测量其后 60 和 80 ms 的电位。变化速率由这两个位置的电位差计算；正值表示向上，负值表示向下。如果已接近 T 波，就不再把该处当作 ST 测量。")
        case .t: L10n.text("分别寻找 T 波的开始、峰值和结束。前后时长比 = 起点到峰值的时间 ÷ 峰值到终点的时间。两部分长度相近时，比值接近 1；有多个波峰时需要结合原图查看。")
        case .qt: L10n.text("每次心跳单独测量：从这一次 QRS 的起点，到同一次 T 波的终点，再汇总结果。T 波终点不清时，不计算 QT。")
        case .qtc: L10n.text("使用同一次心跳的 QT 和紧邻前一次的 RR，均以秒代入：Fridericia = QT / RR^(1/3)；Bazett = QT / √RR。当前算法要求相关 RR 连续、相邻变化不超过 10%，且间隔为 500–1500 ms。这是算法的适用条件，不是正常范围。")
        case .tp: L10n.text("从本次 T 波终点量到下一次 P 波起点。任一位置不清、信号中断，或间隔短于 40 ms 时不测量。")
        case .rr: L10n.text("RR 和 PP 分别使用各自的相邻波峰计算，不互相替代，也不跨过信号中断的地方拼接。")
        case .u: L10n.text("要求 T 波已回到基线，候选与下一次 P 波分开，持续 40–140 ms，幅度不超过 T 波的四分之一，并在至少三次心跳中以相近位置重复。融合或只有一次的小波形不输出结果。")
        }
    }
    public var metrics: [SegmentMetric] {
        switch self {
        case .p: [.pDuration, .pAmplitude]
        case .pr: [.prDuration]
        case .prSegment: [.prSegmentDuration, .prLevel]
        case .qrs: [.qrsDuration, .qAmplitude, .qDuration, .rAmplitude, .rPeakTime, .sAmplitude, .sDuration]
        case .st: [.stDuration, .jLevel, .st60, .st80, .stSlope]
        case .t: [.tDuration, .tAmplitude, .tSymmetry]
        case .qt: [.qtDuration]
        case .qtc: [.qtcFridericia, .qtcBazett]
        case .tp: [.tpDuration]
        case .rr: [.rrDuration, .ppDuration]
        case .u: [.uAmplitude]
        }
    }
}

public enum SegmentMetric: String, Codable, CaseIterable, Sendable, Identifiable {
    case pDuration, pAmplitude, prDuration, prSegmentDuration, prLevel
    case qrsDuration, qAmplitude, qDuration, rAmplitude, rPeakTime, sAmplitude, sDuration
    case stDuration, jLevel, st60, st80, stSlope, tDuration, tAmplitude, tSymmetry
    case qtDuration, qtcFridericia, qtcBazett, tpDuration, rrDuration, ppDuration, uAmplitude
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .pDuration: L10n.text("P 波持续时间")
        case .pAmplitude: L10n.text("P 波幅度")
        case .prDuration: L10n.text("PR 间期")
        case .prSegmentDuration: L10n.text("PR 段持续时间")
        case .prLevel: L10n.text("PR 段电位")
        case .qrsDuration: L10n.text("QRS 持续时间")
        case .qAmplitude: L10n.text("Q 波幅度（估计）")
        case .qDuration: L10n.text("Q 波持续时间（估计）")
        case .rAmplitude: L10n.text("R 主峰幅度")
        case .rPeakTime: L10n.text("QRS 开始到 R 峰的时间")
        case .sAmplitude: L10n.text("S 波幅度（估计）")
        case .sDuration: L10n.text("S 波持续时间（估计）")
        case .stDuration: L10n.text("ST 段持续时间")
        case .jLevel: L10n.text("J 点电位")
        case .st60: L10n.text("J 点后 60 ms 的电位")
        case .st80: L10n.text("J 点后 80 ms 的电位")
        case .stSlope: L10n.text("ST 电位变化速率")
        case .tDuration: L10n.text("T 波持续时间")
        case .tAmplitude: L10n.text("T 波幅度")
        case .tSymmetry: L10n.text("T 波前后时长比")
        case .qtDuration: L10n.text("QT 间期")
        case .qtcFridericia: L10n.text("QTc（Fridericia）")
        case .qtcBazett: L10n.text("QTc（Bazett）")
        case .tpDuration: L10n.text("TP 段持续时间")
        case .rrDuration: L10n.text("RR 间期")
        case .ppDuration: L10n.text("PP 间期")
        case .uAmplitude: L10n.text("U 波候选幅度")
        }
    }
    public var unit: String {
        switch self {
        case .pAmplitude, .prLevel, .qAmplitude, .rAmplitude, .sAmplitude, .jLevel, .st60, .st80, .tAmplitude, .uAmplitude: "mV"
        case .stSlope: "mV/s"
        case .tSymmetry: L10n.text("倍")
        default: "ms"
        }
    }
    public func format(_ value: Double) -> String {
        String(format: unit == "ms" ? "%.0f" : "%.2f", locale: L10n.locale, value)
    }
}

public struct SegmentValue: Codable, Sendable, Equatable, Identifiable {
    public var metric: SegmentMetric
    public var value: Double?
    public var reason: String?
    public var id: String { metric.rawValue }
    public var displayReason: String? { reason.map(AnalysisText.readable) }
}

public struct SegmentObservation: Codable, Sendable, Equatable, Identifiable {
    public var segment: ECGSegment
    public var start: Double?
    public var end: Double?
    public var peak: Double?
    public var morphology: String?
    public var values: [SegmentValue]
    public var id: String { segment.rawValue }
    public var hasMeasurement: Bool { values.contains { $0.value != nil } }
    public var displayMorphology: String? { morphology.map(AnalysisText.readable) }
    public func value(_ metric: SegmentMetric) -> SegmentValue? { values.first { $0.metric == metric } }
}

public struct SegmentBeat: Codable, Sendable, Equatable, Identifiable {
    public var id: Int
    public var rTime: Double
    public var observations: [SegmentObservation]
    public func observation(_ segment: ECGSegment) -> SegmentObservation? { observations.first { $0.segment == segment } }
}

public struct SegmentStatistic: Sendable {
    public var metric: SegmentMetric
    public var count: Int
    public var total: Int
    public var median: Double?
    public var minimum: Double?
    public var maximum: Double?
    public var p10: Double?
    public var p90: Double?
    public var coverageDescription: String {
        if total == 0 { return L10n.text("暂无可用于测量的心跳") }
        if count == total { return L10n.text("已测量 \(count) 次") }
        return L10n.text("已测量 \(count) 次，\(total - count) 次未纳入")
    }
}

public struct SegmentAnalysis: Codable, Sendable, Equatable {
    public var beats: [SegmentBeat]
    public var samplingFrequency: Double
    public var unavailableReason: String?
    public var visibleSegments: [ECGSegment] {
        ECGSegment.supportedCases + (statistics(.uAmplitude).count >= 3 ? [.u] : [])
    }
    public static var method: String { L10n.text("这些数值由应用自动估算，准确度尚未经过真实 Apple Watch 数据验证，不能据此判断心电是否正常。") }
    public static var readingGuide: String { L10n.text("ms 是毫秒，1000 ms 等于 1 秒。mV 是毫伏，用来表示波形相对参考水平线的高低；正数在上方，负数在下方。\n中位数是把测量值从小到大排列后，处于中间的数值。它不是平均值。\n最低–最高展示所有测量值的范围；中间 80% 范围（P10–P90）去掉两端各 10% 的分布，便于看出数值集中在哪里。两者都不是正常范围。\n测量次数以应用识别到的心跳为准，可能有漏检。没有结果的心跳不会填成 0，也不会计入统计。") }
    public var displayUnavailableReason: String? { unavailableReason.map(AnalysisText.readable) }
    public func statistics(_ metric: SegmentMetric) -> SegmentStatistic {
        let values = beats.compactMap { beat in
            beat.observations.flatMap(\.values).first { $0.metric == metric }?.value
        }.filter(\.isFinite).sorted()
        func percentile(_ fraction: Double) -> Double? {
            guard !values.isEmpty else { return nil }
            let index = Double(values.count - 1) * fraction
            let lower = Int(index), upper = min(values.count - 1, lower + 1)
            return values[lower] + (values[upper] - values[lower]) * (index - Double(lower))
        }
        return SegmentStatistic(metric: metric, count: values.count, total: beats.count,
                                median: Statistics.median(values), minimum: values.first, maximum: values.last,
                                p10: percentile(0.1), p90: percentile(0.9))
    }
    public func missingReasons(_ segment: ECGSegment) -> [String] {
        var counts: [String: Int] = [:]
        for beat in beats {
            let reasons = Set(beat.observation(segment)?.values.compactMap { $0.value == nil ? $0.displayReason : nil } ?? [])
            for reason in reasons { counts[reason, default: 0] += 1 }
        }
        return counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .map { L10n.text("\($0.value) 次：\($0.key)") }
    }
}
