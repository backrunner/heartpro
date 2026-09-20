import Foundation

/// Exploratory delineation, not a validated clinical interval detector. All voltage
/// measurements use a lightly smoothed raw trace, never the R detector's high-pass trace.
enum SegmentAnalyzer {
    static func analyze(_ waveform: Waveform, analysis: ECGAnalysis) -> SegmentAnalysis {
        let signal = SegmentSignal(waveform: waveform, windows: analysis.windows)
        let peaks = analysis.peakTimes
        let anchors = peaks.indices.map { i in
            signal.baselineAnchor(before: peaks[i], rr: i > 0 ? peaks[i] - peaks[i - 1] : 0.8)
        }
        var drafts = peaks.indices.map { i in
            delineate(signal, id: i, r: peaks[i], previous: i > 0 ? peaks[i - 1] : nil,
                      next: i + 1 < peaks.count ? peaks[i + 1] : nil,
                      anchor: anchors[i], nextAnchor: i + 1 < anchors.count ? anchors[i + 1] : nil)
        }
        // Inter-beat measures require adjacent beats and uninterrupted source samples.
        for i in drafts.indices {
            if i > 0 {
                let left = drafts[i - 1], right = drafts[i]
                if signal.usable(left.beat.rTime, right.beat.rTime) {
                    drafts[i].set(.rrDuration, (right.beat.rTime - left.beat.rTime) * 1000)
                    drafts[i].range(.rr, left.beat.rTime, right.beat.rTime)
                    if let p0 = left.p?.peak, let p1 = right.p?.peak,
                       signal.usable(signal.time(p0), signal.time(p1)) {
                        drafts[i].set(.ppDuration, (signal.time(p1) - signal.time(p0)) * 1000)
                    }
                }
                let rr = right.beat.rTime - left.beat.rTime
                let priorRR = i > 1 ? left.beat.rTime - drafts[i - 2].beat.rTime : nil
                let adjacentRR = i + 1 < drafts.count ? drafts[i + 1].beat.rTime - right.beat.rTime : nil
                let neighbors = [priorRR, adjacentRR].compactMap { $0 }
                let stable = neighbors.count == 2 && neighbors.allSatisfy { abs($0 - rr) <= rr * 0.1 }
                let continuous = i > 1 && i + 1 < drafts.count && signal.usable(drafts[i - 2].beat.rTime, drafts[i + 1].beat.rTime)
                if let qt = right.get(.qtDuration), stable, continuous, rr >= 0.5, rr <= 1.5 {
                    drafts[i].set(.qtcFridericia, qt / pow(rr, 1.0 / 3.0))
                    drafts[i].set(.qtcBazett, qt / sqrt(rr))
                    drafts[i].range(.qtc, right.beat.observation(.qt)?.start, right.beat.observation(.qt)?.end)
                } else {
                    drafts[i].reject(.qtc, "QT 终点不清，或连续 RR 不足／波动超过 10%／心率超出研究窗口")
                }
            }
            if i + 1 < drafts.count, let end = drafts[i].t?.end, let start = drafts[i + 1].p?.start,
               signal.time(start) - signal.time(end) >= 0.04, signal.usable(signal.time(end), signal.time(start)) {
                drafts[i].set(.tpDuration, (signal.time(start) - signal.time(end)) * 1000)
                drafts[i].range(.tp, signal.time(end), signal.time(start))
            }
            // Only a small, separately bounded post-T deflection can be a U candidate.
            // Never shorten a fused/biphasic T wave to create space for one.
            if i + 1 < drafts.count, let t = drafts[i].t, let end = t.end,
               let nextP = drafts[i + 1].p?.start,
               let baseline = signal.mean(signal.time(end) + 0.012, signal.time(end) + 0.032) {
                let a = signal.time(end) + 0.04
                let b = min(signal.time(end) + 0.34, signal.time(nextP) - 0.05)
                if b - a >= 0.10, signal.usable(a, b), let range = signal.indices(a, b),
                   let candidate = signal.wave(range: range, baseline: baseline, minimumAmplitude: 0.018),
                   let first = candidate.start, let last = candidate.end,
                   signal.time(first) >= a + 0.008, signal.time(last) <= b - 0.012,
                   (0.04...0.14).contains(signal.time(last) - signal.time(first)) {
                    let amplitude = signal.y[candidate.peak] - baseline
                    let tAmplitude = abs(signal.y[t.peak] - baseline)
                    if abs(amplitude) <= min(0.15, tAmplitude * 0.25) {
                        drafts[i].set(.uAmplitude, amplitude)
                        drafts[i].range(.u, signal.time(first), signal.time(last), peak: signal.time(candidate.peak))
                    }
                }
            }
        }
        // Isolated low-amplitude bumps are too easy to confuse with noise. Retain only
        // candidates repeated at a similar delay after T on at least three beats.
        let candidates = drafts.indices.filter { drafts[$0].get(.uAmplitude) != nil }
        let delays = candidates.compactMap { i -> Double? in
            guard let peak = drafts[i].beat.observation(.u)?.peak, let end = drafts[i].t?.end else { return nil }
            return peak - signal.time(end)
        }
        let delay = Statistics.median(delays) ?? 0
        let consistent = candidates.filter { i in
            guard let peak = drafts[i].beat.observation(.u)?.peak, let end = drafts[i].t?.end else { return false }
            return abs(peak - signal.time(end) - delay) <= 0.04
        }
        for i in candidates where consistent.count < 3 || !consistent.contains(i) {
            drafts[i].reject(.u, "U 候选未在至少三次心跳中重复出现")
        }
        return SegmentAnalysis(beats: drafts.map(\.beat), samplingFrequency: waveform.samplingFrequency,
                               unavailableReason: peaks.isEmpty ? "未检测到可供分段的 R 候选峰。" : nil)
    }

