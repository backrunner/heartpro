import SwiftUI
import HeartProCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var confirmClear = false
    @State private var showGuide = false
    @State private var showNotice = false
    var body: some View {
        List {
            Section {
                HStack(spacing: 15) {
                    Image("BrandMark").resizable().scaledToFit()
                        .frame(width: 44, height: 44).frame(width: 62, height: 62)
                        .hpGlass(tint: HP.coral.opacity(0.08)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("HeartPro").font(.system(.title2, design: .rounded, weight: .bold))
                        Text(L10n.text("Apple Watch 心电记录与统计")).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
            }
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    LabeledContent(L10n.text("应用语言"), value: L10n.locale.localizedString(forIdentifier: L10n.language) ?? L10n.language)
                }.accessibilityIdentifier("appLanguage")
            } header: { Text(L10n.text("语言")) }

            Section(L10n.text("健康数据")) {
                Button { Task { await model.connect() } } label: { Label(L10n.text("健康授权"), systemImage: "heart.text.clipboard") }
                Button { model.refresh() } label: { Label(L10n.text("同步记录"), systemImage: "arrow.triangle.2.circlepath") }.disabled(model.isDemo || model.isSyncing || !model.hasConnected)
                if !model.isDemo && model.hasUnfinishedAnalyses {
                    Button { Task { await model.retryFailedAnalyses() } } label: { Label(L10n.text("重试未完成的分析"), systemImage: "arrow.clockwise") }
                        .disabled(model.isSyncing || !model.hasConnected)
                        .accessibilityIdentifier("retryUnfinishedAnalyses")
                }
            }
            Section(L10n.text("帮助")) {
                Link(destination: URL(string: "https://heartpro.alkinum.com/\(L10n.language == "zh-Hans" ? "zh/" : "")support/")!) {
                    Label(L10n.text("支持与联系"), systemImage: "envelope")
                }
                    .accessibilityIdentifier("supportWebsite")
                Button { showGuide = true } label: { Label(L10n.text("使用指南"), systemImage: "book.closed") }
                    .accessibilityIdentifier("openUsageGuide")
                Button {
                    Task { if model.isDemo { await model.leaveDemo() } else { await model.enterDemo() }; dismiss() }
                } label: { Label(model.isDemo ? L10n.text("退出演示，查看我的数据") : L10n.text("体验示例"), systemImage: "play.circle") }
            }
            Section(L10n.text("关于")) {
                Button(L10n.text("使用须知")) { showNotice = true }
                    .accessibilityIdentifier("openUsageNotice")
                Link(L10n.text("隐私政策"), destination: URL(string: "https://heartpro.alkinum.com/\(L10n.language == "zh-Hans" ? "zh/" : "")privacy/")!)
                    .accessibilityIdentifier("privacyPolicy")
                NavigationLink(L10n.text("分析能力与限制")) { methods }
                NavigationLink(L10n.text("数据保护与管理")) { privacy }
                LabeledContent(L10n.text("应用版本"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.6.0")
            }
            Section {
                Button(L10n.text("清空 HeartPro 本地数据"), role: .destructive) { confirmClear = true }.disabled(model.isDemo || model.isWritingNotes)
            } footer: { Text(L10n.text("不会删除 Apple 原始心电图，也不会删除已写入健康的独立症状。")) }
        }.navigationTitle(L10n.text("设置")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("完成")) { dismiss() } } }
            .sheet(isPresented: $showGuide) { UsageGuideView() }
            .sheet(isPresented: $showNotice) { UsageNoticeView(acknowledging: false) { showNotice = false } }
            .confirmationDialog(L10n.text("清空所有本地心电副本、分析与备忘？此操作不能撤销。"), isPresented: $confirmClear, titleVisibility: .visible) {
                Button(L10n.text("清空本地数据"), role: .destructive) { Task { await model.clearLocalData() } }
            }
    }

    private var methods: some View {
        List {
            Section(L10n.text("当前提供")) {
                Text(L10n.text("查看 Apple 健康中的心电图、分类和心率，按日期回看历史与趋势。你也可以添加备忘、选择将症状保存到健康 App，或导出 PDF。"))
                Text(L10n.text("应用会估算每次心跳的波峰、间隔和波形变化。你可以按段查看结果、回到原图核对，也可以自己选两个点测量时间和电压差。"))
            }
            Section(L10n.text("尚不提供医学判断")) {
                Text(L10n.text("自动测量尚未经过真实 Apple Watch 数据的准确度验证，不能判断心电是否正常。看不清的波段会说明原因并留空。"))
                Text(L10n.text("单导联不能可靠识别或排除心梗、心肌缺血。应用不能用于医疗用途，不能替代医生诊断。"))
            }
            Section(L10n.text("参考依据")) {
                Link(L10n.text("Apple Watch ECG 使用说明"), destination: URL(string: "https://support.apple.com/en-us/120278")!)
                Link(L10n.text("HealthKit 心电数据说明"), destination: URL(string: "https://developer.apple.com/documentation/healthkit/hkelectrocardiogram")!)
                Link(L10n.text("HRV 指标与参考值综述"), destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/")!)
            }
        }.navigationTitle(L10n.text("分析方法")).navigationBarTitleDisplayMode(.inline)
    }

    private var privacy: some View {
        List {
            Section(L10n.text("留在设备上")) {
                Text(L10n.text("心电分析和备忘留在此设备上，HeartPro 不会上传这些数据。"))
                Text(L10n.text("无需账号，没有广告或跟踪。健康数据不通过 HeartPro 同步到 iCloud，也不会用于营销。"))
                Text(L10n.text("你可以随时在 Apple 健康中更改授权。已导入的记录可在这里清空。"))
            }
            Section(L10n.text("你的选择")) {
                Text(L10n.text("只有你选择保存到 Apple 健康时，症状才会写入；文字备忘留在 HeartPro。"))
                Text(L10n.text("报告由你选择是否分享，请留意接收人。"))
                Text(L10n.text("临时报告在下次打开应用时清理超过 24 小时的副本；清空本地数据也会删除这些副本。已分享的文件由接收人管理。"))
                Text(L10n.text("清空本地数据会删除本地备忘，请先导出需要的内容。Apple 健康中的原始数据及独立症状不会被删除。"))
            }
        }.navigationTitle(L10n.text("数据保护")).navigationBarTitleDisplayMode(.inline)
    }
}
