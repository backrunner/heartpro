import SwiftUI

/// Content stays on the page; Liquid Glass is reserved for its floating controls.
struct OnboardingBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            HP.canvas
            if !reduceTransparency {
                RadialGradient(colors: [HP.coral.opacity(0.10), .clear], center: .topTrailing,
                               startRadius: 0, endRadius: 360)
                RadialGradient(colors: [HP.teal.opacity(0.05), .clear], center: .bottomLeading,
                               startRadius: 0, endRadius: 280)
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct OnboardingActionBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        controls
            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 12)
            .frame(maxWidth: 560).frame(maxWidth: .infinity)
            .background {
                // A quiet fade keeps scrolled text from competing with the controls.
                LinearGradient(stops: [.init(color: HP.canvas.opacity(0), location: 0),
                                       .init(color: HP.canvas, location: 0.18)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
    }

    @ViewBuilder private var controls: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) { content }
        } else { content }
    }
}

struct OnboardingButtonStyle: ViewModifier {
    var prominent = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26.0, *), !reduceTransparency {
                if prominent { content.buttonStyle(.glassProminent) }
                else { content.buttonStyle(.glass) }
            } else {
                if prominent { content.buttonStyle(.borderedProminent) }
                else { content.buttonStyle(.bordered) }
            }
        }.buttonBorderShape(.capsule).controlSize(.large)
    }
}
