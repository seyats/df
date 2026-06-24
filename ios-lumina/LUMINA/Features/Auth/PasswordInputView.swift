import SwiftUI

/// Экран 6: «Придумайте пароль»
struct PasswordInputView: View {
    @Binding var password: String
    @Binding var showPassword: Bool
    var onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)

            Text("Придумайте пароль")
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 60)

            Text("Пароль должен быть сложным для угадывания и содержать минимум 8 символов.")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Поле ввода
            HStack {
                if showPassword {
                    TextField("Пароль", text: $password)
                } else {
                    SecureField("Пароль", text: $password)
                }
                Button(action: {
                    showPassword.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: showPassword ? "eye" : "eye.slash")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)
                }
            }
            .font(LuminaFont.body)
            .focused($isFocused)
            .padding()
            .frame(height: 56)
            .glassInput()
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .onAppear { isFocused = true }

            // Индикатор сложности
            if !password.isEmpty {
                HStack(spacing: 4) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(passwordStrength >= i + 1
                                  ? (i < 2 ? Color.red : i < 3 ? Color.orange : Color.green)
                                  : Color.gray.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
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
                password.isValidPassword ? LuminaColor.accentBlue : Color.gray.opacity(0.3),
                in: Capsule()
            )
            .disabled(!password.isValidPassword)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
    }

    private var passwordStrength: Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters) != nil { score += 1 }
        return score
    }
}
