import SwiftUI
import HeartProCore

/// The same short tour is presented on first entry and from Settings.
struct UsageGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var titles: [String] {
        [L10n.text("先看今天，再看趋势"), L10n.text("找到一条心电，读懂一次测量"),
         L10n.text("看懂心跳的细节"), L10n.text("看懂心跳变化，记下测量时的状态")]
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
                            lesson("heart", L10n.text("今日心脏健康"), L10n.text("快速了解今天的心率、HRV 和心电记录。轻点卡片可查看每日详情。"))
                            lesson("chart.xyaxis.line", L10n.text("趋势"), L10n.text("按周、月或年观察变化。先看自己一段时间的走势，不必只盯着某一次高低。"))
                        case 1:
                            lesson("calendar", L10n.text("按日期查找"), L10n.text("在心电记录上方轻点日历，直接找到某一天，再切换前一天或后一天。"))
                            lesson("arrow.up.right", L10n.text("打开记录"), L10n.text("轻点整张卡片查看详情。右上角的箭头表示可以进入下一页。"))
                            lesson("exclamationmark.circle", L10n.text("需要留意的提示"), L10n.text("Apple 提示心率偏高、偏低或房颤时，卡片会突出显示。进入详情可查看原始分类和测量结果。"))
                        case 2:
                            lesson("waveform.path.ecg", L10n.text("原始心电图"), L10n.text("轻点右上角可横屏全屏查看。顶部标出测得的波段与间隔，轻点可查看时长；也能放大或用尺子选择两点测量。"))
                            lesson("plus", L10n.text("分段测量与波形对比"), L10n.text("轻点模块右上角的加号展开。分段测量提供参考范围和偏离原因；波形对比帮助你看清心跳的形状。"))
                            lesson("heart.text.clipboard", L10n.text("节律分析"), L10n.text("查看心跳间隔、节奏变化和提前出现的心跳线索。自动分析只能帮助回看，不能代替诊断。"))
                        default:
                            lesson("chart.dots.scatter", L10n.text("本次 ECG 的 HRV"), L10n.text("30 秒心电也能估算 HRV。聚集图中每个点代表相邻的两次心跳间隔；越集中，间隔越接近，并非越集中就越健康。"))
                            lesson("note.text", L10n.text("备忘与分享"), L10n.text("记下运动、睡眠或不适，帮助理解测量时的状态。需要时可导出报告。"))
                            lesson("info.circle", L10n.text("随时再看"), L10n.text("模块旁的信息按钮有更详细的说明。也可以在设置中重新打开使用指南。"))
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
