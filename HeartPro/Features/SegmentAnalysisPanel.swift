import SwiftUI
import Charts
import HeartProCore

struct SegmentAnalysisPanel: View {
    var analysis: SegmentAnalysis?
    var waveform: Waveform?
    var selectTime: (Double) -> Void
    @State private var selection: SegmentSelection?
    @State private var pendingTime: Double?
    @State private var expandedSegment: ECGSegment?
    @State private var showHelp = false
    private var segments: [ECGSegment] { analysis?.visibleSegments ?? ECGSegment.supportedCases }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(title: L10n.text("心电分段分析"))
                Spacer()
                AnalysisInfoButton(title: L10n.text("了解分段测量")) { showHelp = true }
            }
            if let reason = analysis?.displayUnavailableReason {
                Text(reason).font(.subheadline).foregroundStyle(.secondary)
            }
            AnalysisSurface(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(segments) { segment in
                        SegmentCard(segment: segment, analysis: analysis, expanded: Binding(
                            get: { expandedSegment == segment },
                            set: { expandedSegment = $0 ? segment : nil }
                        )) { beat in
                            selection = SegmentSelection(segment: segment, beatID: beat.id)
                        }
                        if segment != segments.last { Divider().padding(.horizontal, 18) }
                    }
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            AnalysisHelpSheet(title: L10n.text("了解分段测量")) {
                Text(SegmentAnalysis.method)
                Text(L10n.text("这些数字怎么看")).font(.headline)
                Text(SegmentAnalysis.readingGuide)
                if let analysis {
                    Text(L10n.text("这条记录大约每 \(1000 / analysis.samplingFrequency, specifier: "%.1f") ms 采样一次。采样间隔不等于测量误差。"))
                }
                Text(L10n.text("参考范围用于帮助理解，不能直接套用来判断手表心电是否正常。没有测量结果，也不代表这段波形不存在。"))
                Link(L10n.text("阅读 MSD 的心电图介绍"), destination: URL(string: "https://www.msdmanuals.com/professional/cardiovascular-disorders/cardiovascular-tests-and-procedures/electrocardiography")!)
            }
        }
        .sheet(item: $selection, onDismiss: {
            if let time = pendingTime { pendingTime = nil; selectTime(time) }
        }) { item in
            if let analysis {
                NavigationStack {
                    SegmentBeatDetail(segment: item.segment, analysis: analysis, waveform: waveform, initialBeatID: item.beatID) { time in
                        pendingTime = time
                        selection = nil
                    }
                }
            }
        }
    }
}

private struct SegmentSelection: Identifiable {
    let segment: ECGSegment
    let beatID: Int
    var id: String { "\(segment.rawValue)-\(beatID)" }
}