    private static func delineate(_ original: SegmentSignal, id: Int, r: Double, previous: Double?, next: Double?,
                                  anchor: BaselineAnchor?, nextAnchor: BaselineAnchor?) -> Draft {
        var draft = Draft(id: id, r: r)
        guard original.fs >= 200 else { draft.rejectAll("采样率低于 200 Hz，不进行精细波段定位"); return draft }
        let previousRR = previous.map { r - $0 } ?? 0.8
        let nextRR = next.map { $0 - r } ?? 0.8
        guard previousRR >= 0.35, nextRR >= 0.35, previousRR <= 2, nextRR <= 2 else {
            draft.rejectAll("相邻 RR 超出 350–2000 ms 的研究窗口，可能出现波形重叠或峰识别错误")
            return draft
        }
        guard let anchor else {
            draft.rejectAll("局部 TP 基线不稳定或噪声过大，无法可靠确定振幅与边界")
            return draft
        }
        guard original.usable(anchor.start, r + 0.15) else {
            draft.rejectAll("心搏前缘／基线不完整，或跨越低质量片段和采样缺口")
            return draft
        }
        let after = nextAnchor.flatMap { original.usable(anchor.time, $0.time) ? $0 : nil }
        // Remove only slow drift estimated from quiet inter-beat anchors. The raw
        // waveform remains untouched; displaced ST is not used as a baseline anchor.
        let s = original.correctingBaseline(anchor, after)
        let baseline = 0.0
        let noise = anchor.noise
        guard let rIndex = s.nearest(r), let qrsRange = s.indices(r - 0.15, r + 0.16) else { return draft }
        let amplitude = abs(s.y[rIndex] - baseline)
        guard amplitude >= max(0.12, noise * 10) else { draft.rejectAll("主峰振幅相对噪声不足"); return draft }
        guard s.residualNoise(qrsRange) <= max(0.008, amplitude * 0.06) else {
            draft.rejectAll("QRS 局部高频噪声过大，无法稳定定位边界"); return draft
        }
        // QRS endpoints follow a return to low slope, not a return to zero voltage.
        // Requiring a zero crossing would erase or mislabel an elevated/depressed ST plateau.
        guard let onset = s.qrsBoundary(range: qrsRange, peak: rIndex, baseline: baseline, noise: noise, direction: -1),
              let offset = s.qrsBoundary(range: qrsRange, peak: rIndex, baseline: baseline, noise: noise, direction: 1),
              s.time(offset) - s.time(onset) >= 0.025, s.time(offset) - s.time(onset) <= 0.24 else {
            draft.rejectAll("QRS 起止点不清、未回到局部基线或多峰融合")
            return draft
        }
        draft.range(.qrs, s.time(onset), s.time(offset), peak: r)
        draft.set(.qrsDuration, (s.time(offset) - s.time(onset)) * 1000)
        draft.set(.rAmplitude, s.y[rIndex] - baseline)
        draft.set(.rPeakTime, (r - s.time(onset)) * 1000)
        let polarity = s.y[rIndex] >= baseline ? 1.0 : -1.0
        draft.morphology(.qrs, polarity > 0 ? "主峰正向；Q／S 按主峰两侧的反向分量寻找" : "主峰负向；Q／R／S 命名需人工复核，未自动翻转电压")
        for (range, ampMetric, widthMetric) in [(onset..<rIndex, SegmentMetric.qAmplitude, SegmentMetric.qDuration),
                                               ((rIndex + 1)..<(offset + 1), .sAmplitude, .sDuration)] {
            if let index = range.min(by: { (s.y[$0] - baseline) * polarity < (s.y[$1] - baseline) * polarity }),
               (s.y[index] - baseline) * polarity < -max(0.025, noise * 4) {
                var a = index, b = index
                while a > range.lowerBound && (s.y[a - 1] - baseline) * polarity < 0 { a -= 1 }
                while b < range.upperBound - 1 && (s.y[b + 1] - baseline) * polarity < 0 { b += 1 }
                draft.set(ampMetric, s.y[index] - baseline)
                draft.set(widthMetric, (s.time(b) - s.time(a)) * 1000)
            }
        }

        if let range = s.indices(r - min(0.32, previousRR * 0.38), s.time(onset) - 0.025),
           s.usable(s.time(range.lowerBound), s.time(range.upperBound - 1)) {
            draft.p = s.wave(range: range, baseline: baseline, minimumAmplitude: max(0.025, noise * 5))
        }
        if let p = draft.p {
            draft.range(.p, p.start.map(s.time), p.end.map(s.time), peak: s.time(p.peak))
            draft.set(.pAmplitude, s.y[p.peak] - baseline)
            draft.morphology(.p, p.morphology)
            if let a = p.start, let b = p.end {
                let width = s.time(b) - s.time(a)
                if width >= 0.035, width <= 0.18 { draft.set(.pDuration, width * 1000) }
                else { draft.p = nil; draft.reject(.p, "P 候选时限超出研究窗口，可能为噪声或波形融合") }
            }
        }
        if let a = draft.p?.start {
            draft.set(.prDuration, (s.time(onset) - s.time(a)) * 1000)
            draft.range(.pr, s.time(a), s.time(onset))
        }
        if let b = draft.p?.end, s.time(onset) - s.time(b) >= 0.016 {
            draft.set(.prSegmentDuration, (s.time(onset) - s.time(b)) * 1000)
            draft.set(.prLevel, s.mean(s.time(b) + 0.004, s.time(onset) - 0.004).map { $0 - baseline })
            draft.range(.prSegment, s.time(b), s.time(onset))
        }

        // Stop before the next P search region. Truncation yields a missing T end, never a guessed QT.
        let tLimit = min(r + 0.65, next.map { $0 - min(0.32, nextRR * 0.38) } ?? s.duration)
        let tStart = s.time(offset) + 0.035
        if tLimit > tStart, s.usable(s.time(offset), tLimit), let range = s.indices(tStart, tLimit) {
            draft.t = s.wave(range: range, baseline: baseline, minimumAmplitude: max(0.035, noise * 5))
            // For a displaced but flat ST plateau, locate the T onset relative to
            // that plateau, while retaining the T end relative to the TP baseline.
            if draft.t?.start == nil, let plateau = s.indices(s.time(offset) + 0.012, s.time(offset) + 0.030) {
                let values = plateau.map { s.y[$0] }
                if (values.max() ?? 0) - (values.min() ?? 0) < max(0.01, noise * 3),
                   let local = Statistics.median(values), abs(local - baseline) > noise * 3 {
                    draft.t?.start = s.wave(range: range, baseline: local, minimumAmplitude: max(0.035, noise * 5))?.start
                }
            }
        }
        if let t = draft.t {
            draft.range(.t, t.start.map(s.time), t.end.map(s.time), peak: s.time(t.peak))
            draft.set(.tAmplitude, s.y[t.peak] - baseline)
            draft.morphology(.t, t.morphology)
            if let a = t.start, let b = t.end, b > a {
                draft.set(.tDuration, (s.time(b) - s.time(a)) * 1000)
                if b > t.peak { draft.set(.tSymmetry, (s.time(t.peak) - s.time(a)) / (s.time(b) - s.time(t.peak))) }
            }
            if let b = t.end, s.time(b) > s.time(offset) {
                draft.set(.qtDuration, (s.time(b) - s.time(onset)) * 1000)
                draft.range(.qt, s.time(onset), s.time(b))
            }
        }
        let j = s.time(offset)
        draft.range(.st, j, draft.t?.start.map(s.time))
        draft.set(.jLevel, s.y[offset] - baseline)
        if let a = draft.t?.start {
            let tOnset = s.time(a)
            draft.set(.stDuration, (tOnset - j) * 1000)
            for (delta, metric) in [(0.06, SegmentMetric.st60), (0.08, .st80)] {
                if j + delta + 0.004 < tOnset, s.usable(j, j + delta + 0.004) {
                    draft.set(metric, s.mean(j + delta - 0.004, j + delta + 0.004).map { $0 - baseline })
                } else { draft.set(metric, nil, reason: "采样点已接近或进入 T 波，不能作为 ST 电位") }
            }
            if let a = draft.get(.st60), let b = draft.get(.st80) { draft.set(.stSlope, (b - a) / 0.02) }
        }
        return draft
    }
}

