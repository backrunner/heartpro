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
    public func position(_ value: Double) -> Position {
        guard value.isFinite else { return .contextRequired }
        if let lower, value < lower { return .below }
        if let upper, upperInclusive ? value > upper : value >= upper { return .above }
        return lower == nil && upper == nil ? .contextRequired : .within
    }
    // Never select disease or treatment explanations using an individual's value.
    public func explanation(_ value: Double?) -> String { context }

}

extension ECGSegment {
    public var adultReference: SegmentReference {
        let context = L10n.text("参考值仅作一般资料，不根据本次测量推断病因或给出用药、治疗建议。单导联估算可能有误差，不能用于判断健康状况。")
        switch self {
        case .p:
            return SegmentReference(upper: 120, upperInclusive: false, range: L10n.text("成人参考：P 波 < 120 ms"), context: context)
        case .pr:
            return SegmentReference(lower: 120, upper: 200, range: L10n.text("成人参考：PR 120–200 ms"), context: context)
        case .qrs:
            return SegmentReference(upper: 120, upperInclusive: false, range: L10n.text("成人参考：QRS < 120 ms"), context: context)
        case .qtc:
            return SegmentReference(range: L10n.text("成人 QTc：男性约 350–450 ms；女性约 360–460 ms"), context: context)
        case .rr:
            return SegmentReference(lower: 600, upper: 1000, range: L10n.text("成人静息参考：RR 600–1000 ms（60–100 bpm）"), context: context)
        default:
            return SegmentReference(range: L10n.text("没有适用于本次单导联测量的统一正常区间"), context: context)
        }
    }
}
