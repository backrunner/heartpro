import Foundation

/// Adult educational ECG references. These are not detector acceptance windows.
/// A comparison describes a measured number, never a normal/abnormal diagnosis.
public struct SegmentReference: Sendable {
    public enum Position: Sendable { case below, within, above, contextRequired }
    public var lower: Double?
    public var upper: Double?
    public var upperInclusive = true
    public var range: String
    public var context: String
    public var below: String
    public var above: String
    public func position(_ value: Double) -> Position {
        guard value.isFinite else { return .contextRequired }
        if let lower, value < lower { return .below }
        if let upper, upperInclusive ? value > upper : value >= upper { return .above }
        return lower == nil && upper == nil ? .contextRequired : .within
    }
    public func explanation(_ value: Double?) -> String {
        guard let value else { return context }
        switch position(value) {
        case .below: return below
        case .above: return above
        case .within: return context
        case .contextRequired: return context
        }
    }
}

extension ECGSegment {
    public var adultReference: SegmentReference {
        switch self {
        case .p:
            SegmentReference(upper: 120, upperInclusive: false, range: L10n.text("成人参考：P 波 < 120 ms"),
                context: L10n.text("参考范围来自常规心电图；手表单导联的边界估算可能有偏差。"), below: "",
                above: L10n.text("测量值达到或超过参考上限。可能与心房传导变慢有关，也可能是噪声或 P 波边界识别偏差；反复出现时可请医生复核心电图。"))
        case .pr:
            SegmentReference(lower: 120, upper: 200, range: L10n.text("成人参考：PR 120–200 ms"),
                context: L10n.text("年龄、心率及药物会影响 PR，参考范围不能单独用于诊断。"),
                below: L10n.text("测量值低于参考范围。可能与传导较快、预激或起点识别偏差有关，需结合 P 波与 QRS 形态复核。"),
                above: L10n.text("测量值高于参考范围。迷走神经张力、部分减慢心率的药物或房室传导延迟都可能影响 PR；请结合原图和用药情况复核。"))
        case .qrs:
            SegmentReference(upper: 120, upperInclusive: false, range: L10n.text("成人参考：QRS < 120 ms"),
                context: L10n.text("常见 QRS 约 70–100 ms；小于 120 ms 仅表示未达到常用增宽界限，不表示心电正常。"), below: "",
                above: L10n.text("测量值达到或超过常用增宽界限。可能与心室传导延迟、起搏或不同起源的心跳有关，也可能是边界识别误差；需结合完整心电图复核。"))
        case .qtc:
            SegmentReference(range: L10n.text("成人 QTc：男性约 350–450 ms；女性约 360–460 ms"),
                context: L10n.text("需结合性别、年龄和校正公式判断。QTc 偏长可能与药物、电解质或遗传因素有关；偏短也可能与电解质或遗传因素有关。心率及 T 波终点误差会改变估算结果。"), below: "", above: "")
        case .rr:
            SegmentReference(lower: 600, upper: 1000, range: L10n.text("成人静息参考：RR 600–1000 ms（60–100 bpm）"),
                context: L10n.text("仅适用于成人安静状态。呼吸、运动、睡眠、体能和药物都可能改变心跳间隔。"),
                below: L10n.text("间隔较短表示心率较快。运动、紧张、咖啡因、发热等都可能造成变化；若静息时持续偏快或伴不适，可咨询医生。"),
                above: L10n.text("间隔较长表示心率较慢。睡眠、较好的体能、药物或传导变化都可能造成变化；漏检波峰也会拉长间隔，需要复核原图。"))
        default:
            SegmentReference(range: L10n.text("没有适用于本次单导联测量的统一正常区间"), context: reference, below: "", above: "")
        }
    }
}