private struct LocatedWave {
    var start: Int?
    var end: Int?
    var peak: Int
    var morphology: String
}

private struct Draft {
    var beat: SegmentBeat
    var p: LocatedWave?
    var t: LocatedWave?
    init(id: Int, r: Double) {
        beat = SegmentBeat(id: id, rTime: r, observations: ECGSegment.allCases.map { segment in
            let reason: String
            switch segment {
            case .p, .pr, .prSegment: reason = "P 波低幅、起止点不清或与相邻波形融合"
            case .qrs: reason = "未辨认出独立分量；不以零值代替"
            case .t, .qt: reason = "T 波低幅、边界不清、片段不完整或与下一搏重叠"
            case .st: reason = "T 波起点不清，无法确定 ST 测量窗口"
            case .qtc: reason = "缺少同搏 QT 与连续稳定的前序 RR"
            case .tp: reason = "本搏 T 终点或下一搏 P 起点不可测，或区间不连续"
            case .rr: reason = "前一搏缺失、P 波不清或区间不连续"
            case .u: reason = "尚无可靠的 T–U 自动分离方法"
            }
            return SegmentObservation(segment: segment, values: segment.metrics.map { SegmentValue(metric: $0, reason: reason) })
        })
    }
    mutating func set(_ metric: SegmentMetric, _ value: Double?, reason: String? = nil) {
        for i in beat.observations.indices {
            if let j = beat.observations[i].values.firstIndex(where: { $0.metric == metric }) {
                let valid = value.flatMap { $0.isFinite ? $0 : nil }
                beat.observations[i].values[j] = SegmentValue(metric: metric, value: valid, reason: valid == nil ? reason ?? "所需边界不可测" : nil)
                return
            }
        }
    }
    func get(_ metric: SegmentMetric) -> Double? { beat.observations.flatMap(\.values).first { $0.metric == metric }?.value }
    mutating func range(_ segment: ECGSegment, _ start: Double?, _ end: Double?, peak: Double? = nil) {
        guard let i = beat.observations.firstIndex(where: { $0.segment == segment }) else { return }
        beat.observations[i].start = start; beat.observations[i].end = end; beat.observations[i].peak = peak
    }
    mutating func morphology(_ segment: ECGSegment, _ text: String) {
        guard let i = beat.observations.firstIndex(where: { $0.segment == segment }) else { return }
        beat.observations[i].morphology = text
    }
    mutating func reject(_ segment: ECGSegment, _ reason: String) {
        for metric in segment.metrics { set(metric, nil, reason: reason) }
        range(segment, nil, nil)
        if let i = beat.observations.firstIndex(where: { $0.segment == segment }) { beat.observations[i].morphology = nil }
    }
    mutating func rejectAll(_ reason: String) { for segment in ECGSegment.allCases where segment != .u { reject(segment, reason) } }
}

