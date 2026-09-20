import Foundation

extension RhythmBeat.Candidate {
    public var title: String {
        switch self {
        case .wide: L10n.text("宽波群早搏候选")
        case .narrow: L10n.text("窄波群早搏候选")
        case .undetermined: L10n.text("早搏候选，类型待复核")
        }
    }
}

extension RhythmAssessment.Limitation {
    public var explanation: String {
        switch self {
        case .insufficientSignal: L10n.text("清晰信号不足 20 秒或不足整条记录的 80%，这次不计算分数。")
        case .insufficientBeats: L10n.text("可复核心跳不足 15 次，或有较多心跳无法可靠比较，这次不计算分数。")
        case .unstableReference: L10n.text("稳定的参考心跳不足，本次不计算分数。仅在时序和形态同时支持时标出早搏候选。")
        case .irregularRhythm: L10n.text("心跳间隔变化较大，超出这套评分规则的适用范围。")
        case .sourceClassification: L10n.text("Apple 将这条记录归为房颤或质量不佳，本次不套用早搏分类与节律评分。")
        }
    }
}

extension RhythmAssessment {
    public var coverageText: String { L10n.text("\(detectedBeatCount) 次已识别心跳中，\(evaluated.count) 次可复核") }
    public var scoreBasis: String { L10n.text("\(evaluated.count) 次可复核心跳，\(flagged.count) 次被标记；同一次心跳只计一次。") }
    public static var scoreRule: String {
        L10n.text("节律参考分 = 100 ×（1 − 被标记心跳数 ÷ 可复核心跳数），四舍五入。标记包括早搏候选、明显的间隔变化或局部形态变化；早搏后的停顿不重复计数。它描述本条记录中未被规则标记的比例，不是心脏健康分，100 分也不代表心电正常。")
    }
    public static var scoreEligibility: String {
        L10n.text("至少需要 20 秒清晰信号、80% 信号覆盖、15 次可复核心跳，以及 8 次稳定的参考心跳。可复核比例需达到非边缘心跳的 80%。信号不足不扣分；PR、QT 缺值和 HRV 高低也不参与加减分。")
    }
    public static var candidateRule: String {
        L10n.text("先与附近心跳比较：提前超过 15% 且至少 80 ms，再检查后续间隔是否延长，或 QRS 是否变宽并改变形态。宽波群候选要求局部宽度至少 120 ms、比参考宽 20%，且模板相关度低于 0.90。窄波群候选要求宽度小于 120 ms、相关度至少 0.90，并伴随后续间隔延长。这些是研究规则，不能单凭它们确认房早或室早。")
    }
    public static var caveat: String { L10n.text("自动识别可能漏报或误报，候选需要结合原图确认。") }
    public var reportText: String {
        var lines = [coverageText]
        if let score { lines += [L10n.text("节律参考分：\(score) / 100"), scoreBasis] }
        if let limitation { lines.append(limitation.explanation) }
        if !evaluated.isEmpty && limitation != .sourceClassification {
            lines.append(L10n.text("本次早搏候选：\(candidates.count) 次"))
            if !flagged.isEmpty { lines.append(L10n.text("可以回看的变化")) }
            lines += flagged.map { L10n.text("\($0.time, specifier: "%.2f") 秒：\($0.reviewTitle)。\($0.evidence)") }
        }
        lines += [Self.caveat, Self.scoreRule, Self.scoreEligibility, Self.candidateRule, L10n.text("规则版本：\(version)")]
        return lines.joined(separator: "\n\n")
    }
}

extension RhythmBeat {
    public var timingSummary: String {
        guard let precedingRR, let referenceRR else { return "" }
        return L10n.text("比附近心跳提前 \(max(0, referenceRR - precedingRR) / 1000, specifier: "%.2f") 秒")
    }
    public var reviewTitle: String {
        if let candidate { return candidate.title }
        return L10n.list([intervalChanged ? ReviewEvent.Kind.rr.title : nil,
                          shapeChanged ? ReviewEvent.Kind.shape.title : nil].compactMap { $0 })
    }
    public var evidence: String {
        guard let precedingRR, let followingRR, let referenceRR, let qrsWidth, let correlation else { return "" }
        return L10n.text("前一间隔 \(precedingRR, specifier: "%.0f") ms，附近参考 \(referenceRR, specifier: "%.0f") ms，后一间隔 \(followingRR, specifier: "%.0f") ms。局部 QRS 宽度约 \(qrsWidth, specifier: "%.0f") ms，模板相关度 \(correlation, specifier: "%.2f")。")
    }
}
