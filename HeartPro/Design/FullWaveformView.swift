import SwiftUI
import HeartProCore

@MainActor @Observable private final class WaveformViewport {
    var zoom = 1.5
    var showPeaks = false
    var showSegments = true
    var measuring = false
    var firstPoint: VoltagePoint?
    var secondPoint: VoltagePoint?
    var position = ScrollPosition(id: 0, anchor: .leading)
    var selection: WaveformAnnotation?
}

struct FullWaveformView: View {
    var waveform: Waveform
    var peakTimes: [Double]
    var segments: SegmentAnalysis?
    @Binding var selectedTime: Double?
    @State private var viewport = WaveformViewport()
    @State private var fullscreen = false

    var body: some View {
        WaveformPlot(waveform: waveform, peakTimes: peakTimes, annotations: segments?.waveformAnnotations ?? [],
                     selectedTime: $selectedTime, viewport: viewport, expand: { fullscreen = true })
            .fullScreenCover(isPresented: $fullscreen) {
                GeometryReader { geometry in
                    WaveformPlot(waveform: waveform, peakTimes: peakTimes, annotations: segments?.waveformAnnotations ?? [],
                                 selectedTime: $selectedTime, viewport: viewport,
                                 availableHeight: max(160, geometry.size.height - 16), close: { fullscreen = false })
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .background(HP.canvas.ignoresSafeArea()).tint(HP.coral)
                .background(WaveformLandscapeRequest().frame(width: 0, height: 0))
                .statusBarHidden().persistentSystemOverlays(.hidden)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fullscreenWaveform")
            }
    }
}

private struct WaveformPlot: View {
    var waveform: Waveform
    var peakTimes: [Double]
    var annotations: [WaveformAnnotation]
    @Binding var selectedTime: Double?
    @Bindable var viewport: WaveformViewport
    var availableHeight: CGFloat?
    var expand: (() -> Void)?
    var close: (() -> Void)?
    @State private var pinchStart: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let tileDuration = 0.5
    private var tiles: Int { max(1, Int(ceil(waveform.duration / tileDuration))) }
    @ScaledMetric(relativeTo: .caption2) private var bandFontSize = 9.0
    private var bandLayout: WaveformBandLayout {
        WaveformBandLayout(annotations: viewport.showSegments ? annotations : [], duration: waveform.duration,
                           pointsPerSecond: 100 * viewport.zoom,
                           font: .systemFont(ofSize: bandFontSize, weight: .medium))
    }
    private var bandHeight: CGFloat { bandLayout.height }
    private var hasReadout: Bool { viewport.measuring || viewport.selection != nil || selectedTime != nil }
    private var height: CGFloat {
        availableHeight.map { max(80, $0 - 100 - bandHeight - (hasReadout ? 30 : 0)) } ?? 148
    }
    private var markers: [Double] {
        [viewport.firstPoint?.time, viewport.secondPoint?.time, viewport.selection?.start,
         viewport.selection?.end, selectedTime].compactMap { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(L10n.text("原始心电图")).font(.subheadline.weight(.semibold))
                Text(L10n.text("\(waveform.duration.integerText) 秒")).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if let expand {
                    Button(action: expand) { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                        .hpCircularIconButton().accessibilityLabel(L10n.text("全屏查看心电图"))
                        .accessibilityIdentifier("expandWaveform")
                }
                if let close {
                    Button(action: close) { Image(systemName: "xmark") }
                        .hpCircularIconButton().accessibilityLabel(L10n.text("退出全屏"))
                        .accessibilityIdentifier("closeFullscreenWaveform")
                }
            }
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: bandHeight)
                    VoltageAxis(height: height, pointsPerMillivolt: 40 * viewport.zoom)
                }.frame(width: 36)
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 0) {
                        if !bandLayout.entries.isEmpty {
                            WaveformBands(layout: bandLayout, selected: viewport.selection) { select($0) }
                                .frame(width: max(1, waveform.duration * 100 * viewport.zoom), height: bandHeight)
                        }
                        // Every tile participates in layout so zoom and rotation
                        // cannot leave off-screen scroll targets at estimated positions.
                        HStack(spacing: 0) {
                            ForEach(0..<tiles, id: \.self) { tile in
                                let start = Double(tile) * tileDuration
                                let end = min(waveform.duration, start + tileDuration)
                                let width = max(0.01, end - start) * 100 * viewport.zoom
                                WaveformCanvas(points: waveform.envelope(from: start, to: end, columns: Int(80 * viewport.zoom)),
                                               range: start...max(start + 0.01, end), peakTimes: viewport.showPeaks ? peakTimes : [],
                                               gain: viewport.zoom, standard: true, markers: markers)
                                    .frame(width: width, height: height).id(tile)
                                    .accessibilityIdentifier("waveformTile-\(tile)")
                                    .onTapGesture { location in
                                        guard viewport.measuring else { return }
                                        let time = start + location.x / (100 * viewport.zoom)
                                        guard let point = nearestPoint(time) else { return }
                                        if viewport.firstPoint == nil || viewport.secondPoint != nil {
                                            viewport.firstPoint = point; viewport.secondPoint = nil
                                        } else { viewport.secondPoint = point }
                                    }
                            }
                        }.scrollTargetLayout()
                    }
                    .frame(width: max(1, waveform.duration * 100 * viewport.zoom), alignment: .leading)
                }
                .scrollPosition($viewport.position, anchor: .leading).scrollIndicators(.hidden)
                .clipShape(RoundedRectangle(cornerRadius: 8)).accessibilityIdentifier("fullWaveform")
                .simultaneousGesture(MagnifyGesture().onChanged { value in
                    if pinchStart == nil { pinchStart = viewport.zoom }
                    viewport.zoom = min(6, max(0.5, (pinchStart ?? 1.5) * value.magnification))
                }.onEnded { _ in pinchStart = nil })
            }.frame(height: bandHeight + height)
            HStack(spacing: 0) {
                Button { viewport.zoom = max(0.5, viewport.zoom / 1.5) } label: {
                    Image(systemName: "minus.magnifyingglass").frame(width: 44, height: 44)
                }.accessibilityLabel(L10n.text("缩小波形"))
                Text("\(viewport.zoom, specifier: "%.1f")×").font(.caption.monospacedDigit())
                    .lineLimit(1).fixedSize().frame(minWidth: 38)
                    .accessibilityIdentifier("waveformZoom")
                Button { viewport.zoom = min(6, viewport.zoom * 1.5) } label: {
                    Image(systemName: "plus.magnifyingglass").frame(width: 44, height: 44)
                }.accessibilityLabel(L10n.text("放大波形"))
                Spacer(minLength: 0)
                Button {
                    viewport.measuring.toggle(); viewport.firstPoint = nil; viewport.secondPoint = nil
                    viewport.selection = nil
                } label: { Image(systemName: "ruler").frame(width: 44, height: 44) }
                    .foregroundStyle(viewport.measuring ? HP.coral : .secondary)
                    .accessibilityLabel(L10n.text("双点测量")).accessibilityIdentifier("measureWaveform")
                Menu {
                    Button(L10n.text("波形开头"), systemImage: "backward.end") { viewport.position.scrollTo(edge: .leading) }
                        .accessibilityIdentifier("jumpToWaveformStart")
                    Button(L10n.text("波形末尾"), systemImage: "forward.end") { viewport.position.scrollTo(edge: .trailing) }
                        .accessibilityIdentifier("jumpToWaveformEnd")
                    Toggle(L10n.text("波段标注"), isOn: $viewport.showSegments)
                    Toggle(L10n.text("研究性 R 峰"), isOn: $viewport.showPeaks)
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                    .accessibilityLabel(L10n.text("波形选项"))
                    .accessibilityIdentifier("waveformOptions")
            }.font(.body).buttonStyle(.plain)
            if hasReadout {
                HStack(spacing: 8) {
                    readout.font(.caption.monospacedDigit())
                    Spacer(minLength: 0)
                    if !viewport.measuring {
                        Button(L10n.text("清除")) { selectedTime = nil; viewport.selection = nil }.font(.caption)
                    }
                }
            }
        }
        .onChange(of: selectedTime) { _, time in
            if let time {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    viewport.position.scrollTo(id: min(tiles - 1, max(0, Int(time / tileDuration))), anchor: .leading)
                }
            }
        }
    }

    @ViewBuilder private var readout: some View {
        if viewport.measuring {
            if let first = viewport.firstPoint, let second = viewport.secondPoint {
                Text("Δt \(abs(second.time - first.time) * 1000, specifier: "%.0f") ms · ΔV \(second.millivolts - first.millivolts, specifier: "%.2f") mV")
                    .accessibilityIdentifier("measurementResult")
            } else { Text(viewport.firstPoint == nil ? L10n.text("依次轻点波形上的两个位置") : L10n.text("再轻点一个位置完成测量")) }
        } else if let selection = viewport.selection {
            Text("\(selection.kind.label) · \(selection.milliseconds.integerText) ms")
                .accessibilityIdentifier("waveformBandMeasurement")
        } else if let selectedTime {
            Text(L10n.text("定位 \(selectedTime, specifier: "%.2f") s"))
        }
    }
    private func select(_ span: WaveformAnnotation) {
        viewport.selection = span; viewport.measuring = false
        viewport.firstPoint = nil; viewport.secondPoint = nil
        selectedTime = span.start
    }
    private func nearestPoint(_ time: Double) -> VoltagePoint? {
        guard !waveform.points.isEmpty else { return nil }
        var a = 0, b = waveform.points.count
        while a < b { let middle = (a + b) / 2; if waveform.points[middle].time < time { a = middle + 1 } else { b = middle } }
        let i = min(a, waveform.points.count - 1)
        return i > 0 && abs(waveform.points[i - 1].time - time) < abs(waveform.points[i].time - time)
            ? waveform.points[i - 1] : waveform.points[i]
    }
}

