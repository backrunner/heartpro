import Foundation
import Testing
@testable import HeartProCore

// Independent piecewise-linear fixture with explicit boundaries (not DemoData Gaussians).
private func segmentFixture(fs: Double = 500, rr: Double = 1, p: Bool = true, t: Bool = true,
                            inverted: Bool = false, offset: Double = 0, tEnd: Double = 0.40, stLevel: Double = 0,
                            uAmplitude: Double = 0) -> Waveform {
    var knots: [(Double, Double)] = [(-0.44, 0)]
    if p { knots += [(-0.24, 0), (-0.19, 0.12), (-0.14, 0)] }
    knots += [(-0.05, 0), (-0.035, -0.16), (-0.02, 0), (0, 1), (0.02, 0), (0.04, -0.22), (0.06, stLevel)]
    if t { knots += [(0.15, stLevel), (0.27, 0.25 + stLevel), (tEnd, 0)] }
    if uAmplitude != 0 { knots += [(0.48, 0), (0.525, uAmplitude), (0.57, 0)] }
    knots += [(max(0.65, tEnd + 0.01), 0)]
    let points = (0..<Int(15 * fs)).map { index -> VoltagePoint in
        let time = Double(index) / fs
        var value = 0.0
        // Superpose adjacent cycles so long T waves really overlap; never wrap a tail to zero.
        for cycle in Int(floor(time / rr))...Int(floor(time / rr)) + 1 {
            let relative = time - Double(cycle) * rr
            for (left, right) in zip(knots, knots.dropFirst()) where relative >= left.0 && relative < right.0 {
                value += left.1 + (right.1 - left.1) * (relative - left.0) / (right.0 - left.0)
            }
        }
        return VoltagePoint(time: time, millivolts: offset + value * (inverted ? -1 : 1))
    }
    return Waveform(samplingFrequency: fs, points: points)
}

