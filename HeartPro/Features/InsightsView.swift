import SwiftUI
import Charts
import HeartProCore
import UIKit

private extension HeartHealthTrendRange {
    var title: String { switch self { case .day: L10n.text("日"); case .week: L10n.text("周"); case .month: L10n.text("月") } }
    var aggregationTitle: String { switch self { case .day: L10n.text("按日汇总"); case .week: L10n.text("按周汇总"); case .month: L10n.text("按月汇总") } }
}
private enum TrendMetric: String, CaseIterable { case bpm, hrv
    var title: String { switch self { case .bpm: L10n.text("日常心率"); case .hrv: L10n.text("健康 SDNN") } }
    var unit: String { switch self { case .bpm: "bpm"; case .hrv: "ms" } }
}

/// Reject vertical pans before recognition so the scroll view keeps them. Once a
/// horizontal pan wins, cancel child control taps (especially ECG navigation).
private struct InsightsPeriodSwipe: UIGestureRecognizerRepresentable {
    var shift: (Int) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) { }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard recognizer.state == .ended else { return }
        let translation = recognizer.translation(in: recognizer.view)
        guard abs(translation.x) > 70, abs(translation.x) > abs(translation.y) * 1.5 else { return }
        shift(translation.x < 0 ? 1 : -1)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * 1.5
        }
    }
}

struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @State private var section: Int
    @State private var date = Date.now
    @State private var range: HeartHealthTrendRange = .day
    @State private var pendingHRVScroll: Bool
    @State private var dailyRecords: [ECGRecord] = []
    @State private var dailyHealth = HeartHealthSnapshot()
    @State private var loadingHealth = false
    @State private var healthError: String?
    @State private var showCalendar = false
    @State private var selectedDates: [TrendMetric: Date] = [:]
    @State private var healthSnapshot = HeartHealthSnapshot()
    @State private var heartRatePoints: [HeartHealthTrendPoint] = []
    @State private var hrvPoints: [HeartHealthTrendPoint] = []
    @State private var loadGeneration = 0

    init(initialSection: Int, showHRV: Bool = false) {
        _section = State(initialValue: initialSection)
        _pendingHRVScroll = State(initialValue: showHRV)
    }
    init(initialSection: Int, date: Date, showHRV: Bool = false) {
        _section = State(initialValue: initialSection)
        _date = State(initialValue: date)
        _pendingHRVScroll = State(initialValue: showHRV)
    }
    private var hrvSamples: [HRVSample] { healthSnapshot.hrv }
    private func selectedPoint(for metric: TrendMetric) -> HeartHealthTrendPoint? {
        guard let selectedDate = selectedDates[metric] else { return nil }
        let points = metric == .hrv ? hrvPoints : heartRatePoints
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    private var summary: DailySummary { DailySummary(records: dailyRecords, date: date) }
    private var interval: DateInterval { range.interval(endingAt: date) }
    private var dateTitle: String {
        if section == 0 { return date.formatted(.dateTime.year().month(.wide).day().locale(L10n.locale)) }
        let last = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
        switch range {
        case .month: return interval.start.formatted(.dateTime.year().month().locale(L10n.locale)) + " – " + last.formatted(.dateTime.year().month().locale(L10n.locale))
        case .day, .week: return interval.start.formatted(.dateTime.year().month().day().locale(L10n.locale)) + " – " + last.formatted(.dateTime.year().month().day().locale(L10n.locale))
        }
    }
    private var periodLabel: String? {
        section == 0 && Calendar.current.isDateInToday(date) ? L10n.text("今天") : nil
    }
    private var canMoveForward: Bool {
        let calendar = Calendar.current
        return (calendar.dateInterval(of: section == 0 ? .day : range.component, for: date)?.end ?? date) <= Date.now
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Picker(L10n.text("查看方式"), selection: $section) { Text(L10n.text("当日")).tag(0); Text(L10n.text("趋势")).tag(1) }.pickerStyle(.segmented).accessibilityIdentifier("insightsSection")
                dateNavigation
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if model.isDemo { Tag(text: L10n.text("合成示例"), color: HP.coral) }
                        if !model.isDemo && !model.hasRequestedHeartHealth {
                            Button { Task { await model.connect() } } label: {
                                Label(L10n.text("连接日常心率与 HRV"), systemImage: "heart.text.clipboard")
                            }.disabled(model.isConnecting || model.isSyncing)
                        }
                        if loadingHealth { ProgressView().frame(maxWidth: .infinity).accessibilityIdentifier("insightsLoading") }
                        if let healthError { Text(healthError).font(.caption).foregroundStyle(.secondary) }
                        if section == 0 { dayContent } else { trendContent }
                        ReferenceFooter()
                    }.padding(.horizontal, 20).padding(.bottom, 20).frame(maxWidth: 760).frame(maxWidth: .infinity)
                }
                .contentShape(Rectangle())
                .gesture(InsightsPeriodSwipe(shift: shift))
                .accessibilityIdentifier("insightsContent")
                .onChange(of: loadingHealth) { _, loading in
                    guard !loading, pendingHRVScroll, section == 1 else { return }
                    proxy.scrollTo(TrendMetric.hrv, anchor: .top)
                    pendingHRVScroll = false
                }
                .accessibilityActions {
                    Button(L10n.text("前一天或上一时段")) { shift(-1) }
                    if canMoveForward {
                        Button(L10n.text("后一天或下一时段")) { shift(1) }
                    }
                }
            }
        }
        .background(AppBackground()).navigationTitle(section == 0 ? L10n.text("每日记录") : L10n.text("记录趋势")).navigationBarTitleDisplayMode(.inline)
        .task(id: "\(date)-\(range)-\(section)-\(model.isDemo)-\(model.dataRevision)") { await load() }
        .onChange(of: date) { _, _ in selectedDates.removeAll() }
        .onChange(of: range) { _, _ in selectedDates.removeAll() }
        .onChange(of: section) { _, _ in selectedDates.removeAll() }
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                DatePicker(L10n.text("选择日期"), selection: $date, in: ...Date.now, displayedComponents: .date).datePickerStyle(.graphical).padding()
                    .navigationTitle(L10n.text("选择日期")).navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("完成")) { showCalendar = false } } }
            }.presentationDetents([.medium, .large])
        }
    }

    private var dateNavigation: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left").foregroundStyle(HP.caret).frame(width: 44, height: 44) }.accessibilityLabel(L10n.text("前一天或上一时段")).accessibilityIdentifier("previousInsightsPeriod")
            Spacer()
            Button { showCalendar = true } label: {
                VStack(spacing: 3) {
                    Text(dateTitle).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                    if let periodLabel { Text(periodLabel).font(.caption2).foregroundStyle(.secondary) }
                }
            }.foregroundStyle(.primary).frame(minHeight: 44).accessibilityIdentifier("insightsDate").accessibilityLabel(dateTitle)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right").foregroundStyle(HP.caret).frame(width: 44, height: 44) }
                .disabled(!canMoveForward).accessibilityLabel(L10n.text("后一天或下一时段")).accessibilityIdentifier("nextInsightsPeriod")
        }.padding(8).hpGlass(interactive: true)
    }

    private var dayContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            DailyHero(summary: summary, health: dailyHealth, isDemo: model.isDemo, title: L10n.text("当日概览"))
            if !healthSnapshot.heartRates.isEmpty {
                Surface {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: L10n.text("日常心率"), subtitle: L10n.text("按小时汇总"))
                        Chart(healthSnapshot.heartRates) { bucket in
                            RuleMark(x: .value(L10n.text("时间"), bucket.date),
                                     yStart: .value("bpm", bucket.minimum), yEnd: .value("bpm", bucket.maximum))
                                .foregroundStyle(HP.coral.opacity(0.3)).lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
                            PointMark(x: .value(L10n.text("时间"), bucket.date), y: .value("bpm", bucket.average)).foregroundStyle(HP.coral)
                        }.frame(height: 160).chartYAxisLabel("bpm").accessibilityIdentifier("dailyHeartRateChart")
                        Text(L10n.text("圆点表示时段平均值，竖线表示最低到最高；活动和休息都会影响心率。"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            SectionHeading(title: L10n.text("当日心电"), subtitle: L10n.text("\(dailyRecords.count) 条"))
            if dailyRecords.isEmpty { EmptyPanel(title: L10n.text("这一天还没有记录"), message: L10n.text("左右切换日期，查看其他心电图。")) }
            ForEach(dailyRecords) { record in
                NavigationLink { ECGDetailView(record: record) } label: { ECGCard(record: record, hasNote: model.notes.contains { $0.recordID == record.id }) }.buttonStyle(.plain)
                    .accessibilityIdentifier("dailyECG-\(record.id)")
            }
        }
    }

    private var trendContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            Picker(L10n.text("时间范围"), selection: $range) { ForEach(HeartHealthTrendRange.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.segmented).accessibilityIdentifier("trendRange")
            ForEach(TrendMetric.allCases, id: \.self) { metric in
                trendPanel(for: metric).id(metric)
            }
        }
    }

    private func trendPanel(for metric: TrendMetric) -> some View {
        let points = metric == .hrv ? hrvPoints : heartRatePoints
        let selectedPoint = selectedPoint(for: metric)
        let selection = Binding<Date?>(get: { selectedDates[metric] }, set: { selectedDates[metric] = $0 })
        return VStack(alignment: .leading, spacing: 16) {
            Surface {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(metric == .hrv ? L10n.text("Apple 健康 SDNN") : metric.title)
                                .font(.headline).accessibilityIdentifier("trendTitle-\(metric.rawValue)")
                            if metric == .bpm {
                                Text(L10n.text("时段平均心率的中位数")).font(.subheadline).foregroundStyle(.secondary)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 7) {
                                Text(Statistics.median(points.map(\.value))?.integerText ?? "—").font(.system(size: 46, weight: .semibold, design: .rounded)).tracking(-2)
                                Text(metric.unit).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()

                    }
                    if points.isEmpty {
                        EmptyPanel(icon: "chart.xyaxis.line", title: L10n.text("还没有可比较的数据"), message: L10n.text("这段时间没有此指标的可读取样本。"))
                    } else {
                        Chart(points) { point in
                            LineMark(x: .value(L10n.text("日期"), point.date), y: .value(metric.title, point.value), series: .value(L10n.text("连续段"), point.segment))
                                .foregroundStyle(HP.coral).lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            PointMark(x: .value(L10n.text("日期"), point.date), y: .value(metric.title, point.value)).foregroundStyle(HP.coral).symbolSize(28)
                            if selectedPoint?.id == point.id {
                                RuleMark(x: .value(L10n.text("选择日期"), point.date)).foregroundStyle(HP.coral.opacity(0.25)).lineStyle(StrokeStyle(dash: [4, 4]))
                            }
                        }.chartXScale(domain: interval.start...interval.end).chartYScale(domain: chartDomain(for: points))
                            .chartXSelection(value: selection)
                            .chartGesture { proxy in
                                SpatialTapGesture().onEnded { value in proxy.selectXValue(at: value.location.x) }
                            }
                            .chartLegend(.hidden).frame(height: 195)
                            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: range == .month ? .dateTime.month(.abbreviated).locale(L10n.locale) : .dateTime.month().day().locale(L10n.locale))
                            } }
                            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in AxisGridLine(stroke: StrokeStyle(dash: [3, 4])); AxisValueLabel() } }
                            .accessibilityLabel(L10n.text("\(metric.title)趋势，\(points.count) 个有效数据点"))
                            .accessibilityIdentifier("heartHealthTrendChart-\(metric.rawValue)")
                    }
                    HStack {
                        Text(metric == .hrv ? L10n.text("\(hrvSamples.filter { $0.date >= interval.start && $0.date < interval.end }.count) 条 SDNN") : L10n.text("\(healthSnapshot.heartRates.count) 个日常心率时段"))
                        Spacer()
                        Text(range.aggregationTitle)
                    }.font(.caption).foregroundStyle(.secondary)
                }
            }
            if let point = selectedPoint {
                Button { open(point) } label: {
                    HStack { Text(pointTitle(point)); Spacer(); Text("\(point.value.integerText) \(metric.unit)"); Image(systemName: "arrow.up.right") }.font(.subheadline).padding(18).hpGlass(interactive: true)
                }.accessibilityIdentifier("selectedTrendPoint-\(metric.rawValue)")
            }
            if metric == .hrv {
                if !model.isDemo { Button(L10n.text("重新读取")) { Task { await load() } }.disabled(loadingHealth).buttonStyle(.bordered).buttonBorderShape(.capsule) }
                Text(L10n.text("系统 SDNN 单独展示，不与短时 ECG 的 RR 波动混算。记录时长、姿势、呼吸和来源都会影响结果。")).font(.caption).foregroundStyle(.secondary)
            } else {
                Label(L10n.text("空缺保留为空，不补零、不推测未记录的时间。"), systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trendPanel-\(metric.rawValue)")
    }

    private func chartDomain(for points: [HeartHealthTrendPoint]) -> ClosedRange<Double> {
        let low = points.map(\.value).min() ?? 0, high = points.map(\.value).max() ?? 100
        return max(0, low - 8)...max(low + 16, high + 8)
    }
    private func shift(_ direction: Int) {
        guard direction < 0 || canMoveForward else { return }
        if section == 0 {
            if let next = Calendar.current.date(byAdding: .day, value: direction, to: date) { date = min(next, .now) }
        } else {
            date = range.shiftedDate(from: date, direction: direction)
        }
    }
    private func pointTitle(_ point: HeartHealthTrendPoint) -> String {
        switch range {
        case .day: point.date.formatted(.dateTime.month().day().locale(L10n.locale))
        case .week: point.date.formatted(.dateTime.month().day().locale(L10n.locale)) + " – " + (Calendar.current.date(byAdding: .day, value: -1, to: point.end) ?? point.date).formatted(.dateTime.month().day().locale(L10n.locale))
        case .month: point.date.formatted(.dateTime.year().month().locale(L10n.locale))
        }
    }
    private func open(_ point: HeartHealthTrendPoint) {
        date = min(Calendar.current.date(byAdding: .day, value: -1, to: point.end) ?? point.date, .now)
        switch range {
        case .day: section = 0
        case .week: range = .day
        case .month: range = .week
        }
        selectedDates.removeAll()
    }
    private func load() async {
        loadGeneration += 1
        let generation = loadGeneration, revision = model.dataRevision
        let requestedDate = date, requestedRange = range, requestedDemo = model.isDemo, requestedSection = section
        let requestedInterval = interval
        let calendar = Calendar.current
        loadingHealth = true; healthError = nil
        dailyRecords = []; dailyHealth = HeartHealthSnapshot(); healthSnapshot = HeartHealthSnapshot()
        heartRatePoints = []; hrvPoints = []
        guard let day = calendar.dateInterval(of: .day, for: requestedDate) else { loadingHealth = false; return }
        let queryEnd = min(requestedInterval.end, calendar.dateInterval(of: .day, for: .now)?.end ?? requestedInterval.end)
        let daily = requestedSection == 0 ? await model.records(on: requestedDate) : []
        do {
            let health = try await model.heartHealth(from: requestedSection == 0 ? day.start : requestedInterval.start,
                to: requestedSection == 0 ? day.end : queryEnd, hourly: requestedSection == 0)
            let dayHealth = requestedSection == 0 ? try await model.heartHealth(from: day.start, to: day.end) : HeartHealthSnapshot()
            let aggregated = await Task.detached(priority: .userInitiated) {
                guard requestedSection == 1 else { return ([HeartHealthTrendPoint](), [HeartHealthTrendPoint]()) }
                return (requestedRange.points(samples: health.heartRates.map { ($0.date, $0.average) }, in: requestedInterval, calendar: calendar),
                        requestedRange.points(samples: health.hrv.map { ($0.date, $0.milliseconds) }, in: requestedInterval, calendar: calendar))
            }.value
            guard !Task.isCancelled, loadGeneration == generation, model.dataRevision == revision,
                  date == requestedDate, range == requestedRange, section == requestedSection, model.isDemo == requestedDemo else { return }
            dailyRecords = daily; healthSnapshot = health; dailyHealth = dayHealth
            heartRatePoints = aggregated.0; hrvPoints = aggregated.1
            loadingHealth = false
        } catch {
            guard !Task.isCancelled, loadGeneration == generation, model.dataRevision == revision,
                  date == requestedDate, range == requestedRange, section == requestedSection, model.isDemo == requestedDemo else { return }
            dailyRecords = daily; loadingHealth = false; healthError = error.localizedDescription
        }
    }
}
