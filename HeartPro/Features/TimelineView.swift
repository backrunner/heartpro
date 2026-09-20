import SwiftUI
import HeartProCore

private struct RecordDay: Identifiable {
    var date: Date
    var records: [ECGRecord]
    var id: Date { date }
}

struct TimelineView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false
    @State private var showOverview = false
    @State private var selectedRecord: ECGRecord?
    @State private var showDatePicker = false
    @State private var selectedDate = Date.now
    @State private var filterDate: Date?
    @State private var filteredRecords: [ECGRecord] = []
    @State private var loadingDay = false
    @State private var today: [ECGRecord] = []
    @State private var todayHealth = HeartHealthSnapshot()
    private var summary: DailySummary { DailySummary(records: today, date: .now) }
    private var displayedRecords: [ECGRecord] { filterDate == nil ? model.records : filteredRecords }
    private var days: [RecordDay] {
        Dictionary(grouping: displayedRecords, by: { Calendar.current.startOfDay(for: $0.date) })
            .map { RecordDay(date: $0.key, records: $0.value) }.sorted { $0.date > $1.date }
    }
    private var showsLanding: Bool {
        !model.hasConnected && !model.isDemo && model.records.isEmpty && !model.isPreparingDemo
    }
    var body: some View {
        Group {
            if showsLanding {
                AuthorizationLandingView(isConnecting: model.isConnecting,
                    connect: { Task { await model.connect() } }, enterDemo: { Task { await model.enterDemo() } })
            } else { timeline }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) { HeartProWordmark() }.sharedBackgroundVisibility(.hidden)
            } else { ToolbarItem(placement: .topBarLeading) { HeartProWordmark() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("设置"), systemImage: "slider.horizontal.3") { showSettings = true }.accessibilityIdentifier("settings")
            }
        }
        .navigationDestination(isPresented: $showOverview) { InsightsView(initialSection: 0) }
        .navigationDestination(isPresented: Binding(get: { selectedRecord != nil }, set: { if !$0 { selectedRecord = nil } })) {
            if let selectedRecord { ECGDetailView(record: selectedRecord) }
        }
        .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() } }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(L10n.text("选择日期"), selection: $selectedDate, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding().accessibilityIdentifier("historyDatePicker")
                    .navigationTitle(L10n.text("按日期查找")).navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button(L10n.text("取消")) { showDatePicker = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.text("完成")) { filterDate = Calendar.current.startOfDay(for: selectedDate); showDatePicker = false }
                        }
                    }
            }.presentationDetents([.medium, .large])
        }
        .refreshable { model.refresh() }
        .task(id: "\(model.isDemo)-\(model.dataRevision)") {
            let demo = model.isDemo
            let records = await model.records(on: .now)
            guard !Task.isCancelled, demo == model.isDemo else { return }
            today = records
            if demo {
                let start = Calendar.current.startOfDay(for: .now)
                let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
                todayHealth = DemoData.heartHealth(from: start, to: end)
            } else { todayHealth = model.todayHealth.day(.now) }
        }
        .task(id: "\(filterDate?.timeIntervalSince1970 ?? -1)-\(model.isDemo)-\(model.dataRevision)") {
            guard let requested = filterDate else { filteredRecords = []; loadingDay = false; return }
            loadingDay = true
            let values = await model.records(on: requested)
            guard !Task.isCancelled, filterDate == requested else { return }
            filteredRecords = values; loadingDay = false
        }
    }

    private var timeline: some View {
        let noteIDs = Set(model.notes.map(\.recordID))
        let indices = Dictionary(uniqueKeysWithValues: displayedRecords.enumerated().map { ($0.element.id, $0.offset) })
        return List {
            Group {
                header
                if model.isPreparingDemo {
                    ProgressView(L10n.text("正在准备合成演示…")).frame(maxWidth: .infinity).padding(.vertical, 80)
                } else {
                    Button { showOverview = true } label: {
                        DailyHero(summary: summary, health: todayHealth, isDemo: model.isDemo, navigates: true)
                    }.buttonStyle(.plain).accessibilityIdentifier("dailyOverview")
                    status
                    if !model.isDemo && !model.hasRequestedHeartHealth {
                        Button { Task { await model.connect() } } label: {
                            Label(L10n.text("连接日常心率与 HRV"), systemImage: "heart.text.clipboard")
                        }.disabled(model.isConnecting || model.isSyncing)
                    }
                    HStack {
                        SectionHeading(title: L10n.text("心电记录"), subtitle: L10n.text("共 \(model.totalCount) 条"))
                        Spacer()
                        Button { selectedDate = filterDate ?? .now; showDatePicker = true } label: {
                            Label(L10n.text("按日期查找"), systemImage: "calendar")
                        }.font(.subheadline).accessibilityIdentifier("timelineCalendar")
                    }
                    if let filterDate {
                        HStack {
                            Button { shiftHistoryDay(-1) } label: { Image(systemName: "chevron.left").frame(width: 32, height: 40) }
                                .accessibilityLabel(L10n.text("前一天或上一时段")).accessibilityIdentifier("previousHistoryDay")
                            Text(filterDate.formatted(.dateTime.year().month().day().locale(L10n.locale)))
                            Button { shiftHistoryDay(1) } label: { Image(systemName: "chevron.right").frame(width: 32, height: 40) }
                                .disabled(Calendar.current.isDateInToday(filterDate))
                                .accessibilityLabel(L10n.text("后一天或下一时段")).accessibilityIdentifier("nextHistoryDay")
                            Spacer()
                            Button(L10n.text("全部记录")) { self.filterDate = nil }
                                .accessibilityIdentifier("clearDateFilter")
                        }.font(.subheadline)
                    }
                    if loadingDay { ProgressView().frame(maxWidth: .infinity) }
                    else if displayedRecords.isEmpty {
                        EmptyPanel(title: L10n.text("暂无可读取的心电图"), message: L10n.text("在 Apple Watch 上完成 ECG 测量，并等待同步到 iPhone。也可以在健康中检查 HeartPro 的读取权限。"))
                    }
                }
            }.listRowSeparator(.hidden).listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

            if !loadingDay {
                ForEach(days) { day in
                    Section {
                        ForEach(day.records) { record in
                            Button { selectedRecord = record } label: {
                                ECGCard(record: record, hasNote: noteIDs.contains(record.id))
                            }.buttonStyle(.plain)
                                .accessibilityIdentifier("ecgRecord-\(indices[record.id] ?? 0)")
                                .listRowSeparator(.hidden).listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        }
                    } header: {
                        Text(day.date.formatted(.dateTime.year().month(.wide).day().weekday(.wide).locale(L10n.locale)))
                            .font(.caption.weight(.medium)).textCase(nil)
                    }
                }
            }
            if filterDate == nil && model.hasMore && !model.records.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
                    .task(id: model.records.count) { await model.loadMore() }
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)
            }
            ReferenceFooter().listRowSeparator(.hidden).listRowBackground(Color.clear)
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    private var header: some View {
        HStack {
            Text(Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide).locale(L10n.locale))).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            if model.isDemo { Tag(text: L10n.text("合成示例"), color: HP.coral) }
        }
    }
    private func shiftHistoryDay(_ offset: Int) {
        guard let filterDate, let next = Calendar.current.date(byAdding: .day, value: offset, to: filterDate) else { return }
        self.filterDate = min(Calendar.current.startOfDay(for: .now), next)
    }
    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if model.isSyncing { ProgressView().controlSize(.small) }
                else { Image(systemName: "heart.text.clipboard").foregroundStyle(HP.teal) }
                Text(model.isDemo ? L10n.text("合成示例，不代表你的健康数据") : model.syncMessage).font(.caption).foregroundStyle(.secondary)
                Spacer()
                if !model.isDemo {
                    Button { model.refresh() } label: { Image(systemName: "arrow.clockwise") }.disabled(model.isSyncing).accessibilityLabel(L10n.text("同步心电图"))
                }
            }
            if !model.isDemo, let message = model.healthErrorMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct DailyHero: View {
    var summary: DailySummary
    var health: HeartHealthSnapshot
    var isDemo: Bool
    var title = L10n.text("今日心脏健康")
    var navigates = false
    @ScaledMetric(relativeTo: .body) private var columnWidth = 95.0
    private var bpm: Double? { Statistics.median(health.heartRates.map(\.average)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if navigates { CardNavigationIndicator() }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: columnWidth), alignment: .leading)], alignment: .leading, spacing: 16) {
                MetricValue(value: bpm?.integerText ?? "—", unit: "bpm", label: L10n.text("日常平均心率"))
                MetricValue(value: Statistics.median(health.hrv.map(\.milliseconds))?.integerText ?? "—", unit: "ms", label: L10n.text("健康 SDNN"))
                MetricValue(value: "\(summary.records.count)", unit: L10n.text("条"), label: L10n.text("心电记录"))
            }
            if let low = health.heartRates.map(\.minimum).min(), let high = health.heartRates.map(\.maximum).max() {
                Text(L10n.text("日常心率范围 \(low.integerText)–\(high.integerText) bpm"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }.padding(20).hpGlass(interactive: navigates)
            .contentShape(RoundedRectangle(cornerRadius: HP.radius))
    }
}

