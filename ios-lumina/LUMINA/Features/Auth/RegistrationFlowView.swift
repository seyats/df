import SwiftUI

// MARK: - Поток регистрации
struct RegistrationFlowView: View {
    @Environment(AuthService.self) private var authService
    @State private var phone = ""
    @State private var countryCode = "+7"
    @State private var otpCode = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var birthday = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    @State private var pinCode = ""
    @State private var confirmPinCode = ""
    @State private var showPassword = false
    @State private var showUsernameEntry = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var usernameSuggestions: [String] = []

    var body: some View {
        NavigationStack {
            Group {
                switch authService.registrationStep {
                case .welcome:
                    WelcomeView()
                case .phoneInput:
                    PhoneInputView(
                        phone: $phone,
                        countryCode: $countryCode,
                        isLoading: $isLoading,
                        onContinue: { requestOTP() },
                        errorMessage: errorMessage
                    )
                case .otp:
                    OTPView(
                        code: $otpCode,
                        phone: "\(countryCode)\(phone.sanitizedPhone)",
                        isLoading: $isLoading,
                        onVerify: { verifyOTP() },
                        onResend: { requestOTP() }
                    )
                case .nameInput:
                    NameInputView(
                        name: $fullName,
                        onContinue: { authService.registrationStep = .usernameInput }
                    )
                case .usernameInput:
                    UsernameInputView(
                        username: $username,
                        suggestions: usernameSuggestions,
                        isLoading: $isLoading,
                        onContinue: { authService.registrationStep = .passwordInput }
                    )
                case .passwordInput:
                    PasswordInputView(
                        password: $password,
                        showPassword: $showPassword,
                        onContinue: { authService.registrationStep = .birthday }
                    )
                case .birthday:
                    BirthdayView(
                        date: $birthday,
                        onContinue: { authService.registrationStep = .pinCreate }
                    )
                case .pinCreate:
                    PINCreateView(
                        pin: $pinCode,
                        mode: .create,
                        onComplete: { finishRegistration() }
                    )
                case .onboarding:
                    OnboardingView(onComplete: {
                        authService.registrationStep = .complete
                    })
                case .complete:
                    RootView()
                }
            }
            .background(LuminaColor.backgroundMain)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authService.registrationStep)
        }
    }

    // MARK: - Actions
    private func requestOTP() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fullPhone = countryCode + phone.sanitizedPhone
                try await AuthService.shared.requestOTP(phone: fullPhone)
                await MainActor.run {
                    isLoading = false
                    authService.registrationStep = .otp
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func verifyOTP() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fullPhone = countryCode + phone.sanitizedPhone
                try await AuthService.shared.verifyOTP(phone: fullPhone, code: otpCode)
                await MainActor.run {
                    isLoading = false
                    authService.registrationStep = .nameInput
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func finishRegistration() {
        Task {
            do {
                try await AuthService.shared.completeRegistration(
                    fullName: fullName,
                    username: username,
                    password: password,
                    birthday: birthday,
                    pinCode: pinCode
                )
                await MainActor.run {
                    authService.registrationStep = .onboarding
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RegistrationFlowView()
        .environment(AuthService.shared)
}
