import SwiftUI

/// Эффект Liquid Glass для iOS 26+ с fallback на ultraThinMaterial.
struct GlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

struct GlassCapsuleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

struct GlassCircleModifier: ViewModifier {
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

struct GlassInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
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
