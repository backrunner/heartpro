import Foundation

/// Versioned research features, not confirmed beat origins or a normal-beat classifier.
public struct RhythmAssessment: Codable, Sendable, Equatable {
    public static let policyVersion = "rhythm-review-1"
    public var version = Self.policyVersion
    public var beats: [RhythmBeat]
    public var referenceBeatCount: Int
    public var detectedBeatCount: Int
    public var score: Int?
    public var limitation: Limitation?
    public enum Limitation: String, Codable, Sendable {
        case insufficientSignal, insufficientBeats, unstableReference, irregularRhythm, sourceClassification
    }
    public var evaluated: [RhythmBeat] { limitation == .sourceClassification ? [] : beats.filter { $0.exclusion == nil } }
    public var flagged: [RhythmBeat] { evaluated.filter(\.needsReview) }
    public var candidates: [RhythmBeat] { limitation == .sourceClassification ? [] : evaluated.filter { $0.candidate != nil } }
    public var excludedCount: Int { detectedBeatCount - evaluated.count }
    public func restricted(for classification: SourceClassification) -> Self {
        var copy = self
        if classification == .atrialFibrillation || classification == .poorReading {
            copy.score = nil; copy.limitation = .sourceClassification
        }
        return copy
    }
}

public struct RhythmBeat: Codable, Sendable, Equatable, Identifiable {
    public enum Candidate: String, Codable, Sendable { case wide, narrow, undetermined }
    public enum Exclusion: String, Codable, Sendable { case edge, discontinuity, waveform, reference, interval }
    public var id: Int
    public var time: Double
    public var precedingRR: Double?
    public var followingRR: Double?
    public var referenceRR: Double?
    public var qrsWidth: Double?
    public var correlation: Double?
    public var candidate: Candidate?
    public var intervalChanged = false
    public var shapeChanged = false
    public var exclusion: Exclusion?
    public var needsReview: Bool { candidate != nil || intervalChanged || shapeChanged }
    public var prematurityPercent: Double? {
        guard let precedingRR, let referenceRR, referenceRR > 0 else { return nil }
        return max(0, (1 - precedingRR / referenceRR) * 100)
    }
}

enum EctopyAnalyzer {
    private struct Shape {
        var values: [Double]
        var width: Double
    }

