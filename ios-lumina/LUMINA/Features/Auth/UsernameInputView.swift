import SwiftUI

/// Экран 5: «Придумайте имя пользователя»
struct UsernameInputView: View {
    @Binding var username: String
    let suggestions: [String]
    @Binding var isLoading: Bool
    var onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            Text("Придумайте имя пользователя")
                .font(LuminaFont.h1)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 80)

            HStack(spacing: 4) {
                Text("@")
                    .font(LuminaFont.body)
                    .foregroundStyle(.gray)
                TextField("AlexSmithwlt0", text: $username)
                    .font(LuminaFont.body)
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
            }
            .padding()
            .frame(height: 48)
            .glassInput()
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .onAppear { isFocused = true }

            // Чипсы с вариантами
            if !suggestions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: { username = suggestion }) {
                            Text("@\(suggestion)")
                                .font(LuminaFont.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Color.gray.opacity(0.15),
                                    in: Capsule()
                                )
                                .foregroundStyle(LuminaColor.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

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
                username.isValidUsername ? LuminaColor.accentBlue : Color.gray.opacity(0.3),
                in: Capsule()
            )
            .disabled(!username.isValidUsername)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
    }
}
