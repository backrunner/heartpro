import Foundation

/// Explicitly synthetic fixtures; never written to HealthKit or mixed with imported records.
public enum DemoData {
    public static func heartHealth(from start: Date, to end: Date, hourly: Bool = false) -> HeartHealthSnapshot {
        let calendar = Calendar.current
        var buckets: [HeartRateBucket] = []
        var cursor = start
        let component: Calendar.Component = hourly ? .hour : .day
        while let next = calendar.date(byAdding: component, value: 1, to: cursor), next <= end {
            let phase = Double(calendar.ordinality(of: .day, in: .year, for: cursor) ?? 0)
            let average = 64 + (sin(phase / 6) * 4) + (hourly ? sin(Double(calendar.component(.hour, from: cursor)) / 3) * 3 : 0)
            buckets.append(HeartRateBucket(date: cursor, end: next, average: average, minimum: average - 11, maximum: average + 17))
            cursor = next
        }
        return HeartHealthSnapshot(heartRates: buckets)
    }
    /// A reproducible morphology example for development and UI verification.
    public static func rhythmExample() -> Waveform {
        let fs = 500.0
        let beats = (1..<30).map { i in (Double(i) - ([9, 19].contains(i) ? 0.35 : 0), i == 19) }
        let points = (0..<15500).map { i -> VoltagePoint in
            let time = Double(i) / fs
            var value = 0.0
            for (r, wide) in beats where time - r > -0.3 && time - r < 0.65 {
                let x = time - r
                let knots: [(Double, Double)] = wide
                    ? [(-0.10, 0), (-0.02, -1.2), (0, -1.4), (0.11, 0), (0.18, 0), (0.28, 0.25), (0.4, 0)]
                    : [(-0.24, 0), (-0.19, 0.1), (-0.14, 0), (-0.04, 0), (0, 1), (0.04, 0), (0.15, 0), (0.27, 0.25), (0.40, 0), (0.48, 0), (0.525, 0.04), (0.57, 0)]
                for (a, b) in zip(knots, knots.dropFirst()) where x >= a.0 && x < b.0 {
                    value += a.1 + (b.1 - a.1) * (x - a.0) / (b.0 - a.0)
                }
            }
            return VoltagePoint(time: time, millivolts: value)
        }
        return Waveform(samplingFrequency: fs, points: points)
    }
    public static func waveform(bpm: Double = 68, seconds: Double = 30, samplingRate: Double = 256, phase: Double = 0) -> Waveform {
        let interval = 60 / bpm
        func gaussian(_ t: Double, _ center: Double, _ width: Double, _ height: Double) -> Double {
            height * exp(-pow((t - center) / width, 2) / 2)
        }
        let points = (0..<Int(seconds * samplingRate)).map { i -> VoltagePoint in
            let t = Double(i) / samplingRate
            let cycle = (t + phase).truncatingRemainder(dividingBy: interval)
            let center = interval * 0.42
            let p = gaussian(cycle, center - 0.17, 0.027, 0.1)
            let q = gaussian(cycle, center - 0.022, 0.008, -0.13)
            let r = gaussian(cycle, center, 0.010, 1.02)
            let s = gaussian(cycle, center + 0.024, 0.011, -0.23)
            let waveT = gaussian(cycle, center + 0.22, 0.050, 0.23)
            return VoltagePoint(time: t, millivolts: p + q + r + s + waveT + sin(t * 1.7) * 0.015)
        }
        return Waveform(samplingFrequency: samplingRate, points: points)
    }

    public static func records(now: Date = .now, calendar: Calendar = .current) -> [ECGRecord] {
        var records: [ECGRecord] = []
        let offsets: [TimeInterval] = [34920, 29760, 27000]
        let firstDayRates: [Double] = [68, 72, 65]
        var cache: [Double: (Waveform, ECGAnalysis?)] = [:]
        for day in 0..<35 {
            guard let base = calendar.date(byAdding: .day, value: -day, to: calendar.startOfDay(for: now)) else { continue }
            let count = day == 0 ? 3 : (day % 5 == 0 ? 0 : 1 + day % 3)
            for index in 0..<count {
                let date = base.addingTimeInterval(offsets[index])
                let bpm = day == 0 ? firstDayRates[index] : Double(63 + (day * 7 + index * 3) % 18)
                if cache[bpm] == nil {
                    let wave = waveform(bpm: bpm)
                    cache[bpm] = (wave, try? SignalAnalyzer.analyze(wave))
                }
                guard let (wave, analysis) = cache[bpm] else { continue }
                let record = ECGRecord(date: date, duration: 30, samplingFrequency: 256, sampleCount: wave.points.count,
                                       appleBPM: bpm, classification: .sinus, source: L10n.text("合成演示"), isDemo: true,
                                       preview: wave.envelope(to: 6, columns: 180), analysis: analysis)
                records.append(record)
            }
        }
        return records.sorted { $0.date > $1.date }
    }
}
