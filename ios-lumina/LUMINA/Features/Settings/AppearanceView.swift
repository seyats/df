import SwiftUI

enum AppearanceOption: String, CaseIterable {
    case system = "System"
    case day = "Day"
    case night = "Night"

    var icon: String {
        switch self {
        case .system: return "moon.circle.fill"
        case .day: return "sun.max.fill"
        case .night: return "moon.fill"
        }
    }
}

/// Appearance screen - exact match to screenshots (iOS 26 liquid glass)
struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAppearance: AppearanceOption = .system
    @State private var textSize: Double = 0.5   // 0.0 small ... 1.0 large

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Three option cards - frosted glass (split to help type checker)
                    HStack(spacing: 12) {
                        AppearanceOptionCard(option: .system, isSelected: selectedAppearance == .system) {
                            selectedAppearance = .system
                        }
                        AppearanceOptionCard(option: .day, isSelected: selectedAppearance == .day) {
                            selectedAppearance = .day
                        }
                        AppearanceOptionCard(option: .night, isSelected: selectedAppearance == .night) {
                            selectedAppearance = .night
                        }
                    }
                    .padding(.horizontal, 16)

                    // Text Size
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Text Size")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 16) {
                            // Slider with labels
                            HStack {
                                Text("A")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                Slider(value: $textSize, in: 0...1)
                                    .tint(LuminaColor.accentBlue)
                                Text("A")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 8)

                            // Preview bubbles - matches screenshot
                            VStack(spacing: 10) {
                                HStack {
                                    Spacer()
                                    Text("Hey, how's it going?")
                                        .font(.system(size: 15 + CGFloat(textSize * 6)))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(LuminaColor.accentBlue)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }

                                HStack {
                                    Text("Pretty good, thanks! How about you?")
                                        .font(.system(size: 15 + CGFloat(textSize * 6)))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray5))
                                        .foregroundStyle(.primary)
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .glassCard(radius: 20)

                            Text("Preview")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .glassCard(radius: 18)
                    }
                }
                .padding(.top, 8)
            }
            .background(LuminaColor.backgroundMain.ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(LuminaColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .glassCircle()
                    }
                }
            }
        }
    }
}

#Preview {
    AppearanceView()
}

// Helper view to avoid complex type-checking in the main body
struct AppearanceOptionCard: View {
    let option: AppearanceOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(isSelected ? LuminaColor.accentBlue : .primary)

                Text(option.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(
                isSelected ? Color.white.opacity(0.9) : .ultraThinMaterial
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? LuminaColor.accentBlue.opacity(0.6) : Color.white.opacity(0.25),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}