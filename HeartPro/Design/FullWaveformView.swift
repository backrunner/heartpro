import SwiftUI
import HeartProCore

@MainActor @Observable private final class WaveformViewport {
    var zoom = 1.5
    var showPeaks = false
    var showSegments = true
    var measuring = false
    var firstPoint: VoltagePoint?
    var secondPoint: VoltagePoint?
    var position: Int? = 0
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
    private var lanes: [Int] { viewport.showSegments ? Set(annotations.map { $0.kind.lane }).sorted() : [] }
    private var bandHeight: CGFloat { CGFloat(lanes.count) * 16 }
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
                    VStack(spacing: 0) {
                        if !lanes.isEmpty {
                            WaveformBands(annotations: annotations, lanes: lanes, duration: waveform.duration,
                                          selected: viewport.selection) { select($0) }
                                .frame(width: max(1, waveform.duration * 100 * viewport.zoom), height: bandHeight)
                        }
                        LazyHStack(spacing: 0) {
                            ForEach(0..<tiles, id: \.self) { tile in
                                let start = Double(tile) * tileDuration
                                let end = min(waveform.duration, start + tileDuration)
                                let width = max(0.01, end - start) * 100 * viewport.zoom
                                WaveformCanvas(points: waveform.envelope(from: start, to: end, columns: Int(80 * viewport.zoom)),
                                               range: start...max(start + 0.01, end), peakTimes: viewport.showPeaks ? peakTimes : [],
                                               gain: viewport.zoom, standard: true, markers: markers)
                                    .frame(width: width, height: height).id(tile)
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
                }
                .scrollPosition(id: $viewport.position, anchor: .leading).scrollIndicators(.hidden)
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
                    Button(L10n.text("波形开头"), systemImage: "backward.end") { viewport.position = 0 }
                    Button(L10n.text("波形末尾"), systemImage: "forward.end") { viewport.position = tiles - 1 }
                    Toggle(L10n.text("波段标注"), isOn: $viewport.showSegments)
                    Toggle(L10n.text("研究性 R 峰"), isOn: $viewport.showPeaks)
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                    .accessibilityLabel(L10n.text("波形选项"))
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
                    viewport.position = min(tiles - 1, max(0, Int(time / tileDuration)))
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

private struct WaveformBands: View {
    var annotations: [WaveformAnnotation]
    var lanes: [Int]
    var duration: Double
    var selected: WaveformAnnotation?
    var select: (WaveformAnnotation) -> Void

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let scale = size.width / max(duration, 0.001)
                for span in annotations {
                    guard let range = span.clipped(to: 0...duration), let row = lanes.firstIndex(of: span.kind.lane) else { continue }
                    let x = range.lowerBound * scale, width = (range.upperBound - range.lowerBound) * scale
                    let y = Double(row) * 16
                    let color = HP.coral
                    let rect = CGRect(x: x, y: y + 2, width: max(0.5, width), height: 12)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color.opacity(selected?.id == span.id ? 0.28 : 0.12)))
                    var bracket = Path()
                    bracket.move(to: CGPoint(x: x, y: y + 10)); bracket.addLine(to: CGPoint(x: x, y: y + 14))
                    bracket.addLine(to: CGPoint(x: x + width, y: y + 14)); bracket.addLine(to: CGPoint(x: x + width, y: y + 10))
                    context.stroke(bracket, with: .color(color.opacity(0.7)), lineWidth: 0.8)
                    let label = context.resolve(Text(span.kind.label).font(.system(size: 9, weight: .medium)).foregroundStyle(.primary))
                    if label.measure(in: CGSize(width: 100, height: 12)).width + 2 < width {
                        context.draw(label, at: CGPoint(x: x + width / 2, y: y + 7))
                    }
                }
            }.onTapGesture { point in
                let row = Int(point.y / 16), time = point.x / geometry.size.width * duration
                guard lanes.indices.contains(row), let span = annotations.first(where: {
                    $0.kind.lane == lanes[row] && $0.start <= time && $0.end >= time
                }) else { return }
                select(span)
            }
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(L10n.text("波段标注"))
        .accessibilityValue(selected.map { "\($0.kind.label), \($0.milliseconds.integerText) ms" } ?? "")
        .accessibilityAdjustableAction { direction in
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