private struct SegmentCard: View {
    let segment: ECGSegment
    let analysis: SegmentAnalysis?
    @Binding var expanded: Bool
    let select: (SegmentBeat) -> Void
    @State private var selectedMetric: SegmentMetric?
    private var metric: SegmentMetric { selectedMetric ?? segment.metrics[0] }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Surface(padding: 16) { details }
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    summaryTitle.fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 4)
                    summaryValue.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 8) { summaryTitle; summaryValue }
            }
        }
        .disclosureGroupStyle(AnalysisDisclosureStyle(identifier: "segment-\(segment.rawValue)", inset: 18))
    }

    private var summaryTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(segment.title).font(.subheadline.weight(.semibold))
            if let stat = analysis?.statistics(segment.metrics[0]), stat.count > 0 {
                Text(L10n.text("基于 \(stat.count) 次清晰测量")).font(.caption).foregroundStyle(.secondary)
            } else {
                Text(analysis == nil ? L10n.text("等待分析") : L10n.text("展开查看原因"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var summaryValue: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if let stat = analysis?.statistics(segment.metrics[0]), let median = stat.median {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(stat.metric.format(median)).font(.system(.title3, design: .rounded, weight: .medium)).monospacedDigit()
                    Text(stat.metric.unit).font(.caption).foregroundStyle(.secondary)
                }
                Text(segment == .qtc ? L10n.text("Fridericia 中位数") : L10n.text("中位数")).font(.caption2).foregroundStyle(.secondary)
            } else { Text("—").font(.title3).foregroundStyle(.secondary) }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 18) {
            let reference = segment.adultReference
            let median = analysis?.statistics(segment.metrics[0]).median
            VStack(alignment: .leading, spacing: 8) {
                Label(reference.range, systemImage: "ruler").font(.subheadline.weight(.medium))
                if let median {
                    if reference.position(median) == .above || reference.position(median) == .below {
                        Text(L10n.text("本次中位数偏离参考范围")).font(.caption.weight(.semibold)).foregroundStyle(HP.amber)
                    }
                }
                Text(reference.explanation(median)).font(.caption).foregroundStyle(.secondary)
            }.padding(12).background(HP.teal.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("segmentReference-\(segment.rawValue)")
            if let analysis {
                VStack(spacing: 12) {
                    ForEach(segment.metrics) { item in
                        let stat = analysis.statistics(item)
                        if stat.count > 0 || item == segment.metrics.first { statistic(stat) }
                    }
                }
                if !analysis.beats.isEmpty {
                    if segment.metrics.count > 1 {
                        Menu {
                            Picker(L10n.text("图表指标"), selection: Binding(get: { metric }, set: { selectedMetric = $0 })) {
                                ForEach(segment.metrics) { Text($0.title).tag($0) }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(metric.title).foregroundStyle(.primary)
                                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(HP.caret)
                            }.font(.subheadline)
                        }.menuIndicator(.hidden).hpGlassButton().tint(.primary)
                            .accessibilityIdentifier("segmentMetric-\(segment.rawValue)")
                            .accessibilityValue(metric.title)
                    }
                    if analysis.statistics(metric).count > 0 {
                        Chart(analysis.beats) { beat in
                            if let value = beat.observation(segment)?.value(metric)?.value {
                                PointMark(x: .value(L10n.text("时间"), beat.rTime), y: .value(metric.title, value))
                                    .foregroundStyle(HP.teal).symbolSize(20)
                            }
                        }.frame(height: 140).chartXAxisLabel(L10n.text("记录时间（秒）")).chartYAxisLabel(metric.unit)
                            .accessibilityLabel(L10n.text("每次心跳的\(metric.title)，无法测量的位置留空"))
                    }
                    Button {
                        if let beat = analysis.beats.first(where: { $0.observation(segment)?.hasMeasurement == true }) ?? analysis.beats.first {
                            select(beat)
                        }
                    } label: {
                        Label(L10n.text("查看每次心跳"), systemImage: "waveform.path.ecg")
                            .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity)
                    }.hpGlassButton().tint(.primary).accessibilityIdentifier("segmentBeats-\(segment.rawValue)")
                }
                let reasons = analysis.missingReasons(segment)
                if !reasons.isEmpty {
                    DisclosureGroup(L10n.text("为什么暂时无法测量")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(reasons, id: \.self) { Text($0) }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                }
                DisclosureGroup(L10n.text("分布与波形细节")) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(segment.metrics) { item in
                            let stat = analysis.statistics(item)
                            if let p10 = stat.p10, let p90 = stat.p90 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).fontWeight(.medium)
                                    Text(L10n.text("中间 80% 范围 \(item.format(p10))–\(item.format(p90)) \(item.unit)"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        let morphologies = Dictionary(grouping: analysis.beats.compactMap { $0.observation(segment)?.displayMorphology }, by: { $0 })
                        ForEach(morphologies.keys.sorted(), id: \.self) { text in
                            LabeledContent(text, value: L10n.text("\(morphologies[text]?.count ?? 0) 次"))
                        }
                    }.font(.caption)
                }
            }
            DisclosureGroup(L10n.text("如何理解与测量")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(segment.explanation)
                    Text(segment.reference)
                    Text(segment.measurementDetails)
                }.font(.caption).foregroundStyle(.secondary)
            }
        }.font(.subheadline).disclosureGroupStyle(AnalysisDisclosureStyle())
    }

    private func statistic(_ stat: SegmentStatistic) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(stat.metric.title).fixedSize(); Spacer()
                    Text(stat.median.map { "\(stat.metric.format($0)) \(stat.metric.unit)" } ?? L10n.text("暂时无法测量")).monospacedDigit().fixedSize()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.metric.title)
                    Text(stat.median.map { "\(stat.metric.format($0)) \(stat.metric.unit)" } ?? L10n.text("暂时无法测量")).monospacedDigit()
                }
            }.font(.subheadline.weight(.medium))
            if let low = stat.minimum, let high = stat.maximum {
                Text(L10n.text("本次测量范围 \(stat.metric.format(low))–\(stat.metric.format(high)) \(stat.metric.unit)"))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
    }
}

