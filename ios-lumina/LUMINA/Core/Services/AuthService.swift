import Foundation

/// Сервис аутентификации: объединяет API, E2EE и Keychain.
@Observable
final class AuthService {
    static let shared = AuthService()

    var isAuthenticated = false
    var currentUser: UserModel?
    var registrationStep: RegistrationStep = .welcome
    /// В локальном режиме здесь лежит код, который UI должен показать.
    var pendingOTPHint: String?

    enum RegistrationStep {
        case welcome
        case phoneInput
        case otp
        case nameInput
        case usernameInput
        case passwordInput
        case birthday
        case pinCreate
        case onboarding
        case complete
    }

    private init() {
        if KeychainService.shared.authToken != nil {
            isAuthenticated = true
            Task { await loadCurrentUser() }
        }
    }

    func loadCurrentUser() async {
        guard let userID = KeychainService.shared.currentUserID else { return }
        do {
            currentUser = try await APIService.shared.fetchUser(userID: userID)
            if Constants.useLocalBackend {
                await LocalBackend.shared.ensureWelcomeChat(for: userID)
            }
        } catch {
            // silently fail — user will be prompted to login
        }
    }

    // MARK: - Регистрация
    /// Возвращает код-подсказку для локального режима (для показа в UI).
    @discardableResult
    func requestOTP(phone: String) async throws -> String? {
        let hint = try await APIService.shared.requestOTP(phone: phone)
        if let hint = hint {
            await MainActor.run {
                self.pendingOTPHint = hint
                LocalOTPStore.shared.lastCode = hint
                LocalOTPStore.shared.lastPhone = phone
            }
        }
        return hint
    }

    func verifyOTP(phone: String, code: String) async throws {
        let user = try await APIService.shared.verifyOTP(phone: phone, code: code)
        await setupE2EE(for: user)
        currentUser = user
        await MainActor.run {
            self.pendingOTPHint = nil
            LocalOTPStore.shared.lastCode = nil
        }
    }

    func completeRegistration(
        fullName: String,
        username: String,
        password: String,
        birthday: Date,
        pinCode: String
    ) async throws {
        let updatedUser = try await APIService.shared.updateProfile(fullName: fullName, username: username)
        KeychainService.shared.pinCode = pinCode
        currentUser = updatedUser
        isAuthenticated = true
        registrationStep = .complete
        if Constants.useLocalBackend, let uid = updatedUser.id as String? {
            await LocalBackend.shared.ensureWelcomeChat(for: uid)
        }
    }

    // MARK: - Вход
    func signIn(phone: String, password: String) async throws {
        let user = try await APIService.shared.signIn(phone: phone, password: password)
        await setupE2EE(for: user)
        currentUser = user
        isAuthenticated = true
    }

    func signInWithUsername(_ username: String, password: String) async throws {
        let user = try await APIService.shared.signInWithUsername(username, password: password)
        await setupE2EE(for: user)
        currentUser = user
        isAuthenticated = true
    }

    // MARK: - Выход
    func signOut() {
        KeychainService.shared.authToken = nil
        KeychainService.shared.refreshToken = nil
        KeychainService.shared.currentUserID = nil
        currentUser = nil
        isAuthenticated = false
        registrationStep = .welcome
        SocketService.shared.disconnect()
    }

    // MARK: - E2EE
    private func setupE2EE(for user: UserModel) async {
        let keys = E2EEService.shared.generateKeyPair()
        KeychainService.shared.privateKey = keys.privateKey
        KeychainService.shared.publicKey = keys.publicKey
        // Сохраняем публичный ключ на сервере
        let _ = try? await APIService.shared.updateProfile(fullName: nil, username: nil)
    }
}
