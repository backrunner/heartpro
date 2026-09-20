import SwiftUI
import HeartProCore
import SwiftData

@main struct HeartProApp: App {
    @State private var model: AppModel?
    private let container: ModelContainer?
    private let startupError: String?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            if testing { UIView.setAnimationsEnabled(false) }
            container = try ECGRepository.container(inMemory: testing)
            startupError = nil
        } catch { container = nil; startupError = error.localizedDescription }
    }

    var body: some Scene {
        WindowGroup {
            if let model {
                RootView().environment(model).tint(HP.coral)
                    .environment(\.locale, L10n.locale)
                    .modifier(UITestTextSize())
                    .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--light") ? .light : ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : nil)
                    .overlay {
                        if scenePhase != .active {
                            ZStack {
                                HP.canvas.ignoresSafeArea()
                                VStack(spacing: 12) {
                                    Image(systemName: "heart.fill").font(.largeTitle).foregroundStyle(HP.coral)
                                    Text("HeartPro").font(.system(.title2, design: .rounded, weight: .semibold))
                                    Text(L10n.text("健康数据已隐藏")).font(.caption).foregroundStyle(.secondary)
                                }
                            }.accessibilityHidden(true)
                        }
                    }
                    .task { await model.start(); model.refresh() }
                    .onChange(of: scenePhase) { _, phase in
                        if phase == .active { model.refresh() }
                        else if phase == .background { model.cancelSync() }
                    }
            } else if let startupError {
                ContentUnavailableView(L10n.text("暂时无法打开本地资料"), systemImage: "lock.shield",
                                       description: Text(L10n.text("请解锁设备后重新打开。\n\(startupError)")))
            } else {
                ProgressView().task {
                    guard let container else { return }
                    // SwiftData binds its executor when the context is created. Construct
                    // the repository off the main actor so database/JSON work stays off UI.
                    let repository = await Task.detached(priority: .userInitiated) {
                        ECGRepository(modelContainer: container)
                    }.value
                    model = AppModel(repository: repository)
                }
            }
        }
    }
}

private struct UITestTextSize: ViewModifier {
    func body(content: Content) -> some View {
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--large-text") {
            content.dynamicTypeSize(.accessibility1)
        } else { content }
    }
}

struct RootView: View {
    @AppStorage("hasSeenUsageGuide") private var hasSeenUsageGuide = false
    @State private var showGuide = false
    @Environment(AppModel.self) private var model
    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab(L10n.text("心电"), systemImage: "waveform.path.ecg", value: 0) {
                NavigationStack { TimelineView() }
            }
            Tab(L10n.text("趋势"), systemImage: "chart.xyaxis.line", value: 1) {
                NavigationStack { InsightsView(initialSection: 1) }
            }
        }
        .task {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--uitesting") && args.contains("--reset-guide") { hasSeenUsageGuide = false }
            if !hasSeenUsageGuide && !args.contains("--skip-guide") { showGuide = true }
        }
        .sheet(isPresented: $showGuide, onDismiss: { hasSeenUsageGuide = true }) { UsageGuideView() }
        .alert(L10n.text("提示"), isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(L10n.text("知道了"), role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