/// Label widths are independent of measured spans. Extra rows resolve label
/// collisions at small zoom levels without widening or moving the time brackets.
@MainActor struct WaveformBandLayout {
    struct Entry {
        var span: WaveformAnnotation
        var band: CGRect
        var label: CGRect
    }
    var entries: [Entry] = []
    var height: CGFloat = 0
    var font: UIFont

    init(annotations: [WaveformAnnotation], duration: Double, pointsPerSecond: CGFloat, font: UIFont) {
        self.font = font
        let contentWidth = max(1, duration * pointsPerSecond)
        let rowHeight = max(16, ceil(font.lineHeight) + 4)
        for lane in Set(annotations.map { $0.kind.lane }).sorted() {
            var rowEnds: [CGFloat] = []
            var pending: [(WaveformAnnotation, CGRect, CGFloat, Int)] = []
            for span in annotations.filter({ $0.kind.lane == lane }).sorted(by: { $0.start < $1.start }) {
                guard let range = span.clipped(to: 0...duration) else { continue }
                let x = range.lowerBound * pointsPerSecond
                let width = (range.upperBound - range.lowerBound) * pointsPerSecond
                let labelWidth = ceil((span.kind.label as NSString).size(withAttributes: [.font: font]).width) + 2
                let labelX = max(0, min(contentWidth - labelWidth, x + width / 2 - labelWidth / 2))
                let row = rowEnds.firstIndex(where: { $0 + 3 <= labelX }) ?? rowEnds.count
                if row == rowEnds.count { rowEnds.append(labelX + labelWidth) }
                else { rowEnds[row] = labelX + labelWidth }
                pending.append((span, CGRect(x: labelX, y: 0, width: labelWidth, height: ceil(font.lineHeight)), width, row))
            }
            let bandY = height + CGFloat(max(0, rowEnds.count - 1)) * rowHeight + 2
            for (span, label, width, row) in pending {
                let band = CGRect(x: max(0, span.start) * pointsPerSecond, y: bandY,
                                  width: width, height: rowHeight - 4)
                entries.append(Entry(span: span, band: band,
                    label: CGRect(x: label.minX, y: band.midY - CGFloat(row) * rowHeight - label.height / 2,
                                  width: label.width, height: label.height)))
            }
            height += CGFloat(rowEnds.count) * rowHeight
        }
    }

