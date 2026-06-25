import SwiftUI

/// Glass-like material effects compatible with iOS 17+.
/// Future .glassEffect APIs removed to allow compilation on current Xcode / iOS 17 deployment target.
struct GlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct GlassCapsuleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
    }
}

struct GlassCircleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
    }
}

struct GlassInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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

    func glassInput() -> some View {
        modifier(GlassInputModifier())
    }
}