private func segments(_ wave: Waveform) throws -> SegmentAnalysis { try #require(SignalAnalyzer.analyze(wave).segments) }

@Test func delineationMatchesKnownBoundariesAtMultipleSamplingRates() throws {
    for fs in [250.0, 500, 1000] {
        let result = try segments(segmentFixture(fs: fs))
        let expected: [(SegmentMetric, Double, Double)] = [(.pDuration, 100, 16), (.prDuration, 190, 14),
            (.prSegmentDuration, 90, 14), (.qrsDuration, 110, 12), (.tDuration, 250, 32),
            (.qtDuration, 450, 24), (.rrDuration, 1000, 2), (.ppDuration, 1000, 2),
            (.pAmplitude, 0.12, 0.015), (.tAmplitude, 0.25, 0.015), (.st60, 0, 0.006), (.st80, 0, 0.006)]
        for (metric, value, tolerance) in expected {
            let stat = result.statistics(metric)
            #expect(stat.count >= 10, "\(metric) at \(fs) Hz coverage \(stat.count)")
            let actual = try #require(stat.median, "\(metric) at \(fs) Hz")
            #expect(abs(actual - value) <= tolerance, "\(metric): \(actual) vs \(value) at \(fs) Hz")
        }
    }
}

@Test func inversionAndDCOffsetPreserveTimesAndSignedVoltages() throws {
    let positive = try segments(segmentFixture())
    let negative = try segments(segmentFixture(inverted: true, offset: 1.2))
    for metric in [SegmentMetric.pDuration, .prDuration, .qrsDuration, .qtDuration] {
        #expect(abs(try #require(positive.statistics(metric).median) - #require(negative.statistics(metric).median)) < 4)
    }
    for metric in [SegmentMetric.pAmplitude, .qAmplitude, .rAmplitude, .sAmplitude, .tAmplitude] {
        #expect(abs(try #require(positive.statistics(metric).median) + #require(negative.statistics(metric).median)) < 0.005)
    }
}

@Test func absentWavesDoNotReceiveFabricatedIntervals() throws {
    let noP = try segments(segmentFixture(p: false))
    for metric in [SegmentMetric.pDuration, .pAmplitude, .prDuration, .prSegmentDuration, .ppDuration, .tpDuration] {
        #expect(noP.statistics(metric).count == 0)
    }
    #expect(noP.statistics(.qrsDuration).count > 10)
    #expect(!noP.missingReasons(.p).isEmpty)
    let noT = try segments(segmentFixture(t: false))
    for metric in [SegmentMetric.tDuration, .tAmplitude, .qtDuration, .qtcFridericia, .st60, .st80] {
        #expect(noT.statistics(metric).count == 0)
    }
}

@Test func gapsRejectAffectedBeatsAndNeverJoinPPOrTP() throws {
    var wave = segmentFixture()
    // Gap straddles a 2 s quality-window boundary as well as an R peak.
    wave.points.removeAll { $0.time > 5.97 && $0.time < 6.05 }
    let result = try segments(wave)
    for beat in result.beats {
        for item in beat.observations {
            if let a = item.start, let b = item.end {
                #expect(!(a < 6.05 && b > 5.97), "\(item.segment) bridges gap")
            }
        }
    }
    // The missing R may itself be absent from the beat list. Do not require an
    // unrelated, fully recorded QRS to be rejected as well.
    #expect(result.statistics(.qrsDuration).count < (try segments(segmentFixture())).statistics(.qrsDuration).count)
    let afterGap = try #require(result.beats.first { $0.rTime > 6.05 })
    #expect(afterGap.observation(.rr)?.value(.rrDuration)?.value == nil)
    #expect(afterGap.observation(.rr)?.value(.ppDuration)?.value == nil)
}

@Test func qtcUsesPairedQTAndRRAndRejectsUnstableRhythm() throws {
    let wave = segmentFixture(rr: 0.8, tEnd: 0.36)
    var analysis = try SignalAnalyzer.analyze(wave)
    let result = try #require(analysis.segments)
    let beat = try #require(result.beats.first { $0.observation(.qtc)?.value(.qtcFridericia)?.value != nil })
    let qt = try #require(beat.observation(.qt)?.value(.qtDuration)?.value)
    #expect(abs(try #require(beat.observation(.qtc)?.value(.qtcFridericia)?.value) - qt / pow(0.8, 1.0 / 3)) < 1)
    #expect(abs(try #require(beat.observation(.qtc)?.value(.qtcBazett)?.value) - qt / sqrt(0.8)) < 1)
    analysis.peakTimes[5] += 0.18
    let modified = SegmentAnalyzer.analyze(wave, analysis: analysis)
    #expect(modified.beats[5].observation(.qtc)?.value(.qtcBazett)?.value == nil)
    #expect(modified.beats[6].observation(.qtc)?.value(.qtcBazett)?.value == nil)
}

@Test func lowSamplingRateAndFlatSignalsHaveExplicitUnavailableResults() throws {
    let result = try segments(segmentFixture(fs: 100))
    #expect(!result.beats.isEmpty)
    #expect(result.statistics(.qrsDuration).median == nil)
    #expect(result.missingReasons(.qrs).contains { $0.contains("200 Hz") })
    let flat = Waveform(samplingFrequency: 250, points: (0..<2500).map { VoltagePoint(time: Double($0) / 250, millivolts: 0) })
    let empty = try segments(flat)
    #expect(empty.beats.isEmpty)
    #expect(empty.unavailableReason != nil)
}

@Test func overlappingTAndUnstableBaselineSuppressMeasurements() throws {
    let truncated = try segments(segmentFixture(rr: 0.8, tEnd: 0.58))
    #expect(truncated.statistics(.qtDuration).median == nil)
    var noisy = segmentFixture()
    for i in noisy.points.indices {
        noisy.points[i].millivolts += 0.09 * sin(noisy.points[i].time * 2 * .pi * 37)
    }
    let result = try segments(noisy)
    #expect(result.statistics(.qrsDuration).median == nil)
}

@Test func noiseConfinedToTWaveDoesNotBecomeAQTMeasurement() throws {
    var wave = segmentFixture()
    for i in wave.points.indices {
        let phase = wave.points[i].time.truncatingRemainder(dividingBy: 1)
        if phase >= 0.12, phase <= 0.48 {
            wave.points[i].millivolts += 0.12 * sin(wave.points[i].time * 2 * .pi * 85)
        }
    }
    let result = try segments(wave)
    #expect(result.statistics(.qrsDuration).count > 10)
    #expect(result.statistics(.qtDuration).count == 0)
    #expect(result.statistics(.tAmplitude).count == 0)
}

@Test func truncatedRisingTIsNotReportedAsAPeak() throws {
    var wave = segmentFixture()
    wave.points.removeAll { $0.time >= 14.26 }
    let result = try segments(wave)
    let last = try #require(result.beats.last)
    #expect(abs(last.rTime - 14) < 0.01)
    #expect(last.observation(.t)?.value(.tAmplitude)?.value == nil)
    #expect(last.observation(.qt)?.value(.qtDuration)?.value == nil)
    #expect(result.statistics(.tAmplitude).count > 10)
}

@Test func STSamplesDoNotIncludeTWaveAndUnseparatedUIsUnavailable() throws {
    let result = try segments(DemoData.waveform())
    for beat in result.beats {
        let st = try #require(beat.observation(.st))
        for (metric, delta) in [(SegmentMetric.st60, 0.06), (.st80, 0.08)] where st.value(metric)?.value != nil {
            #expect(try #require(st.start) + delta + 0.004 < #require(beat.observation(.t)?.start))
        }
        #expect(beat.observation(.u)?.values.allSatisfy { $0.value == nil && $0.reason != nil } == true)
    }
    #expect(result.statistics(.pDuration).count > 20)
    #expect(result.statistics(.qtDuration).count > 20)
}

@Test func displacedSTUsesRawBaselineWithoutForcingJToZero() throws {
    for level in [0.10, -0.10] {
        let result = try segments(segmentFixture(stLevel: level))
        for metric in [SegmentMetric.jLevel, .st60, .st80] {
            #expect(result.statistics(metric).count > 10)
            #expect(abs(try #require(result.statistics(metric).median) - level) < 0.012)
        }
        #expect(abs(try #require(result.statistics(.qrsDuration).median) - 110) < 12)
    }
}

@Test func segmentStorageRoundTripsAndOldAnalysisStillDecodes() throws {
    let analysis = try SignalAnalyzer.analyze(segmentFixture())
    let data = try JSONEncoder().encode(analysis)
    #expect(try JSONDecoder().decode(ECGAnalysis.self, from: data) == analysis)
    var dictionary = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    dictionary.removeValue(forKey: "segments")
    dictionary["version"] = "0.2.0-research"
    let old = try JSONDecoder().decode(ECGAnalysis.self, from: JSONSerialization.data(withJSONObject: dictionary))
    #expect(old.segments == nil)
    #expect(old.version != ECGAnalysis.currentVersion)
}

@Test func URequiresSeparatedRepeatedSmallDeflections() throws {
    let clean = try segments(segmentFixture(uAmplitude: 0.04))
    #expect(clean.statistics(.uAmplitude).count >= 10)
    #expect(abs(try #require(clean.statistics(.uAmplitude).median) - 0.04) < 0.006)
    #expect(clean.visibleSegments.contains(.u))
    let negative = try segments(segmentFixture(inverted: true, offset: 1.2, uAmplitude: 0.04))
    #expect(abs(try #require(negative.statistics(.uAmplitude).median) + 0.04) < 0.006)
    let ordinary = try segments(segmentFixture())
    #expect(!ordinary.visibleSegments.contains(.u))
    let largeLobe = try segments(segmentFixture(uAmplitude: 0.12))
    #expect(largeLobe.statistics(.uAmplitude).count == 0)
    var isolated = segmentFixture(uAmplitude: 0.04)
    let ordinaryWave = segmentFixture()
    for i in isolated.points.indices where isolated.points[i].time < 6 || isolated.points[i].time >= 7 {
        isolated.points[i] = ordinaryWave.points[i]
    }
    #expect(try segments(isolated).statistics(.uAmplitude).count == 0)
}

// Compress an independently specified cycle while retaining a 500 Hz sampling grid.
private func rateScaledFixture(rr: Double) -> Waveform {
    let source = segmentFixture(fs: 500 * rr)
    return Waveform(samplingFrequency: 500, points: source.points.map {
        VoltagePoint(time: $0.time * rr, millivolts: $0.millivolts)
    })
}

@Test func fasterSeparateWavesAreNotRejectedByAnEmptyBaselineWindow() throws {
    for rr in [0.6, 0.5] {
        let result = try segments(rateScaledFixture(rr: rr))
        for (metric, expected, tolerance) in [(SegmentMetric.qrsDuration, 110 * rr, 14.0),
                                              (.pDuration, 100 * rr, 20), (.qtDuration, 450 * rr, 28)] {
            let stat = result.statistics(metric)
            #expect(stat.count >= 10, "\(metric) at \(60 / rr) bpm: \(result.missingReasons(.qrs))")
            #expect(abs(try #require(stat.median) - expected) < tolerance)
        }
    }
}

@Test func gradualBaselineDriftIsNotTreatedAsHighFrequencyNoise() throws {
    var wave = segmentFixture()
    for i in wave.points.indices {
        let t = wave.points[i].time
        wave.points[i].millivolts += 0.15 * sin(2 * .pi * 0.2 * t) + 0.02 * t
    }
    let result = try segments(wave)
    for (metric, expected, tolerance) in [(SegmentMetric.qrsDuration, 110.0, 16.0),
                                          (.pDuration, 100, 22), (.qtDuration, 450, 35)] {
        let stat = result.statistics(metric)
        #expect(stat.count >= 10, "\(metric): \(stat.count)")
        #expect(abs(try #require(stat.median) - expected) <= tolerance)
    }
    #expect(abs(try #require(result.statistics(.st60).median)) < 0.025)
}

@Test func driftCorrectionPreservesDisplacedSTAndPolarity() throws {
    for level in [-0.10, 0.10] {
        var wave = segmentFixture(stLevel: level)
        for i in wave.points.indices {
            let t = wave.points[i].time
            wave.points[i].millivolts += 0.15 * sin(2 * .pi * 0.2 * t) + 0.02 * t
        }
        let result = try segments(wave)
        for metric in [SegmentMetric.jLevel, .st60, .st80] {
            #expect(result.statistics(metric).count >= 10)
            #expect(abs(try #require(result.statistics(metric).median) - level) < 0.025)
        }
    }
}

@Test func waveformAnnotationsUseMeasuredBoundariesAndClipWithoutInventingEndpoints() throws {
    let analysis = try segments(segmentFixture())
    let spans = analysis.waveformAnnotations
    // Only waves are annotated on the waveform display, not segments
    #expect(Set(spans.map(\.kind)).isSuperset(of: [.p, .qrs, .t]))
    #expect(Set(spans.map(\.id)).count == spans.count)
    for span in spans {
        #expect(span.start >= 0 && span.end > span.start)
        let midpoint = (span.start + span.end) / 2
        #expect(span.clipped(to: span.start...midpoint) == span.start...midpoint)
        #expect(span.clipped(to: midpoint...span.end) == midpoint...span.end)
        #expect(span.clipped(to: span.end...(span.end + 1)) == nil)
    }
    let noP = try segments(segmentFixture(p: false)).waveformAnnotations
    #expect(!noP.contains { $0.kind == .p })
    let noT = try segments(segmentFixture(t: false)).waveformAnnotations
    #expect(!noT.contains { $0.kind == .t })
    var gap = segmentFixture()
    gap.points.removeAll { $0.time > 5.97 && $0.time < 6.05 }
    #expect(try segments(gap).waveformAnnotations.allSatisfy { !($0.start < 6.05 && $0.end > 5.97) })
}
