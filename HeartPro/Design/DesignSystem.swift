import SwiftUI
import HeartProCore

enum HP {
    static let coral = Color(red: 0.89, green: 0.29, blue: 0.35)
    // System red follows the light/dark palette used by Apple's health interfaces.
    static let ecg = Color(uiColor: .systemRed)
    static let teal = Color(red: 0.16, green: 0.48, blue: 0.47)
    static let amber = Color(red: 0.72, green: 0.47, blue: 0.16)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let paper = Color(uiColor: .secondarySystemGroupedBackground)
    static let caret = Color(uiColor: .secondaryLabel)
    static let radius: CGFloat = 20
}

struct AppBackground: View {
    var body: some View {
        HP.canvas.ignoresSafeArea()
    }
}

struct HeartProWordmark: View {
    var body: some View {
        HStack(spacing: 7) {
            Image("BrandMark").resizable().scaledToFit().frame(width: 30, height: 30)
            Text("HeartPro").font(.system(.headline, design: .rounded, weight: .bold))
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("HeartPro")
        .accessibilityIdentifier("brandWordmark")
    }
}

struct Surface<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(HP.paper, in: RoundedRectangle(cornerRadius: HP.radius))
            .overlay(RoundedRectangle(cornerRadius: HP.radius).strokeBorder(.primary.opacity(0.045)))
    }
}

struct GlassSurface: ViewModifier {
    var tint: Color = .clear
    var interactive = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(HP.paper, in: RoundedRectangle(cornerRadius: HP.radius))
                .overlay(RoundedRectangle(cornerRadius: HP.radius).strokeBorder(.primary.opacity(0.08)))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(interactive ? .regular.tint(tint).interactive() : .regular.tint(tint),
                                in: RoundedRectangle(cornerRadius: HP.radius))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: HP.radius))
                .overlay(RoundedRectangle(cornerRadius: HP.radius).strokeBorder(.white.opacity(0.5)))
        }
    }
}

struct GlassControlStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) { content.buttonStyle(.glass) }
        else { content.buttonStyle(.bordered) }
    }
}

struct CircularGlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label.frame(width: 44, height: 44).contentShape(Circle())
        Group {
            if reduceTransparency {
                label.background(HP.paper, in: Circle())
                    .overlay(Circle().strokeBorder(.primary.opacity(0.1)))
            } else if #available(iOS 26.0, *) {
                label.glassEffect(.regular.interactive(), in: Circle())
            } else {
                label.background(.regularMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.primary.opacity(0.08)))
            }
        }.opacity(!isEnabled ? 0.4 : configuration.isPressed ? 0.65 : 1)
            .fixedSize()
    }
}

extension View {
    func hpGlass(tint: Color = .clear, interactive: Bool = false) -> some View { modifier(GlassSurface(tint: tint, interactive: interactive)) }
    func hpGlassButton() -> some View { modifier(GlassControlStyle()) }
    func hpCircularIconButton() -> some View { buttonStyle(CircularGlassButtonStyle()) }
}

struct AnalysisSurface<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading).hpGlass()
    }
}

struct DisclosureCaret: View {
    var isExpanded = false
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(HP.caret)
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .frame(width: 16, height: 20)
            .accessibilityHidden(true)
    }
}

/// Navigation stays inside the card header, away from the waveform and metrics.
struct CardNavigationIndicator: View {
    var body: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HP.caret)
            .frame(width: 24, height: 24)
            .background(.secondary.opacity(0.07), in: Circle())
            .accessibilityHidden(true)
    }
}

/// Keep disclosure labels neutral, with an explicit adaptive caret color.
/// The identifier belongs to the button, so it is not inherited by nested controls.
struct AnalysisDisclosureStyle: DisclosureGroupStyle {
    var identifier = ""
    var inset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { configuration.isExpanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: configuration.isExpanded ? "minus" : "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HP.caret).frame(width: 24, height: 24)
                        .background(.secondary.opacity(0.07), in: Circle()).accessibilityHidden(true)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, inset).padding(.vertical, 14)
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityIdentifier(identifier)
                .accessibilityValue(configuration.isExpanded ? L10n.text("已展开") : L10n.text("已收起"))
            if configuration.isExpanded {
                configuration.content.padding(.horizontal, inset == 0 ? 0 : 10)
                    .padding(.bottom, inset == 0 ? 8 : 10)
            }
        }
    }
}

struct AnalysisInfoButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "info").font(.system(size: 15, weight: .medium))
        }.hpCircularIconButton().tint(.primary).accessibilityLabel(title)
    }
}

struct AnalysisHelpSheet<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) { content }
                    .font(.subheadline).frame(maxWidth: 680, alignment: .leading)
                    .padding(24).frame(maxWidth: .infinity)
            }.background(AppBackground()).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("完成")) { dismiss() } } }
        }
    }
}

struct SectionHeading: View {
    var title: String
    var subtitle: String? = nil
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline).fixedSize()
                Spacer()
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary).fixedSize() }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
        }.padding(.horizontal, 3)
    }
}

struct Tag: View {
    var text: String
    var icon: String? = nil
    var color: Color = HP.teal
    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }.font(.caption.weight(.medium)).padding(.horizontal, 8).padding(.vertical, 4)
            .foregroundStyle(color).background(color.opacity(0.09), in: Capsule())
    }
}

struct MetricValue: View {
    var value: String
    var unit: String = ""
    var label: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(.title2, design: .rounded, weight: .semibold)).monospacedDigit().foregroundStyle(color)
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReferenceFooter: View {
    var body: some View {
        VStack(spacing: 5) {
            Label(L10n.text("仅供记录参考，不构成医疗建议，不能替代专业医疗服务。"), systemImage: "cross.case")
            Text(L10n.text("不提供医疗建议，也不能判断心脏是否健康"))
            Text(L10n.text("请在作出医疗决定前咨询医生。"))
            HealthReferencesButton()
        }.font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 15)
    }
}

struct EmptyPanel: View {
    var icon: String = "waveform.path.ecg"
    var title: String
    var message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.horizontal, 24).padding(.vertical, 36)
    }
}

extension Double {
    var integerText: String { isFinite ? String(Int(rounded())) : "—" }
}