    static func analyze(_ wave: Waveform, analysis: ECGAnalysis) -> RhythmAssessment {
        let peaks = analysis.peakTimes
        let signal = SampledTrace(wave: wave)
        let intervals = Dictionary(uniqueKeysWithValues: analysis.intervals.map { ($0.id, $0.milliseconds) })
        let center = Statistics.median(analysis.intervals.map(\.milliseconds)) ?? 0
        let offsets = (0...80).map { -0.14 + Double($0) * 0.004 }
        func usable(_ start: Double, _ end: Double) -> Bool {
            start >= (wave.points.first?.time ?? 0) && end <= wave.duration &&
            !analysis.windows.contains { !$0.usable && $0.start < end && $0.end > start } && signal.continuous(start, end)
        }
        var shapes: [Int: Shape] = [:]
        if wave.samplingFrequency >= 200 {
            for (id, time) in peaks.enumerated() where usable(time - 0.14, time + 0.18) {
                let raw: [Double] = offsets.compactMap { signal.value(time + $0) }
                guard raw.count == offsets.count else { continue }
                let left = Statistics.median(Array(raw.prefix(5))) ?? 0
                let right = Statistics.median(Array(raw.suffix(5))) ?? 0
                let drift = (right - left) / Double(raw.count - 1)
                let values: [Double] = raw.indices.map { raw[$0] - left - drift * Double($0) }
                let amplitude = abs(values[35])
                guard amplitude >= 0.15, amplitude <= 4, abs(left - right) < amplitude * 0.5 else { continue }
                // Reject sharp impulses and high-frequency contamination before comparing morphology.
                let residual: [Double] = (1..<(raw.count - 1)).map { i in
                    let smoothed = (raw[i - 1] + 2 * raw[i] + raw[i + 1]) / 4
                    return abs(raw[i] - smoothed)
                }
                guard (Statistics.median(residual) ?? 1) < max(0.006, amplitude * 0.015) else { continue }
                let cut = max(0.02, amplitude * 0.10)
                var a = 35, b = 35
                while a > 1 && (abs(values[a]) > cut || abs(values[a - 1]) > cut) { a -= 1 }
                while b < values.count - 2 && (abs(values[b]) > cut || abs(values[b + 1]) > cut) { b += 1 }
                let width = Double(b - a) * 4
                guard a > 1, b < values.count - 2, width >= 28, width <= 240 else { continue }
                shapes[id] = Shape(values: values, width: width)
            }
        }
        // Build the template from beats with ordinary surrounding intervals, never from
        // the beat currently being classified or an indiscriminate average of every beat.
        let referenceIDs = peaks.indices.filter { id in
            guard let before = intervals[id], let after = intervals[id + 1], shapes[id] != nil, center > 0 else { return false }
            return abs(before - center) <= center * 0.15 && abs(after - center) <= center * 0.15
        }
        // With alternating short/long intervals there may be no ordinary-RR template.
        // A repeated narrower morphology can provide a comparison for wide candidates,
        // but an inferred cadence never qualifies a record for a numeric score.
        let widths = shapes.values.map(\.width).sorted()
        let upperWidth = widths.isEmpty ? 0 : widths[min(widths.count - 1, widths.count * 3 / 4)]
        let pairedReferenceIDs = peaks.indices.filter { id in
            guard let before = intervals[id], let after = intervals[id + 1], let shape = shapes[id] else { return false }
            return before > after * 1.20 && shape.width < upperWidth * 0.80
        }
        let usePairedTemplate = pairedReferenceIDs.count >= 4 && pairedReferenceIDs.count * 2 >= referenceIDs.count
        let templateIDs = usePairedTemplate || referenceIDs.count < 8 ? pairedReferenceIDs : referenceIDs
        let referenceWidth = Statistics.median(templateIDs.compactMap { shapes[$0]?.width }) ?? 0
        let template = offsets.indices.map { i in Statistics.median(templateIDs.compactMap { shapes[$0]?.values[i] }) ?? 0 }
        let templateEnergy = template.reduce(0) { $0 + $1 * $1 }
        func correlation(_ values: [Double]) -> Double {
            let energy = values.reduce(0) { $0 + $1 * $1 }
            return zip(values, template).reduce(0) { $0 + $1.0 * $1.1 } / max(0.000001, sqrt(energy * templateEnergy))
        }
        var beats: [RhythmBeat] = []
        var inferredCadence = false
        for (id, time) in peaks.enumerated() {
            var beat = RhythmBeat(id: id, time: time, precedingRR: intervals[id], followingRR: intervals[id + 1], qrsWidth: shapes[id]?.width)
            guard id > 0, id + 1 < peaks.count else { beat.exclusion = .edge; beats.append(beat); continue }
            guard let before = intervals[id], let after = intervals[id + 1], usable(peaks[id - 1], peaks[id + 1]) else {
                beat.exclusion = .discontinuity; beats.append(beat); continue
            }
            guard before >= 280, before <= 2500, after >= 280, after <= 2500 else {
                beat.exclusion = .interval; beats.append(beat); continue
            }
            guard let shape = shapes[id], shapes[id - 1] != nil, shapes[id + 1] != nil else {
                beat.exclusion = .waveform; beats.append(beat); continue
            }
            // Exclude the coupling interval and its following pause from the local baseline.
            let neighborhood = analysis.intervals.filter { abs($0.id - id) <= 10 && $0.id != id && $0.id != id + 1 }
            let local = neighborhood.map(\.milliseconds)
            let localCenter = Statistics.median(local) ?? 0
            let stable = !usePairedTemplate && local.count >= 6 && referenceIDs.count >= 8 &&
                (Statistics.median(local.map { abs($0 - localCenter) }) ?? localCenter) <= localCenter * 0.15
            let cadencePairs = neighborhood.compactMap { interval -> Double? in
                guard let next = intervals[interval.id + 1], min(interval.milliseconds, next) < max(interval.milliseconds, next) * 0.8 else { return nil }
                return (interval.milliseconds + next) / 2
            }
            let pairedCenter = Statistics.median(cadencePairs) ?? 0
            let paired = cadencePairs.count >= 4 && templateIDs.count >= 4 &&
                (Statistics.median(cadencePairs.map { abs($0 - pairedCenter) }) ?? pairedCenter) <= pairedCenter * 0.1
            let reference = stable ? localCenter : pairedCenter
            guard (stable || paired), reference >= 450, reference <= 1500 else {
                beat.exclusion = .reference; beats.append(beat); continue
            }
            if !stable { inferredCadence = true }
            beat.referenceRR = reference
            beat.correlation = correlation(shape.values)
            beat.intervalChanged = abs(before - reference) > max(100, reference * 0.20)
            beat.shapeChanged = beat.correlation! < 0.90
            let early = before < reference * 0.85 && reference - before >= 80
            let pause = after > reference * 1.10 && (before + after) >= reference * 1.50 && (before + after) <= reference * 2.50
            let wideChanged = shape.width >= 120 && shape.width > referenceWidth * 1.20 && beat.correlation! < 0.90
            if early && ((stable && pause) || wideChanged) {
                if wideChanged { beat.candidate = .wide }
                else if shape.width < 120 && beat.correlation! >= 0.90 { beat.candidate = .narrow }
                else { beat.candidate = .undetermined }
            }
            beats.append(beat)
        }
        // A post-candidate pause is one event, not a second affected beat. Its shape
        // can still require review independently.
        let candidateIDs = Set(beats.filter { $0.candidate != nil }.map(\.id))
        for i in beats.indices where candidateIDs.contains(beats[i].id - 1) && beats[i].candidate == nil {
            beats[i].intervalChanged = false
        }
        let evaluated = beats.filter { $0.exclusion == nil }
        let irregular = evaluated.filter { $0.intervalChanged && $0.candidate == nil }.count
        var limitation: RhythmAssessment.Limitation?
        if analysis.validDuration < 20 || analysis.qualityFraction < 0.8 { limitation = .insufficientSignal }
        else if referenceIDs.count < 8 || inferredCadence { limitation = .unstableReference }
        else if evaluated.count < 15 || Double(evaluated.count) / Double(max(1, peaks.count - 2)) < 0.8 { limitation = .insufficientBeats }
        else if Double(irregular) / Double(max(1, evaluated.count)) > 0.20 { limitation = .irregularRhythm }
        let flagged = evaluated.filter(\.needsReview).count
        let score = limitation == nil ? Int((100 * (1 - Double(flagged) / Double(evaluated.count))).rounded()) : nil
        return RhythmAssessment(beats: beats, referenceBeatCount: referenceIDs.count, detectedBeatCount: peaks.count, score: score, limitation: limitation)
    }
}

/// Binary search and gap checks are shared by all morphology samples; never interpolate
/// across missing samples, even when a gap is shorter than a quality window.
private struct SampledTrace {
    let wave: Waveform
    func index(_ time: Double) -> Int {
        var lo = 0, hi = wave.points.count
        while lo < hi { let mid = (lo + hi) / 2; if wave.points[mid].time < time { lo = mid + 1 } else { hi = mid } }
        return lo
    }
    func value(_ time: Double) -> Double? {
        let i = index(time)
        guard i > 0, i < wave.points.count else { return nil }
        let a = wave.points[i - 1], b = wave.points[i]
        guard b.time - a.time <= 1.8 / wave.samplingFrequency else { return nil }
        return a.millivolts + (b.millivolts - a.millivolts) * (time - a.time) / (b.time - a.time)
    }
    func continuous(_ start: Double, _ end: Double) -> Bool {
        let a = max(1, index(start)), b = min(wave.points.count, index(end) + 1)
        return a < b && (a..<b).allSatisfy { wave.points[$0].time - wave.points[$0 - 1].time <= 1.8 / wave.samplingFrequency }
    }
}
