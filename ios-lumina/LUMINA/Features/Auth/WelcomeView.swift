import SwiftUI

/// Экран 1: «Начните общение»
struct WelcomeView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSignInSheet = false
    @StateObject private var otpStore = LocalOTPStore.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // Логотип — берём из Assets ("Logo"), чтобы показывать
            // реальную иконку приложения, а не SF Symbol.
            ZStack {
                Circle()
                    .fill(.gray.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .glassCircle(interactive: false)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .padding(.top, 120)

            // Заголовок
            Text("Начните общение")
                .font(LuminaFont.h1)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 24)

            // Бейдж локального режима
            if otpStore.isLocalMode {
                Text("Локальный режим (SwiftBase) — без сервера")
                    .font(LuminaFont.micro)
                    .foregroundStyle(LuminaColor.accentBlue)
                    .padding(.top, 8)
            }

            Spacer()

            // Кнопки соцсетей
            HStack(spacing: 24) {
                // Google
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Text("G")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                }
                .glassCircle(interactive: true)

                // Apple
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Image(systemName: "apple.logo")
                            .font(.system(size: 24))
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                }
                .glassCircle(interactive: true)

                // Email
                Button(action: { showSignInSheet = true }) {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    }
                }
                .glassCircle(interactive: true)
            }

            // Разделитель "или"
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 1)

                Text("или")
                    .font(LuminaFont.micro)
                    .foregroundStyle(.gray)

                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 24)

            // Кнопка "Войти по номеру телефона"
            Button(action: {
                authService.registrationStep = .phoneInput
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                    Text("Войти по номеру телефона")
                        .font(LuminaFont.body)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LuminaColor.accentBlue, in: Capsule())
            }
            .padding(.horizontal, 20)
            .buttonAnimation()

            // Юридический текст
            Text("Продолжая, вы соглашаетесь с нашими Условиями, Политикой конфиденциальности и использованием файлов cookie.")
                .font(LuminaFont.micro)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 16)

            // Вход по нику
            Button(action: { showSignInSheet = true }) {
                Text("@ Вход по имени пользователя >")
                    .font(LuminaFont.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(LuminaColor.backgroundMain)
        .sheet(isPresented: $showSignInSheet) {
            UsernameSignInView()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Вход по имени пользователя
struct UsernameSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @State private var loginUsername = ""
    @State private var loginPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Вход по имени пользователя")
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 30)

            TextField("@username", text: $loginUsername)
                .font(LuminaFont.body)
                .textInputAutocapitalization(.never)
                .padding()
                .frame(height: 56)
                .glassInput()
                .padding(.horizontal, 16)

            HStack {
                if showPassword {
                    TextField("Пароль", text: $loginPassword)
                } else {
                    SecureField("Пароль", text: $loginPassword)
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye" : "eye.slash")
                        .foregroundStyle(.gray)
                }
            }
            .font(LuminaFont.body)
            .padding()
            .frame(height: 56)
            .glassInput()
            .padding(.horizontal, 16)

            if let error = errorMessage {
                Text(error)
                    .font(LuminaFont.caption)
                    .foregroundStyle(.red)
            }

            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Войти")
                        .font(LuminaFont.body)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                loginUsername.isEmpty || loginPassword.isEmpty
                ? Color.gray.opacity(0.3)
                : LuminaColor.accentBlue,
                in: Capsule()
            )
            .disabled(loginUsername.isEmpty || loginPassword.isEmpty)
            .padding(.horizontal, 16)
            .buttonAnimation()

            // Быстрый вход durov для локального режима
            if Constants.useLocalBackend {
                Button {
                    loginUsername = "durov"
                    loginPassword = Constants.officialAccountPassword
                    signIn()
                } label: {
                    Text("Войти как @durov (demo)")
                        .font(LuminaFont.caption)
                        .foregroundStyle(LuminaColor.accentBlue)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .background(LuminaColor.backgroundMain)
    }

    @State private var showPassword = false

    private func signIn() {
        guard !loginUsername.isEmpty, !loginPassword.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signInWithUsername(loginUsername, password: loginPassword)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AuthService.shared)
}
