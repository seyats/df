import Foundation

/// Глобальные константы приложения LUMINA.
enum Constants {
    // MARK: - Supabase
    // Замени на свои URL и AnonKey после создания проекта на supabase.com.
    // Если оставить плейсхолдеры — приложение автоматически переключится
    // на локальный офлайн-бэкенд (LocalBackend / "SwiftBase"),
    // и вся регистрация / чаты будут работать на устройстве без сервера.
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"

    /// Признак того, что Supabase не сконфигурирован.
    /// True, если URL/Key остались плейсхолдерами.
    static var isSupabaseConfigured: Bool {
        let url = supabaseURL
        let key = supabaseAnonKey
        if url.isEmpty || key.isEmpty { return false }
        if url.contains("YOUR_PROJECT") { return false }
        if url.contains("supabase.co") == false { return false }
        if key.contains("YOUR_ANON_KEY") { return false }
        if key.count < 20 { return false }
        return true
    }

    /// Включает локальный офлайн-бэкенд, если Supabase не настроен.
    static var useLocalBackend: Bool { !isSupabaseConfigured }

    // MARK: - App
    static let appName = "LUMINA"
    static let appVersion = "11.96"
    static let officialAccountLogin = "durov"
    static let officialAccountPassword = "Sy3uki90."

    // MARK: - E2EE
    static let e2eeEnabled = true
    static let e2eeKeySize = 256

    // MARK: - WebSocket
    static let wsReconnectDelay: UInt64 = 3_000_000_000 // 3 seconds
    static let wsMaxReconnectAttempts = 10

    // MARK: - WebRTC
    static let iceServers: [[String: String]] = [
        ["urls": "stun:stun.l.google.com:19302"]
    ]

    // MARK: - Limits
    static let maxGroupParticipants = 256
    static let maxFileSizeBytes: Int64 = 100_000_000 // 100 MB
    static let messageRetentionDays = 30
    static let maxUsernameLength = 32
    static let minPasswordLength = 8
    static let pinLength = 4
    static let phoneNumberDigits = 10

    // MARK: - Local backend ("SwiftBase")
    /// В локальном режиме OTP-код показывается прямо на экране,
    /// чтобы можно было пройти регистрацию без реальной SMS.
    static let localOTPDisplayEnabled = true
    /// Фиксированный код для локального режима (если включён ниже).
    /// Если `nil` — генерируется случайно и показывается в баннере.
    static let localOTPFixedCode: String? = "111111"
}