struct ECGCard: View {
    var record: ECGRecord
    var hasNote = false
    // Highlight the recorded source classification, not research beat-difference counts.
    // Absence of a notice is not a conclusion about clinical risk.
    private var noticeColor: Color? {
        switch record.classification {
        case .atrialFibrillation: HP.coral
        case .highHeartRate, .lowHeartRate: HP.amber
        default: nil
        }
    }
    private var heartRateColor: Color {
        record.classification == .highHeartRate || record.classification == .lowHeartRate ? HP.amber : .primary
    }
    var body: some View {
        // Plain rows avoid a glass compositor and a full medical grid for every ECG.
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.date.formatted(.dateTime.hour().minute().locale(L10n.locale)))
                    .font(.system(.headline, design: .rounded)).monospacedDigit()
                Spacer()
                Text(record.bpm?.integerText ?? "—").font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(heartRateColor)
                Text("bpm").font(.caption).foregroundStyle(.secondary)
                if hasNote { Image(systemName: "note.text").font(.caption).foregroundStyle(HP.coral) }
                CardNavigationIndicator().padding(.leading, 4)
            }
            if !record.preview.isEmpty {
                ECGSparkline(points: record.preview).frame(height: 42).accessibilityHidden(true)
            }
            HStack(spacing: 8) {
                if let noticeColor {
                    Label(record.classification.title, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(noticeColor)
                } else {
                    Text(record.classification.title).font(.subheadline)
                }
                Spacer(minLength: 0)
                if record.failure != nil {
                    Text(L10n.text("分析未完成")).foregroundStyle(.secondary)
                } else if record.listSummary?.limitedSignal == true {
                    Text(L10n.text("部分信号不清晰")).foregroundStyle(.secondary)
                } else if !record.isAnalyzed {
                    Text(L10n.text("等待分析")).foregroundStyle(.secondary)
                }
            }.font(.caption)
        }.padding(16).background(HP.paper, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
    }
}

private struct ECGSparkline: View {
    var points: [VoltagePoint]
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var path = Path()
            for (index, point) in points.enumerated() {
                let position = CGPoint(x: point.time / 6 * size.width,
                                       y: size.height * 0.7 - point.millivolts * size.height * 0.5)
                if index == 0 || point.time - points[index - 1].time > 0.08 { path.move(to: position) }
                else { path.addLine(to: position) }
            }
            context.stroke(path, with: .color(HP.ecg), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }.clipped()
    }
}
