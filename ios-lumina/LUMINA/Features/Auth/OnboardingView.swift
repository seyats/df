import SwiftUI

/// Экран 9: «Добро пожаловать в LUMINA» (Онбординг)
struct OnboardingView: View {
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("Добро пожаловать в LUMINA")
                .font(LuminaFont.h1)
                .foregroundStyle(LuminaColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            // Три фичи
            VStack(spacing: 28) {
                OnboardingFeature(
                    icon: "lock.fill",
                    title: "Сквозное шифрование",
                    description: "Ваши сообщения защищены. Только вы и получатель можете их прочитать."
                )
                OnboardingFeature(
                    icon: "shield.checkerboard",
                    title: "Полная приватность",
                    description: "Никаких логов, никакой слежки. Ваши данные принадлежат только вам."
                )
                OnboardingFeature(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Звонки и сообщения",
                    description: "Аудио и видеозвонки высочайшего качества, мгновенные сообщения."
                )
            }
            .padding(.top, 48)
            .padding(.horizontal, 24)

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onComplete()
                }
            }) {
                Text("Начать")
                    .font(LuminaFont.body)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LuminaColor.accentBlue, in: Capsule())
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(LuminaColor.accentBlue)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LuminaFont.body)
                    .foregroundStyle(LuminaColor.textPrimary)

                Text(description)
                    .font(LuminaFont.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(16)
        .glassRounded(16)
    }
}
