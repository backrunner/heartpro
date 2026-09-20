import SwiftUI
import Charts
import HeartProCore

struct ECGDetailView: View {
    @Environment(AppModel.self) private var model
    @State private var record: ECGRecord
    @State private var waveform: Waveform?
    @State private var loadingError: String?
    @State private var selectedTime: Double?
    @State private var showNote = false
    @State private var editingNote: JournalNote?
    @State private var report: URL?
    @State private var exporting = false
    @ScaledMetric(relativeTo: .title2) private var overviewColumnWidth = 135.0
    private var notes: [JournalNote] { model.notes.filter { $0.recordID == record.id } }
    private var heartRateRange: String {
        guard let minimum = record.analysis?.minimumBPM,
              let maximum = record.analysis?.maximumBPM,
              minimum.isFinite, maximum.isFinite, minimum > 0, maximum >= minimum else { return "—" }
        return "\(minimum.integerText)–\(maximum.integerText)"
    }

    init(record: ECGRecord) { _record = State(initialValue: record) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(record.date.formatted(.dateTime.month(.wide).day().hour().minute().locale(L10n.locale))).font(.title2.weight(.bold))
                            Spacer()
                            if record.isDemo { Tag(text: L10n.text("合成示例"), color: HP.coral) }
                        }
                    }
                    Surface(padding: 12) {
                        if let waveform { FullWaveformView(waveform: waveform, peakTimes: record.analysis?.peakTimes ?? [], segments: record.analysis?.segments, selectedTime: $selectedTime) }
                        else if let loadingError {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(L10n.text("波形暂不可用"), systemImage: "waveform.path.ecg").font(.headline)
                                Text(AnalysisText.readable(loadingError)).font(.caption).foregroundStyle(.secondary)
                                Button(L10n.text("重新读取")) { Task { await loadWaveform() } }
                            }
                        } else { ProgressView(L10n.text("正在读取完整心电图…")).frame(maxWidth: .infinity).frame(height: 220) }
                    }.id("waveform")
                    overview
                    noteSection
                    if let assessment = record.rhythmAssessment {
                        EctopyPanel(assessment: assessment) { time in
                            selectedTime = time
                            withAnimation { proxy.scrollTo("waveform", anchor: .top) }
                        }
                    }
                    if let analysis = record.analysis {
                        if analysis.qualityFraction < 0.8 { quality(analysis) }
                        rhythm(analysis)
                        if let review = analysis.review { MorphologyPanel(review: review) }
                    }
                    SegmentAnalysisPanel(analysis: record.analysis?.segments, waveform: waveform) { time in
                        selectedTime = time
                        withAnimation { proxy.scrollTo("waveform", anchor: .top) }
                    }
                    hrv
                    if let analysis = record.analysis, !(analysis.review?.events.isEmpty ?? true) || !analysis.outliers.isEmpty {
                        outliers(analysis) { time in
                            selectedTime = time
                            withAnimation { proxy.scrollTo("waveform", anchor: .top) }
                        }
                    }
                    capability
                    ReferenceFooter()
                }.padding(14).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(AppBackground())
        }
        .navigationTitle(L10n.text("心电详情")).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNote = true } label: { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel(L10n.text("添加备忘")).accessibilityIdentifier("addNote")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let report { ShareLink(item: report) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel(L10n.text("分享心电报告")) }
                else {
                    Button { export() } label: { if exporting { ProgressView() } else { Image(systemName: "square.and.arrow.up") } }
                        .disabled(waveform == nil || exporting).accessibilityLabel(L10n.text("生成心电 PDF"))
                }
            }
        }
        .task(id: model.isSyncing) {
            do { record = try await model.detailedRecord(record) }
            catch { loadingError = error.localizedDescription }
            if waveform == nil { await loadWaveform() }
        }
        .sheet(isPresented: $showNote) { NavigationStack { NoteEditor(recordID: record.id, date: record.date) } }
        .sheet(item: $editingNote) { note in NavigationStack { NoteEditor(recordID: record.id, date: note.date, existing: note) } }
        .onChange(of: model.notes) { _, _ in report = nil }
        .toolbar(.hidden, for: .tabBar)
        .disclosureGroupStyle(AnalysisDisclosureStyle())
    }

    private var overview: some View {
        Surface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.classification.title).font(.headline)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: overviewColumnWidth), alignment: .leading)], alignment: .leading, spacing: 18) {
                    MetricValue(value: record.bpm?.integerText ?? "—", unit: "bpm", label: L10n.text("平均心率"))
                    MetricValue(value: heartRateRange, unit: "bpm", label: L10n.text("本次心率范围"))
                }
                if let failure = record.failure {
                    Text(AnalysisText.readable(failure)).font(.caption).foregroundStyle(.secondary)
                    Button(L10n.text("重新分析")) { Task { await model.retry(record) } }.disabled(model.isSyncing)
                }
            }
        }
    }

    private func quality(_ analysis: ECGAnalysis) -> some View {
        AnalysisSurface {
            VStack(alignment: .leading, spacing: 15) {
                HStack { Label(L10n.text("可用于分析的时长"), systemImage: "waveform").font(.headline); Spacer(); Text("\((analysis.qualityFraction * 100).integerText)%").font(.system(.title3, design: .rounded, weight: .semibold)).foregroundStyle(HP.teal) }
                GeometryReader { geometry in
                    HStack(spacing: 3) {
                        ForEach(Array(analysis.windows.enumerated()), id: \.offset) { _, window in
                            Capsule().fill(window.usable ? HP.teal.opacity(0.65) : HP.amber.opacity(0.5))
                                .frame(width: max(1, (geometry.size.width - Double(max(0, analysis.windows.count - 1)) * 3) * (window.end - window.start) / max(analysis.duration, 1)))
                        }
                    }
                }.frame(height: 7)
                HStack { Text(L10n.text("0 秒")); Spacer(); Text(L10n.text("\(analysis.duration.integerText) 秒")) }.font(.caption2).foregroundStyle(.secondary)
                Text(analysis.displayReason ?? "").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func rhythm(_ analysis: ECGAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: L10n.text("心率与节律"), subtitle: L10n.text("RR 间期"))
            AnalysisSurface {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { MetricValue(value: Statistics.median(analysis.intervals.map(\.milliseconds))?.integerText ?? "—", unit: "ms", label: L10n.text("RR 中位数")); MetricValue(value: "\(analysis.intervals.count)", unit: L10n.text("个"), label: L10n.text("测得的 RR 间隔")) }
                    if !analysis.intervals.isEmpty {
                        Chart(analysis.intervals) { interval in
                            PointMark(x: .value(L10n.text("时间"), interval.time), y: .value("RR", interval.milliseconds))
                                .foregroundStyle(interval.isOutlier ? HP.amber : HP.teal).symbolSize(interval.isOutlier ? 36 : 16)
                        }.frame(height: 150).chartXAxisLabel(L10n.text("时间（秒）")).chartYAxisLabel("ms")
                    }
                }
            }
        }
    }

    private var hrv: some View {
        RRVariabilityPanel(analysis: record.analysis, classification: record.classification)
    }

    private func outliers(_ analysis: ECGAnalysis, select: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: L10n.text("可以回看的变化"), subtitle: L10n.text("点击查看原图"))
            AnalysisSurface {
                VStack(alignment: .leading, spacing: 14) {
                    if let review = analysis.review, !review.events.isEmpty {
                        ForEach(review.events) { item in
                            Button { select(item.time) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack { Text(item.kind.title); Spacer(); Text("\(item.time, specifier: "%.2f") s"); Image(systemName: "arrow.up.right") }.font(.subheadline)
                                    Text(item.displayDetail).font(.caption).foregroundStyle(.secondary)
                                }.padding(.vertical, 6)
                            }.buttonStyle(.plain)
                        }
                    } else if analysis.intervals.count < 12 {
                        Text(L10n.text("目前测得的心跳间隔少于 12 个，还不够比较哪些变化更突出。")).font(.subheadline)
                    } else if analysis.outliers.isEmpty {
                        Label(L10n.text("没有标出与多数心跳明显不同的片段"), systemImage: "circle.dotted").font(.subheadline.weight(.medium))
                    } else {
                        ForEach(analysis.outliers) { item in
                            Button { select(item.time) } label: {
                                HStack { Label(L10n.text("\(item.time, specifier: "%.2f") 秒"), systemImage: "scope"); Spacer(); Text("RR \(item.milliseconds.integerText) ms"); Image(systemName: "arrow.up.right") }.font(.subheadline)
                            }.padding(.vertical, 5)
                        }
                    }
                }
            }
        }
    }

    private var capability: some View {
        AnalysisSurface(padding: 0) {
            DisclosureGroup(L10n.text("分析方法与限制")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("应用会估算波峰位置、心跳间隔和波形变化，并标出值得回看的片段。它还不能确定早搏类型，也不能诊断房颤等疾病。"))
                    Text(L10n.text("Apple Watch 只有一个观察心脏电活动的角度，也就是单导联，不能可靠识别或排除心梗、心肌缺血。自动测量尚未经过真实 Watch 数据的准确度验证，不用于判断心电是否正常。"))
                    Text(L10n.text("分析版本：\(record.analysis?.version ?? L10n.text("未分析"))"))
                }.font(.caption).foregroundStyle(.secondary).padding(.top, 12)
            }.font(.subheadline.weight(.semibold))
                .disclosureGroupStyle(AnalysisDisclosureStyle(inset: 18))
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { SectionHeading(title: L10n.text("本次备忘"), subtitle: notes.isEmpty ? nil : L10n.text("\(notes.count) 条")); Button(L10n.text("添加")) { showNote = true }.font(.subheadline) }
            if notes.isEmpty {
                Button { showNote = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.pencil").font(.title2)
                        Text(L10n.text("添加症状或测量背景")).font(.subheadline.weight(.semibold))
                        Spacer(); Image(systemName: "plus")
                    }.padding(14).frame(maxWidth: 760).frame(maxWidth: .infinity).hpGlass(tint: HP.coral.opacity(0.03), interactive: true)
                }.buttonStyle(.plain)
            } else {
                ForEach(notes) { note in
                    Button { editingNote = note } label: { NoteCard(note: note) }.buttonStyle(.plain)
                        .accessibilityIdentifier("editNote-\(note.id)")
                }
            }
        }
    }

    private func loadWaveform() async {
        loadingError = nil
        do {
            let wave = try await model.waveform(for: record)
            waveform = wave
            if record.analysis?.version != ECGAnalysis.currentVersion {
                let result = try await Task.detached(priority: .userInitiated) { try SignalAnalyzer.analyze(wave) }.value
                record.analysis = result; record.failure = nil; report = nil
                if !record.isDemo { try await model.repository.complete(record.id, waveform: wave, analysis: result) }
            }
        }
        catch { loadingError = error.localizedDescription }
    }
    private func export() {
        guard let waveform else { return }
        exporting = true
        do { report = try ReportExporter.make(record: record, waveform: waveform, notes: notes) }
        catch { model.errorMessage = error.localizedDescription }
        exporting = false
    }
}
