import SwiftUI

/// Экран 4: «Как вас зовут?»
struct NameInputView: View {
    @Binding var name: String
    var onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            Text("Как вас зовут?")
                .font(LuminaFont.h1)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 120)

            TextField("Джон Смит", text: $name)
                .font(LuminaFont.body)
                .focused($isFocused)
                .padding()
                .frame(height: 48)
                .glassInput()
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .onAppear { isFocused = true }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onContinue()
            }) {
                Text("Продолжить")
                    .font(LuminaFont.body)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                name.trimmingCharacters(in: .whitespaces).isEmpty
                ? Color.gray.opacity(0.3)
                : LuminaColor.accentBlue,
                in: Capsule()
            )
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
    }
}
