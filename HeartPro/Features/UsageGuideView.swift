import SwiftUI
import HeartProCore

/// The same short tour is presented on first entry and from Settings.
struct UsageGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var titles: [String] {
        [L10n.text("查看当日记录与趋势"), L10n.text("按日期打开一条心电"),
         L10n.text("浏览波形与分析模块"), L10n.text("添加备忘与分享报告")]
    }
    private let icons = ["heart.text.clipboard", "calendar", "waveform.path.ecg", "chart.dots.scatter"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Image(systemName: icons[page]).font(.system(size: 34, weight: .light))
                            .foregroundStyle(HP.coral).frame(width: 72, height: 72)
                            .background(HP.coral.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                        Spacer()
                        Text("\(page + 1) / \(titles.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Text(titles[page]).font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader).accessibilityIdentifier("guideTitle")
                    VStack(alignment: .leading, spacing: 24) {
                        switch page {
                        case 0:
                            lesson("heart", L10n.text("今日记录"), L10n.text("轻点当日概览，查看这一天的心率、HRV 和心电记录。"))
                            lesson("chart.xyaxis.line", L10n.text("趋势"), L10n.text("按日、周或月汇总，观察近两周、近一季度或近一年的变化。"))
                        case 1:
                            lesson("calendar", L10n.text("按日期查找"), L10n.text("在心电记录上方轻点日历，直接找到某一天，再切换前一天或后一天。"))
                            lesson("arrow.up.right", L10n.text("打开记录"), L10n.text("轻点整张卡片查看详情。右上角的箭头表示可以进入下一页。"))
                            lesson("exclamationmark.circle", L10n.text("记录中的来源分类"), L10n.text("在卡片上查看来源标签；分类说明与来源可在详情和设置中打开。"))
                        case 2:
                            lesson("waveform.path.ecg", L10n.text("原始心电图"), L10n.text("轻点全屏按钮查看波形，使用缩放或两点测量工具；轻点顶部标签查看对应位置。"))
                            lesson("plus", L10n.text("分段测量与波形对比"), L10n.text("轻点模块右上角的加号展开。分段测量展示本次记录的数值分布和测量方法；波形对比展示形状差异。"))
                            lesson("heart.text.clipboard", L10n.text("节律分析"), L10n.text("轻点候选条目回到原始波形；轻点信息按钮查看规则、限制与参考来源。"))
                        default:
                            lesson("chart.dots.scatter", L10n.text("本次 ECG 的 HRV"), L10n.text("向下滚动到 HRV 模块，轻点信息按钮查看计算说明、限制和文献。"))
                            lesson("note.text", L10n.text("备忘与分享"), L10n.text("轻点添加备忘记录当时的状态。轻点分享按钮生成 PDF，再选择分享目的地。"))
                            lesson("info.circle", L10n.text("随时再看"), L10n.text("模块旁的信息按钮有更详细的说明。也可以在设置中重新打开使用指南。"))
                            HealthReferencesButton()
                        }
                    }
                }.padding(24).frame(maxWidth: 600, alignment: .leading).frame(maxWidth: .infinity)
            }
            .id(page)
            .background(OnboardingBackground())
            .safeAreaInset(edge: .bottom) {
                OnboardingActionBar {
                    HStack(spacing: 12) {
                        if page > 0 {
                            Button(L10n.text("上一步")) { page -= 1 }
                                .modifier(OnboardingButtonStyle()).accessibilityIdentifier("guidePrevious")
                        }
                        Spacer(minLength: 0)
                        Button(page == titles.count - 1 ? L10n.text("开始使用") : L10n.text("下一步")) {
                            if page == titles.count - 1 { dismiss() } else { page += 1 }
                        }
                        .modifier(OnboardingButtonStyle(prominent: true)).accessibilityIdentifier("guideNext")
                    }
                }
            }
            .navigationTitle(L10n.text("使用指南")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("关闭")) { dismiss() }.accessibilityIdentifier("guideClose")
                }
            }
        }
    }

    private func lesson(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(HP.teal).frame(width: 26, height: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