    func annotation(at point: CGPoint) -> WaveformAnnotation? {
        entries.first { $0.label.contains(point) }?.span ?? entries.first { $0.band.contains(point) }?.span
    }
}

private struct WaveformBands: View {
    var layout: WaveformBandLayout
    var selected: WaveformAnnotation?
    var select: (WaveformAnnotation) -> Void

    var body: some View {
        Canvas { context, _ in
            for entry in layout.entries {
                let rect = entry.band
                let color = HP.coral
                context.fill(Path(roundedRect: rect, cornerRadius: 2),
                             with: .color(color.opacity(selected?.id == entry.span.id ? 0.28 : 0.12)))
                var bracket = Path()
                bracket.move(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
                bracket.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                bracket.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                bracket.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
                if entry.label.maxY < rect.minY {
                    bracket.move(to: CGPoint(x: entry.label.midX, y: entry.label.maxY + 1))
                    bracket.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
                }
                context.stroke(bracket, with: .color(color.opacity(0.7)), lineWidth: 0.8)
            }
            // Paint text last so a neighbouring range never covers a narrow wave's label.
            for entry in layout.entries {
                let label = context.resolve(Text(entry.span.kind.label).font(Font(layout.font)).foregroundStyle(.primary))
                context.draw(label, at: CGPoint(x: entry.label.midX, y: entry.label.midY))
            }
        }
        .onTapGesture { point in
            if let span = layout.annotation(at: point) { select(span) }
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(L10n.text("波段标注"))
        .accessibilityValue(selected.map { "\($0.kind.label), \($0.milliseconds.integerText) ms" } ?? "")
        .accessibilityAdjustableAction { direction in
            let annotations = layout.entries.map(\.span)
            let index = selected.flatMap { choice in annotations.firstIndex { $0.id == choice.id } }
            let next = direction == .increment ? min(annotations.count - 1, (index ?? -1) + 1) : max(0, (index ?? 1) - 1)
            if annotations.indices.contains(next) { select(annotations[next]) }
        }
        .accessibilityIdentifier("waveformAnnotations")
    }
}

/// Use the scene attached to this presentation, not a global window or private
/// device-rotation API. A denied request leaves the responsive full-screen view usable.
private struct WaveformLandscapeRequest: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ uiViewController: Controller, context: Context) {}
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController {
        private weak var scene: UIWindowScene?
        private var previous: UIInterfaceOrientationMask?
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard previous == nil, let scene = view.window?.windowScene else { return }
            self.scene = scene
            switch scene.interfaceOrientation {
            case .portrait: previous = .portrait
            case .portraitUpsideDown: previous = .portraitUpsideDown
            case .landscapeLeft: previous = .landscapeLeft
            case .landscapeRight: previous = .landscapeRight
            default: previous = .allButUpsideDown
            }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        func restore() {
            guard let previous else { return }
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: previous))
            self.previous = nil
        }
    }
}
