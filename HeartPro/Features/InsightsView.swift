import SwiftUI
import Charts
import HeartProCore

private enum TrendRange: String, CaseIterable { case day, week, month, year
    var title: String { switch self { case .day: L10n.text("日"); case .week: L10n.text("周"); case .month: L10n.text("月"); case .year: L10n.text("年") } }
    var component: Calendar.Component { switch self { case .day: .day; case .week: .weekOfYear; case .month: .month; case .year: .year } }
}
private enum TrendMetric: String, CaseIterable { case bpm, hrv
    var title: String { switch self { case .bpm: L10n.text("日常心率"); case .hrv: L10n.text("健康 SDNN") } }
    var unit: String { switch self { case .bpm: "bpm"; case .hrv: "ms" } }
}
private struct TrendPoint: Identifiable { var date: Date; var value: Double; var count: Int; var segment: Int; var id: Date { date } }

struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @State private var section: Int
    @State private var date = Date.now
    @State private var range: TrendRange = .week
    @State private var metric: TrendMetric
    @State private var dailyRecords: [ECGRecord] = []
    @State private var dailyHealth = HeartHealthSnapshot()
    @State private var loadingHealth = false
    @State private var healthError: String?
    @State private var showCalendar = false
    @State private var selectedDate: Date?
    @State private var healthSnapshot = HeartHealthSnapshot()

    init(initialSection: Int, showHRV: Bool = false) {
        _section = State(initialValue: initialSection)
        _metric = State(initialValue: showHRV ? .hrv : .bpm)
    }
    init(initialSection: Int, date: Date, showHRV: Bool = false) {
        _section = State(initialValue: initialSection)
        _date = State(initialValue: date)
        _metric = State(initialValue: showHRV ? .hrv : .bpm)
    }
    private var hrvSamples: [HRVSample] { healthSnapshot.hrv }
    private var selectedPoint: TrendPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    private var summary: DailySummary { DailySummary(records: dailyRecords, date: date) }
    private var interval: DateInterval { Calendar.current.dateInterval(of: range.component, for: date) ?? DateInterval(start: date, duration: 86400) }
    private var dateTitle: String {
        if section == 0 || range == .day { return date.formatted(.dateTime.year().month(.wide).day().locale(L10n.locale)) }
        switch range {
        case .year: return date.formatted(.dateTime.year().locale(L10n.locale))
        case .month: return date.formatted(.dateTime.year().month(.wide).locale(L10n.locale))
        case .week: return interval.start.formatted(.dateTime.year().month().day().locale(L10n.locale)) + " – " + interval.end.addingTimeInterval(-1).formatted(.dateTime.month().day().locale(L10n.locale))
        case .day: return date.formatted(.dateTime.year().month().day().locale(L10n.locale))
        }
    }
    private var periodLabel: String? {
        if section == 0 { return Calendar.current.isDateInToday(date) ? L10n.text("今天") : nil }
        guard interval.contains(.now) else { return nil }
        return switch range { case .day: L10n.text("今天"); case .week: L10n.text("本周"); case .month: L10n.text("本月"); case .year: L10n.text("今年") }
    }

    private var points: [TrendPoint] {
        let samples: [(Date, Double)] = metric == .hrv
            ? hrvSamples.map { ($0.date, $0.milliseconds) }
            : healthSnapshot.heartRates.map { ($0.date, $0.average) }
        if range == .day {
            var segment = 0
            let sorted = samples.sorted { $0.0 < $1.0 }
            return sorted.enumerated().map { index, sample in
                if index > 0, sample.0.timeIntervalSince(sorted[index - 1].0) > 5400 { segment += 1 }
                return TrendPoint(date: sample.0, value: sample.1, count: 1, segment: segment)
            }
        }
        let calendar = Calendar.current
        let component: Calendar.Component = range == .year ? .month : .day
        let grouped = Dictionary(grouping: samples) { calendar.dateInterval(of: component, for: $0.0)?.start ?? $0.0 }
        var cursor = interval.start, result: [TrendPoint] = [], segment = 0
        while cursor < interval.end {
            guard let end = calendar.date(byAdding: component, value: 1, to: cursor) else { break }
            let values = grouped[cursor]?.map(\.1) ?? []
            if let median = Statistics.median(values) {
                result.append(TrendPoint(date: cursor, value: median, count: values.count, segment: segment))
            } else { segment += 1 }
            cursor = end
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                Picker(L10n.text("查看方式"), selection: $section) { Text(L10n.text("当日")).tag(0); Text(L10n.text("趋势")).tag(1) }.pickerStyle(.segmented).accessibilityIdentifier("insightsSection")
                dateNavigation
                if model.isDemo { Tag(text: L10n.text("合成示例"), color: HP.coral) }
                if !model.isDemo && !model.hasRequestedHeartHealth {
                    Button { Task { await model.connect() } } label: {
                        Label(L10n.text("连接日常心率与 HRV"), systemImage: "heart.text.clipboard")
                    }.disabled(model.isConnecting || model.isSyncing)
                }
                if loadingHealth { ProgressView().frame(maxWidth: .infinity) }
                if let healthError { Text(healthError).font(.caption).foregroundStyle(.secondary) }
                if section == 0 { dayContent } else { trendContent }
                ReferenceFooter()
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(AppBackground()).navigationTitle(section == 0 ? L10n.text("每日记录") : L10n.text("记录趋势")).navigationBarTitleDisplayMode(.inline)
        .task(id: "\(date)-\(range)-\(section)-\(model.isDemo)-\(model.dataRevision)") { await load() }
        .onChange(of: date) { _, _ in selectedDate = nil }
        .onChange(of: range) { _, _ in selectedDate = nil }
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
            Button { shift(-1) } label: { Image(systemName: "chevron.left").foregroundStyle(HP.caret).frame(width: 32, height: 32) }.accessibilityLabel(L10n.text("前一天或上一时段"))
            Spacer()
            Button { showCalendar = true } label: {
                VStack(spacing: 3) {
                    Text(dateTitle).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                    if let periodLabel { Text(periodLabel).font(.caption2).foregroundStyle(.secondary) }
                }
            }.foregroundStyle(.primary)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right").foregroundStyle(HP.caret).frame(width: 32, height: 32) }
                .disabled(section == 0 ? Calendar.current.isDateInToday(date) : interval.contains(.now)).accessibilityLabel(L10n.text("后一天或下一时段"))
        }.padding(8).hpGlass(interactive: true)
    }

    private var dayContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            DailyHero(summary: summary, health: dailyHealth, isDemo: model.isDemo, title: L10n.text("当日概览"))
                .gesture(DragGesture(minimumDistance: 40).onEnded { value in
                    if abs(value.translation.width) > 70 && abs(value.translation.height) < 60 { shift(value.translation.width < 0 ? 1 : -1) }
                })
            if !healthSnapshot.heartRates.isEmpty {
                Surface {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: L10n.text("日常心率"), subtitle: L10n.text("按小时汇总"))
                        Chart(healthSnapshot.heartRates) { bucket in
                            RuleMark(x: .value(L10n.text("时间"), bucket.date),
                                     yStart: .value("bpm", bucket.minimum), yEnd: .value("bpm", bucket.maximum))
                                .foregroundStyle(HP.coral.opacity(0.3)).lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
                            PointMark(x: .value(L10n.text("时间"), bucket.date), y: .value("bpm", bucket.average)).foregroundStyle(HP.coral)
                        }.frame(height: 160).chartYAxisLabel("bpm")
                        Text(L10n.text("圆点表示时段平均值，竖线表示最低到最高；活动和休息都会影响心率。"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            SectionHeading(title: L10n.text("当日心电"), subtitle: L10n.text("\(dailyRecords.count) 条"))
            if dailyRecords.isEmpty { EmptyPanel(title: L10n.text("这一天还没有记录"), message: L10n.text("左右切换日期，查看其他心电图。")) }
            ForEach(dailyRecords) { record in
                NavigationLink { ECGDetailView(record: record) } label: { ECGCard(record: record, hasNote: model.notes.contains { $0.recordID == record.id }) }.buttonStyle(.plain)
            }
        }
    }

    private var trendContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            Picker(L10n.text("时间范围"), selection: $range) { ForEach(TrendRange.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.segmented).accessibilityIdentifier("trendRange")
            HStack(spacing: 8) {
                ForEach(TrendMetric.allCases, id: \.self) { item in
                    Button { metric = item; selectedDate = nil } label: {
                        Text(item.title).font(.subheadline.weight(metric == item ? .semibold : .regular))
                            .padding(.horizontal, 15).padding(.vertical, 9)
                            .background(metric == item ? HP.coral.opacity(0.1) : .clear, in: Capsule())
                    }.foregroundStyle(metric == item ? HP.coral : .secondary)
                        .accessibilityIdentifier("trendMetric-\(item.rawValue)")
                }
            }
            Surface {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(metric == .hrv ? L10n.text("Apple 健康 SDNN") : L10n.text("时段平均心率的中位数")).font(.subheadline).foregroundStyle(.secondary)
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
                        }.chartXScale(domain: interval.start...interval.end).chartYScale(domain: chartDomain)
                            .chartXSelection(value: $selectedDate).chartLegend(.hidden).frame(height: 195)
                            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in AxisGridLine(stroke: StrokeStyle(dash: [3, 4])); AxisValueLabel() } }
                            .accessibilityLabel(L10n.text("\(metric.title)趋势，\(points.count) 个有效数据点"))
                    }
                    HStack {
                        Text(metric == .hrv ? L10n.text("\(hrvSamples.filter { $0.date >= interval.start && $0.date < interval.end }.count) 条 SDNN") : L10n.text("\(healthSnapshot.heartRates.count) 个日常心率时段"))
                        Spacer()
                        Text(range == .day ? L10n.text("按记录展示") : range == .year ? L10n.text("按月汇总") : L10n.text("按日汇总"))
                    }.font(.caption).foregroundStyle(.secondary)
                }
            }
            if let point = selectedPoint {
                Button { date = point.date; section = 0 } label: {
                    HStack { Text(point.date.formatted(.dateTime.month().day().locale(L10n.locale))); Spacer(); Text("\(point.value.integerText) \(metric.unit)"); Image(systemName: "arrow.up.right") }.font(.subheadline).padding(18).hpGlass(interactive: true)
                }
            }
            if metric == .hrv {
                if !model.isDemo { Button(L10n.text("重新读取")) { Task { await load() } }.disabled(loadingHealth).buttonStyle(.bordered).buttonBorderShape(.capsule) }
                Text(L10n.text("系统 SDNN 单独展示，不与短时 ECG 的 RR 波动混算。记录时长、姿势、呼吸和来源都会影响结果。")).font(.caption).foregroundStyle(.secondary)
            } else {
                Label(L10n.text("空缺保留为空，不补零、不推测未记录的时间。"), systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var chartDomain: ClosedRange<Double> {
        let low = points.map(\.value).min() ?? 0, high = points.map(\.value).max() ?? 100
        return max(0, low - 8)...max(low + 16, high + 8)
    }
    private func shift(_ direction: Int) {
        let component: Calendar.Component = section == 0 ? .day : range.component
        if let next = Calendar.current.date(byAdding: component, value: direction, to: date) { date = min(next, .now) }
    }
    private func load() async {
        let requestedDate = date, requestedRange = range, requestedDemo = model.isDemo, requestedSection = section
        let requestedInterval = interval
        loadingHealth = true; healthError = nil
        dailyRecords = []; dailyHealth = HeartHealthSnapshot(); healthSnapshot = HeartHealthSnapshot()
        let day = Calendar.current.dateInterval(of: .day, for: requestedDate) ?? DateInterval(start: requestedDate, duration: 86400)
        let daily = await model.records(on: requestedDate)
        do {
            let health = try await model.heartHealth(from: section == 0 ? day.start : requestedInterval.start,
                to: section == 0 ? day.end : requestedInterval.end, hourly: section == 0 || range == .day)
            let dayHealth = section == 0 ? try await model.heartHealth(from: day.start, to: day.end) : HeartHealthSnapshot()
            guard !Task.isCancelled, date == requestedDate, range == requestedRange, section == requestedSection, model.isDemo == requestedDemo else { return }
            dailyRecords = daily; healthSnapshot = health; dailyHealth = dayHealth
            loadingHealth = false
        } catch {
            guard !Task.isCancelled, date == requestedDate, range == requestedRange, section == requestedSection, model.isDemo == requestedDemo else { return }
            dailyRecords = daily; loadingHealth = false; healthError = error.localizedDescription
        }
    }
}
