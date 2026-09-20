import SwiftUI
import HeartProCore

struct AuthorizationLandingView: View {
    var isConnecting: Bool
    var connect: () -> Void
    var enterDemo: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    Image("BrandMark").resizable().scaledToFit().frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    Text(L10n.text("更了解自己的心跳"))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                    Text(L10n.text("把 Apple 健康里的记录放在一起，轻松回看每天的变化。"))
                        .font(.body).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 22) {
                    feature("heart", title: L10n.text("日常心率"),
                            detail: L10n.text("查看每天的心跳快慢和长期变化。"))
                    feature("waveform.path.ecg", title: L10n.text("心电记录"),
                            detail: L10n.text("按日期查找，放大看清每次心电图。"))
                    feature("chart.xyaxis.line", title: L10n.text("心率变异性（HRV）"),
                            detail: L10n.text("了解心跳间隔的变化，和过去的自己比较。"))
                }

                Text(L10n.text("下一步会请你允许读取这三类记录，你可以分别选择。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text("仅供参考，不能替代医生诊断。"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
            .frame(maxWidth: 560, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(OnboardingBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            OnboardingActionBar {
                VStack(spacing: 12) {
                    Button(action: connect) {
                        HStack(spacing: 9) {
                            if isConnecting { ProgressView().tint(.white).controlSize(.small) }
                            else { Image(systemName: "heart.fill") }
                            Text(isConnecting ? L10n.text("正在连接…") : L10n.text("连接 Apple 健康"))
                        }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 5)
                    }
                    .modifier(OnboardingButtonStyle(prominent: true))
                    .disabled(isConnecting).accessibilityIdentifier("connectHealth")
                    .accessibilityHint(L10n.text("下一步会请你允许读取这三类记录，你可以分别选择。"))

                    Button(action: enterDemo) {
                        Text(L10n.text("先看看示例")).font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 3)
                    }
                    .modifier(OnboardingButtonStyle())
                    .foregroundStyle(.primary).disabled(isConnecting).accessibilityIdentifier("enterDemo")

                    Label(L10n.text("数据留在你的设备上"), systemImage: "lock")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func feature(_ icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 20, weight: .medium))
                .foregroundStyle(HP.coral).frame(width: 42, height: 42)
                .background(HP.coral.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
    }
}
