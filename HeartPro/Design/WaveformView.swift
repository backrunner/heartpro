import SwiftUI
import HeartProCore

struct WaveformCanvas: View {
    var points: [VoltagePoint]
    var range: ClosedRange<Double>
    var peakTimes: [Double] = []
    var gain: Double = 1
    var standard = false
    var markers: [Double] = []
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            let duration = max(0.001, range.upperBound - range.lowerBound)
            let xScale = size.width / duration
            let yScale = standard ? 40.0 * gain : size.height * 0.38 * gain
            let baseline = size.height * 0.58
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(scheme == .dark ? Color(white: 0.115) : Color(red: 1, green: 0.978, blue: 0.976)))
            var fine = Path(), major = Path()
            let smallX = xScale * 0.04
            if smallX >= 1.5 {
                for n in 0...Int(size.width / smallX) {
                    let x = CGFloat(n) * smallX
                    if n.isMultiple(of: 5) { major.move(to: CGPoint(x: x, y: 0)); major.addLine(to: CGPoint(x: x, y: size.height)) }
                    else { fine.move(to: CGPoint(x: x, y: 0)); fine.addLine(to: CGPoint(x: x, y: size.height)) }
                }
            }
            let smallY = yScale * 0.1
            if smallY >= 1 {
                for n in -Int(size.height / smallY)...Int(size.height / smallY) {
                    let y = baseline + CGFloat(n) * smallY
                    guard y >= 0 && y <= size.height else { continue }
                    if n.isMultiple(of: 5) { major.move(to: CGPoint(x: 0, y: y)); major.addLine(to: CGPoint(x: size.width, y: y)) }
                    else { fine.move(to: CGPoint(x: 0, y: y)); fine.addLine(to: CGPoint(x: size.width, y: y)) }
                }
            }
            context.stroke(fine, with: .color(HP.coral.opacity(scheme == .dark ? 0.10 : 0.09)), lineWidth: 0.4)
            context.stroke(major, with: .color(HP.coral.opacity(0.16)), lineWidth: 0.6)
            var path = Path(); var previous: Double?
            for point in points where range.contains(point.time) {
                let location = CGPoint(x: (point.time - range.lowerBound) * xScale, y: baseline - point.millivolts * yScale)
                if let previous, point.time - previous < 0.08 { path.addLine(to: location) } else { path.move(to: location) }
                previous = point.time
            }
            context.stroke(path, with: .color(HP.ecg), style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
            for time in peakTimes where range.contains(time) {
                let x = (time - range.lowerBound) * xScale
                context.fill(Path(ellipseIn: CGRect(x: x - 2, y: 9, width: 4, height: 4)), with: .color(HP.coral))
            }
            for time in markers where range.contains(time) {
                let x = (time - range.lowerBound) * xScale
                var cursor = Path()
                cursor.move(to: CGPoint(x: x, y: 0)); cursor.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(cursor, with: .color(.primary.opacity(0.65)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            if standard {
                for second in Int(ceil(range.lowerBound))...max(Int(ceil(range.lowerBound)), Int(floor(range.upperBound))) where Double(second) < range.upperBound {
                    let x = (Double(second) - range.lowerBound) * xScale
                    context.draw(Text("\(second)s").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary), at: CGPoint(x: x + 4, y: size.height - 9), anchor: .leading)
                }
            }
        }.accessibilityLabel(L10n.text("心电波形，\(Int(range.lowerBound)) 至 \(Int(range.upperBound)) 秒"))
    }
}

/// The axis and trace share the same baseline and voltage scale. It stays fixed while time scrolls.
struct VoltageAxis: View {
    var height: CGFloat
    var pointsPerMillivolt: Double
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text("mV").font(.system(size: 9, weight: .medium)).position(x: 17, y: 7)
            ForEach(-20...20, id: \.self) { tick in
                let value = Double(tick) * (pointsPerMillivolt < 30 ? 1 : 0.5)
                let y = height * 0.58 - value * pointsPerMillivolt
                if y > 20 && y < height - 16 {
                    HStack(spacing: 3) {
                        Text(value.formatted(.number.precision(.fractionLength(1)).locale(L10n.locale))).monospacedDigit()
                        Rectangle().frame(width: 4, height: 0.5)
                    }.font(.system(size: 9)).position(x: 16, y: y)
                }
            }
        }.foregroundStyle(.secondary).frame(width: 36, height: height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.text("电压刻度，单位毫伏，标签间隔 \(pointsPerMillivolt < 30 ? "1" : "0.5") 毫伏"))
            .accessibilityIdentifier("voltageAxis")
    }
}

struct WaveformPreview: View {
    var points: [VoltagePoint]
    var body: some View {
        HStack(spacing: 0) {
            VoltageAxis(height: 112, pointsPerMillivolt: 112 * 0.38)
            WaveformCanvas(points: points, range: 0...6).frame(height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomTrailing) {
                    Text("0–6 s").font(.system(size: 9)).foregroundStyle(.secondary).padding(6)
                }
        }
    }
}