private struct BaselineAnchor {
    var start: Double
    var time: Double
    var level: Double
    var slope: Double
    var noise: Double
    var cost: Double
}

private struct SegmentSignal {
    let fs: Double
    let times: [Double]
    var raw: [Double]
    var y: [Double]
    let windows: [SignalWindow]
    var duration: Double { times.last ?? 0 }
    init(waveform: Waveform, windows: [SignalWindow]) {
        fs = waveform.samplingFrequency; times = waveform.points.map(\.time)
        raw = waveform.points.map(\.millivolts); self.windows = windows
        // Symmetric <= 10 ms averaging preserves polarity and DC level; no baseline subtraction filter.
        let radius = max(0, Int(fs * 0.004))
        let count = raw.count
        var sums = [Double](repeating: 0, count: raw.count + 1)
        for i in raw.indices { sums[i + 1] = sums[i] + raw[i] }
        y = raw.indices.map { i in
            let a = max(0, i - radius), b = min(count, i + radius + 1)
            return (sums[b] - sums[a]) / Double(b - a)
        }
    }
    /// Fit quiet 25–60 ms patches in an RR-scaled TP search region. A raw
    /// voltage range confounds baseline wander with noise; residuals do not.
    func baselineAnchor(before r: Double, rr: Double) -> BaselineAnchor? {
        let a = r - min(0.44, rr * 0.48)
        let b = r - min(0.28, rr * 0.32)
        let length = min(0.06, b - a)
        guard length >= 0.025 else { return nil }
        var best: BaselineAnchor?
        for start in stride(from: a, through: b - length + 0.00001, by: 0.008) {
            guard usable(start, start + length), let range = indices(start, start + length) else { continue }
            let center = range.reduce(0.0) { $0 + times[$1] } / Double(range.count)
            let level = range.reduce(0.0) { $0 + raw[$1] } / Double(range.count)
            let energy = range.reduce(0.0) { $0 + pow(times[$1] - center, 2) }
            guard energy > 0 else { continue }
            let slope = range.reduce(0.0) { $0 + (times[$1] - center) * (raw[$1] - level) } / energy
            let residual = range.map { raw[$0] - level - slope * (times[$0] - center) }
            let median = Statistics.median(residual) ?? 0
            let noise = max(0.001, (Statistics.median(residual.map { abs($0 - median) }) ?? 0) * 1.4826)
            let spread = (residual.max() ?? 0) - (residual.min() ?? 0)
            guard abs(slope) <= 0.6, noise <= 0.012, spread <= 0.045 else { continue }
            let candidate = BaselineAnchor(start: start, time: center, level: level, slope: slope, noise: noise,
                                           cost: noise + spread * 0.1 + abs(slope) * 0.002)
            if best == nil || candidate.cost < best!.cost { best = candidate }
        }
        return best
    }

