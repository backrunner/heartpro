import SwiftUI
import HeartProCore

/// The same notice is shown to every user before the app starts reading records.
/// Acknowledgement is a reading checkpoint, not medical consent or a legal waiver.
struct UsageNoticeView: View {
    static let currentVersion = 1
    var acknowledging = true
    var onContinue: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    Surface {
                        VStack(alignment: .leading, spacing: 20) {
                            NoticeSection(
                                title: L10n.text("不能替代专业医疗"),
                                symbol: "person.text.rectangle",
                                text: L10n.text("不能替代专业医生、诊断、治疗或其他医疗服务。不要依据应用结果自行诊断、开始或停止用药，或延误就医。")
                            )
                            Divider()
                            NoticeSection(
                                title: L10n.text("分析结果有局限"),
                                symbol: "waveform.path",
                                text: L10n.text("自动分析尚未经过真实 Apple Watch 记录的独立准确度验证。高分、没有提示或缺少数值都不表示身体健康或没有风险。")
                            )
                        }
                    }
                    emergencyNotice
                    HealthReferenceLinks(references: [.appleECG], showsNotice: false)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(24).frame(maxWidth: 560, alignment: .leading).frame(maxWidth: .infinity)
                .frame(minHeight: horizontalSizeClass == .regular ? geometry.size.height : nil)
            }.scrollBounceBehavior(.basedOnSize)
        }
        .background(OnboardingBackground())
        .safeAreaInset(edge: .bottom) {
            OnboardingActionBar {
                Button(action: onContinue) {
                    HStack(spacing: 10) {
                        Text(acknowledging ? L10n.text("我已了解，继续") : L10n.text("完成"))
                            .multilineTextAlignment(.center)
                        if acknowledging {
                            Image(systemName: "arrow.right").accessibilityHidden(true)
                        }
                    }
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .modifier(OnboardingButtonStyle(prominent: true))
                .accessibilityIdentifier("acknowledgeUsageNotice")
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeartProWordmark()
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("使用前，请先了解"))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader).accessibilityIdentifier("usageNoticeTitle")
                Text(HealthInformation.intendedUseNotice)
                    .font(.body).foregroundStyle(.primary.opacity(0.78)).lineSpacing(3)
            }
        }
    }

    private var emergencyNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(HP.amber).accessibilityHidden(true)
                Text(L10n.text("不适时，请及时就医"))
                    .accessibilityAddTraits(.isHeader)
            }.font(.headline)
            Text(L10n.text("如有身体不适，请及时就医；持续胸痛、明显气短或晕厥时，请立即联系当地急救服务。不要等待应用分析，本应用不提供急救监测或提醒。"))
                .font(.callout).lineSpacing(3)
                .accessibilityIdentifier("usageNoticeEmergency")
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(HP.amber.opacity(0.08), in: RoundedRectangle(cornerRadius: HP.radius))
        .overlay(RoundedRectangle(cornerRadius: HP.radius).strokeBorder(HP.amber.opacity(0.15)))
    }
}

private struct NoticeSection: View {
    let title: String
    let symbol: String
    let text: String
    @ScaledMetric(relativeTo: .headline) private var symbolWidth: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Image(systemName: symbol).foregroundStyle(HP.coral)
                    .frame(width: symbolWidth).accessibilityHidden(true)
                Text(title).accessibilityAddTraits(.isHeader)
            }.font(.headline)
            Text(text).font(.callout).foregroundStyle(.primary.opacity(0.78)).lineSpacing(3)
        }
    }
}