private struct SegmentBeatDetail: View {
    let segment: ECGSegment
    let analysis: SegmentAnalysis
    let waveform: Waveform?
    let selectTime: (Double) -> Void
    @State private var beatID: Int
    @Environment(\.dismiss) private var dismiss
    init(segment: ECGSegment, analysis: SegmentAnalysis, waveform: Waveform?, initialBeatID: Int, selectTime: @escaping (Double) -> Void) {
        self.segment = segment; self.analysis = analysis; self.waveform = waveform; self.selectTime = selectTime
        _beatID = State(initialValue: initialBeatID)
    }
    private var beat: SegmentBeat? { analysis.beats.first { $0.id == beatID } }
    var body: some View {
        ScrollView {
            if let beat, let observation = beat.observation(segment) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button { beatID -= 1 } label: { Image(systemName: "chevron.left").foregroundStyle(HP.caret) }.hpCircularIconButton().disabled(beatID == analysis.beats.first?.id).accessibilityLabel(L10n.text("上一次心跳")).accessibilityIdentifier("previousBeat")
                        Spacer()
                        Menu {
                            Picker(L10n.text("选择心跳"), selection: $beatID) {
                                ForEach(analysis.beats) { item in
                                    Text(L10n.text("第 \(item.id + 1) 次心跳（\(item.rTime, specifier: "%.2f") 秒）")).tag(item.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                VStack(spacing: 3) {
                                    Text(L10n.text("第 \(beat.id + 1)/\(analysis.beats.count) 次")).foregroundStyle(.primary)
                                    Text(L10n.text("\(beat.rTime, specifier: "%.2f") 秒")).font(.caption).foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.down").font(.caption).foregroundStyle(HP.caret)
                            }.font(.subheadline.monospacedDigit())
                        }.menuIndicator(.hidden).accessibilityLabel(L10n.text("选择心跳"))
                            .accessibilityValue(L10n.text("第 \(beat.id + 1)/\(analysis.beats.count) 次"))
                        Spacer()
                        Button { beatID += 1 } label: { Image(systemName: "chevron.right").foregroundStyle(HP.caret) }.hpCircularIconButton().disabled(beatID == analysis.beats.last?.id).accessibilityLabel(L10n.text("下一次心跳")).accessibilityIdentifier("nextBeat")
                    }.hpGlassButton().tint(.primary)
                    if let waveform {
                        let start = max(0, min(beat.rTime - 0.44, observation.start ?? beat.rTime))
                        let end = min(waveform.duration, max(beat.rTime + 0.60, observation.end ?? beat.rTime))
                        let runs = traceRuns(waveform, from: start, to: end)
                        Chart {
                            if let a = observation.start, let b = observation.end {
                                RectangleMark(xStart: .value(L10n.text("起点"), a), xEnd: .value(L10n.text("终点"), b))
                                    .foregroundStyle(HP.teal.opacity(0.1))
                            }
                            ForEach(runs) { run in
                                ForEach(run.points, id: \.time) { point in
                                    LineMark(x: .value(L10n.text("时间"), point.time), y: .value(L10n.text("电压"), point.millivolts), series: .value(L10n.text("连续片段"), run.id))
                                        .foregroundStyle(HP.ecg).lineStyle(StrokeStyle(lineWidth: 1.3))
                                }
                            }
                            if let a = observation.start {
                                RuleMark(x: .value(L10n.text("起点"), a)).foregroundStyle(HP.teal).lineStyle(StrokeStyle(dash: [4, 3]))
                                    .annotation(position: .top, alignment: .trailing) { Text(L10n.text("起")).font(.caption2) }
                            }
                            if let b = observation.end {
                                RuleMark(x: .value(L10n.text("终点"), b)).foregroundStyle(HP.teal).lineStyle(StrokeStyle(dash: [4, 3]))
                                    .annotation(position: .top, alignment: .leading) { Text(L10n.text("终")).font(.caption2) }
                            }
                        }.chartLegend(.hidden).chartXScale(domain: start...max(start + 0.01, end)).chartXAxisLabel(L10n.text("记录时间（秒）"))
                            .chartYAxisLabel("mV", position: .trailing, alignment: .center)
                            .frame(height: 230).accessibilityIdentifier("segmentBeatWaveform")
                    }
                    if let start = observation.start { LabeledContent(L10n.text("开始时间"), value: String(format: "%.3f s", locale: L10n.locale, start)) }
                    if let end = observation.end { LabeledContent(L10n.text("结束时间"), value: String(format: "%.3f s", locale: L10n.locale, end)) }
                    if let peak = observation.peak { LabeledContent(L10n.text("波峰时间"), value: String(format: "%.3f s", locale: L10n.locale, peak)) }
                    if let morphology = observation.displayMorphology { Text(morphology).font(.subheadline) }
                    ForEach(observation.values) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            LabeledContent(item.metric.title, value: item.value.map { "\(item.metric.format($0)) \(item.metric.unit)" } ?? L10n.text("暂时无法测量"))
                            if let reason = item.displayReason { Text(reason).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    Button(L10n.text("在完整心电图中查看"), systemImage: "scope") { selectTime(observation.start ?? beat.rTime) }
                        .hpGlassButton().tint(.primary).accessibilityIdentifier("locateSegmentBeat")
                    Text(segment.explanation).font(.caption).foregroundStyle(.secondary)
                    DisclosureGroup(L10n.text("测量方法")) {
                        Text(segment.measurementDetails).font(.caption).foregroundStyle(.secondary).padding(.top, 8)
                    }.font(.subheadline)
                    ReferenceFooter()
                }.padding(20)
            }
        }.background(AppBackground()).navigationTitle(segment.title).navigationBarTitleDisplayMode(.inline)
            .disclosureGroupStyle(AnalysisDisclosureStyle())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("完成")) { dismiss() } } }
    }
    private struct TraceRun: Identifiable { var id: Int; var points: [VoltagePoint] }
    private func traceRuns(_ waveform: Waveform, from start: Double, to end: Double) -> [TraceRun] {
        var runs: [TraceRun] = []
        for point in waveform.points where point.time >= start && point.time <= end {
            if let previous = runs.last?.points.last, point.time - previous.time <= 1.8 / waveform.samplingFrequency {
                runs[runs.count - 1].points.append(point)
            } else { runs.append(TraceRun(id: runs.count, points: [point])) }
        }
        return runs
    }
}