    func correctingBaseline(_ first: BaselineAnchor, _ last: BaselineAnchor?) -> Self {
        func reference(_ time: Double) -> Double {
            guard let last, last.time > first.time, time >= first.time, time <= last.time else {
                let anchor = last.flatMap { time > $0.time ? $0 : nil } ?? first
                return anchor.level + anchor.slope * (time - anchor.time)
            }
            // Hermite interpolation follows smooth drift without flattening ST or
            // assigning P/T endpoints from a template. Only baseline anchors are interpolated.
            let width = last.time - first.time, u = (time - first.time) / width
            return (2 * u * u * u - 3 * u * u + 1) * first.level
                + (u * u * u - 2 * u * u + u) * width * first.slope
                + (-2 * u * u * u + 3 * u * u) * last.level
                + (u * u * u - u * u) * width * last.slope
        }
        var corrected = self
        let baseline = times.map(reference)
        corrected.raw = zip(raw, baseline).map(-)
        corrected.y = zip(y, baseline).map(-)
        return corrected
    }

    func time(_ index: Int) -> Double { times[index] }
    func lowerBound(_ time: Double) -> Int {
        var a = 0, b = times.count
        while a < b { let mid = (a + b) / 2; if times[mid] < time { a = mid + 1 } else { b = mid } }
        return a
    }
    func indices(_ start: Double, _ end: Double) -> Range<Int>? {
        guard start.isFinite, end.isFinite, end > start else { return nil }
        let a = lowerBound(start), b = min(times.count, lowerBound(end) + 1)
        return b > a ? a..<b : nil
    }
    func nearest(_ time: Double) -> Int? {
        guard !times.isEmpty else { return nil }
        let i = min(times.count - 1, lowerBound(time))
        return i > 0 && abs(times[i - 1] - time) < abs(times[i] - time) ? i - 1 : i
    }
    func usable(_ start: Double, _ end: Double) -> Bool {
        guard let first = times.first, start >= first, end <= duration, end > start,
              !windows.contains(where: { !$0.usable && $0.start < end && $0.end > start }),
              let range = indices(start, end), Double(range.count) >= (end - start) * fs * 0.9 else { return false }
        let firstIndex = max(1, range.lowerBound)
        return (firstIndex..<range.upperBound).allSatisfy { times[$0] - times[$0 - 1] <= 1.8 / fs }
    }
    func mean(_ start: Double, _ end: Double) -> Double? {
        guard let range = indices(start, end), usable(start, end) else { return nil }
        return range.reduce(0) { $0 + y[$1] } / Double(range.count)
    }
    func qrsBoundary(range: Range<Int>, peak: Int, baseline: Double, noise: Double, direction: Int) -> Int? {
        func slope(_ i: Int) -> Double {
            let a = max(0, i - 1), b = min(y.count - 1, i + 1)
            return abs((y[b] - y[a]) / (times[b] - times[a]))
        }
        let peakSlope = range.map(slope).max() ?? 0
        let cut = max(0.6, peakSlope * 0.045, noise / 0.008 * 3)
        let quiet = max(2, Int(ceil(fs * 0.012)))
        let amplitude = abs(y[peak] - baseline)
        var i = peak, count = 0
        while range.contains(i) {
            if slope(i) < cut && abs(y[i] - baseline) < amplitude * 0.65 { count += 1 } else { count = 0 }
            if count >= quiet {
                let boundary = i - direction * (quiet - 1)
                if abs(time(boundary) - time(peak)) >= 0.012 { return boundary }
            }
            i += direction
        }
        return nil
    }
    func residualNoise(_ range: Range<Int>) -> Double {
        (Statistics.median(range.map { abs(raw[$0] - y[$0]) }) ?? 0) * 1.4826
    }
    func wave(range: Range<Int>, baseline: Double, minimumAmplitude: Double = 0) -> LocatedWave? {
        guard range.count >= 4, let peak = range.max(by: { abs(y[$0] - baseline) < abs(y[$1] - baseline) }) else { return nil }
        let margin = max(1, Int(ceil(fs * 0.008)))
        // A maximum against the search edge is a truncated slope, not a measured peak.
        guard peak - range.lowerBound >= margin, range.upperBound - 1 - peak >= margin else { return nil }
        let height = abs(y[peak] - baseline)
        guard height >= minimumAmplitude, residualNoise(range) <= max(0.006, height * 0.08) else { return nil }
        let cut = max(0.008, height * 0.10)
        let quiet = max(2, Int(ceil(fs * 0.012)))
        func boundary(direction: Int) -> Int? {
            var i = peak, count = 0
            while range.contains(i) {
                if abs(y[i] - baseline) <= cut { count += 1 } else { count = 0 }
                if count >= quiet { return i - direction * (quiet - 1) }
                i += direction
            }
            return nil
        }
        var start = boundary(direction: -1), end = boundary(direction: 1)
        // A second substantial lobe invalidates a single-wave endpoint if separated
        // by a quiet gap; do not silently report only half a biphasic wave as QT.
        let substantial = max(cut * 2, height * 0.25)
        let active = range.filter { abs(y[$0] - baseline) >= substantial }
        if let first = active.first, let a = start, first < a { start = nil }
        if let last = active.last, let b = end, last > b { end = nil }
        let positive = range.map { y[$0] - baseline }.max() ?? 0
        let negative = range.map { y[$0] - baseline }.min() ?? 0
        let bipolar = positive >= substantial && negative <= -substantial
        return LocatedWave(start: start, end: end, peak: peak,
                           morphology: bipolar ? "双相／多峰候选；分离的波瓣不合并为确定边界" : (y[peak] >= baseline ? "正向" : "负向"))
    }
}
