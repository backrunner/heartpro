import Foundation

/// Actual measured spans on the source time axis. No QTc span: QTc is a corrected
/// number, not an interval that exists at a different position on the waveform.
public struct WaveformAnnotation: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable {
        case p, qrs, t, u, prSegment, st, tp, pr, qt, rr, pp
        public var label: String {
            switch self {
            case .p: "P"
            case .qrs: "QRS"
            case .t: "T"
            case .u: "U"
            case .prSegment: L10n.text("PR 段")
            case .st: "ST"
            case .tp: "TP"
            case .pr: "PR"
            case .qt: "QT"
            case .rr: "RR"
            case .pp: "PP"
            }
        }
        public var lane: Int { 0 }
    }
    public var beatID: Int
    public var kind: Kind
    public var start: Double
    public var end: Double
    public var id: String { "\(beatID)-\(kind.rawValue)" }
    public var milliseconds: Double { (end - start) * 1000 }

    public func clipped(to range: ClosedRange<Double>) -> ClosedRange<Double>? {
        let a = max(start, range.lowerBound), b = min(end, range.upperBound)
        return b > a ? a...b : nil
    }
}

extension SegmentAnalysis {
    public var waveformAnnotations: [WaveformAnnotation] {
        var result: [WaveformAnnotation] = []
        // Only mark waves (P, QRS, T, U), not segments or intervals.
        // Segment and interval values are available in the statistics panel.
        let kinds: [(ECGSegment, WaveformAnnotation.Kind, SegmentMetric)] = [
            (.p, .p, .pDuration), (.qrs, .qrs, .qrsDuration), (.t, .t, .tDuration), (.u, .u, .uAmplitude)
        ]
        for beat in beats {
            for (segment, kind, metric) in kinds {
                guard let observation = beat.observation(segment), observation.value(metric)?.value != nil,
                      let start = observation.start, let end = observation.end,
                      start.isFinite, end.isFinite, start >= 0, end > start else { continue }
                result.append(WaveformAnnotation(beatID: beat.id, kind: kind, start: start, end: end))
            }
        }
        return result.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
    }
}
