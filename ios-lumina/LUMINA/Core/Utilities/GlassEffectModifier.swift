import SwiftUI

/// Liquid Glass (iOS 26/27 style) - frosted, blurred, premium translucent cards.
/// Matches the screenshots: soft white frosted panels, subtle borders, generous radius.
struct GlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 5)
    }
}

struct GlassCapsuleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
    }
}

struct GlassCircleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.09), radius: 9, x: 0, y: 3)
    }
}

struct GlassCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.055), radius: 18, x: 0, y: 7)
    }
}

struct GlassInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassRounded(_ radius: CGFloat = 16, interactive: Bool = false) -> some View {
        modifier(GlassModifier(cornerRadius: radius, interactive: interactive))
    }

    func glassCapsule(interactive: Bool = true) -> some View {
        modifier(GlassCapsuleModifier(interactive: interactive))
    }

    func glassCircle(interactive: Bool = true) -> some View {
        modifier(GlassCircleModifier(interactive: interactive))
    }

    func glassCard(radius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }

    func glassInput() -> some View {
        modifier(GlassInputModifier())
    }

    /// Glass toolbar / nav bar background - strong frosted
    func glassToolbar() -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5),
                alignment: .bottom
            )
    }
}
