import Foundation

/// Сервис HTTP API.
///
/// Если Supabase сконфигурирован (`Constants.isSupabaseConfigured == true`),
/// все запросы идут в Supabase REST. Если нет — автоматически используется
/// локальный офлайн-бэкенд `LocalBackend` ("SwiftBase"), и приложение
/// работает полностью на устройстве без сервера.
///
/// В локальном режиме:
///  - Регистрация / OTP / вход / чаты / сообщения сохраняются в
///    `Documents/lumina_local_backend.json`.
///  - Сгенерированный OTP-код возвращается наверх, чтобы UI мог его показать
///    (см. `LocalOTPStore`).
final class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let anonKey: String
    private let useLocal: Bool

    private init() {
        baseURL = Constants.supabaseURL
        anonKey = Constants.supabaseAnonKey
        useLocal = Constants.useLocalBackend
    }

    // MARK: - JSON helpers (snake_case ↔ camelCase для Supabase)
    private var supabaseDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            // Supabase возвращает ISO8601 с миллисекундами.
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: s) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: s) { return date }
            return Date()
        }
        return d
    }

    private var supabaseEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(formatter.string(from: date))
        }
        return e
    }

    // MARK: - Supabase REST
    private func request(
        _ path: String,
        method: String = "GET",
        body: Data? = nil,
        auth: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(path)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if auth, let token = KeychainService.shared.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = body
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        return (data, httpResponse)
    }

    private func rpc(_ function: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/rpc/\(function)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = KeychainService.shared.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        return data
    }

    // MARK: - Auth
    func signUp(phone: String, password: String) async throws -> UserModel {
        if useLocal {
            let (user, token) = try await LocalBackend.shared.signUp(phone: phone, password: password)
            KeychainService.shared.authToken = token
            KeychainService.shared.currentUserID = user.id
            return user
        }
        let body: [String: Any] = ["phone": phone, "password": password]
        let (data, _) = try await request("auth/signup", method: "POST",
                                          body: JSONSerialization.data(withJSONObject: body), auth: false)
        struct AuthResponse: Codable {
            let user: UserModel
            let accessToken: String
            let refreshToken: String?
        }
        let resp = try supabaseDecoder.decode(AuthResponse.self, from: data)
        KeychainService.shared.authToken = resp.accessToken
        if let rt = resp.refreshToken { KeychainService.shared.refreshToken = rt }
        KeychainService.shared.currentUserID = resp.user.id
        return resp.user
    }

    func signIn(phone: String, password: String) async throws -> UserModel {
        if useLocal {
            let (user, token) = try await LocalBackend.shared.signIn(phone: phone, password: password)
            KeychainService.shared.authToken = token
            KeychainService.shared.currentUserID = user.id
            return user
        }
        let body: [String: Any] = ["phone": phone, "password": password]
        let (data, _) = try await request("auth/signin", method: "POST",
                                          body: JSONSerialization.data(withJSONObject: body), auth: false)
        struct AuthResponse: Codable {
            let user: UserModel
            let accessToken: String
            let refreshToken: String?
        }
        let resp = try supabaseDecoder.decode(AuthResponse.self, from: data)
        KeychainService.shared.authToken = resp.accessToken
        if let rt = resp.refreshToken { KeychainService.shared.refreshToken = rt }
        KeychainService.shared.currentUserID = resp.user.id
        return resp.user
    }

    func signInWithUsername(_ username: String, password: String) async throws -> UserModel {
        if useLocal {
            let (user, token) = try await LocalBackend.shared.signInWithUsername(username, password: password)
            KeychainService.shared.authToken = token
            KeychainService.shared.currentUserID = user.id
            return user
        }
        let body: [String: Any] = ["username": username, "password": password]
        let (data, _) = try await request("auth/signin_username", method: "POST",
                                          body: JSONSerialization.data(withJSONObject: body), auth: false)
        struct AuthResponse: Codable {
            let user: UserModel
            let accessToken: String
            let refreshToken: String?
        }
        let resp = try supabaseDecoder.decode(AuthResponse.self, from: data)
        KeychainService.shared.authToken = resp.accessToken
        if let rt = resp.refreshToken { KeychainService.shared.refreshToken = rt }
        KeychainService.shared.currentUserID = resp.user.id
        return resp.user
    }

    /// В локальном режиме возвращает код OTP, который UI должен показать.
    func requestOTP(phone: String) async throws -> String? {
        if useLocal {
            return await LocalBackend.shared.requestOTP(phone: phone)
        }
        let body = ["phone": phone]
        let _ = try await request("auth/otp", method: "POST",
                                  body: JSONSerialization.data(withJSONObject: body), auth: false)
        return nil
    }

    func verifyOTP(phone: String, code: String) async throws -> UserModel {
        if useLocal {
            let (user, token) = try await LocalBackend.shared.verifyOTP(phone: phone, code: code)
            KeychainService.shared.authToken = token
            KeychainService.shared.currentUserID = user.id
            return user
        }
        let body = ["phone": phone, "code": code]
        let (data, _) = try await request("auth/verify_otp", method: "POST",
                                          body: JSONSerialization.data(withJSONObject: body), auth: false)
        struct AuthResponse: Codable {
            let user: UserModel
            let accessToken: String
            let refreshToken: String?
        }
        let resp = try supabaseDecoder.decode(AuthResponse.self, from: data)
        KeychainService.shared.authToken = resp.accessToken
        if let rt = resp.refreshToken { KeychainService.shared.refreshToken = rt }
        KeychainService.shared.currentUserID = resp.user.id
        return resp.user
    }

    func updateProfile(fullName: String? = nil, username: String? = nil, bio: String? = nil) async throws -> UserModel {
        guard let userID = KeychainService.shared.currentUserID else { throw APIError.unauthorized }
        if useLocal {
            return try await LocalBackend.shared.updateProfile(userID: userID,
                                                                fullName: fullName,
                                                                username: username,
                                                                bio: bio)
        }
        var body: [String: Any] = [:]
        if let n = fullName { body["full_name"] = n }
        if let u = username { body["username"] = u }
        if let b = bio { body["bio"] = b }
        let (data, _) = try await request("profiles?id=eq.\(userID)", method: "PATCH",
                                          body: JSONSerialization.data(withJSONObject: body))
        return try supabaseDecoder.decode(UserModel.self, from: data)
    }

    /// Обновляет push-токен (только для Supabase-режима).
    func updatePushToken(body: [String: Any]) async throws {
        guard !useLocal else { return }
        let _ = try await request("profiles/push_token", method: "PATCH",
                                  body: JSONSerialization.data(withJSONObject: body))
    }

    // MARK: - Chats
    func fetchChats() async throws -> [ChatModel] {
        guard let userID = KeychainService.shared.currentUserID else { throw APIError.unauthorized }
        if useLocal {
            return await LocalBackend.shared.fetchChats(userID: userID)
        }
        let (data, _) = try await request("chats?participant_id=eq.\(userID)&order=last_message_time.desc")
        return try supabaseDecoder.decode([ChatModel].self, from: data)
    }

    func createChat(participantIDs: [String], type: String = "direct", name: String? = nil) async throws -> ChatModel {
        guard let creatorID = KeychainService.shared.currentUserID else { throw APIError.unauthorized }
        if useLocal {
            return try await LocalBackend.shared.createChat(participantIDs: participantIDs,
                                                             type: type,
                                                             name: name,
                                                             creatorID: creatorID)
        }
        let body: [String: Any] = [
            "type": type,
            "participants": participantIDs,
            "name": name as Any
        ]
        let (data, _) = try await request("chats", method: "POST",
                                          body: JSONSerialization.data(withJSONObject: body))
        return try supabaseDecoder.decode(ChatModel.self, from: data)
    }

    func fetchMessages(chatID: String, limit: Int = 50, before: Date? = nil) async throws -> [MessageModel] {
        if useLocal {
            return await LocalBackend.shared.fetchMessages(chatID: chatID, limit: limit)
        }
        var path = "messages?chat_id=eq.\(chatID)&order=created_at.desc&limit=\(limit)"
        if let before = before {
            path += "&created_at=lt.\(ISO8601DateFormatter().string(from: before))"
        }
        let (data, _) = try await request(path)
        return try supabaseDecoder.decode([MessageModel].self, from: data)
    }

    /// Локально сохраняет сообщение. В Supabase-режиме сообщение отправляется
    /// через WebSocket (см. SocketService).
    func sendMessage(_ message: MessageModel) async throws -> MessageModel {
        if useLocal {
            return try await LocalBackend.shared.sendMessage(message)
        }
        let body = try supabaseEncoder.encode(message)
        let (data, _) = try await request("messages", method: "POST", body: body)
        return try supabaseDecoder.decode(MessageModel.self, from: data)
    }

    // MARK: - Users
    func fetchUser(userID: String) async throws -> UserModel {
        if useLocal {
            return try await LocalBackend.shared.fetchUser(userID: userID)
        }
        let (data, _) = try await request("profiles?id=eq.\(userID)")
        let users = try supabaseDecoder.decode([UserModel].self, from: data)
        guard let user = users.first else { throw APIError.notFound }
        return user
    }

    func searchUsers(query: String) async throws -> [UserModel] {
        if useLocal {
            return await LocalBackend.shared.searchUsers(query: query)
        }
        let (data, _) = try await request("profiles?username=ilike.*\(query)*&limit=20")
        return try supabaseDecoder.decode([UserModel].self, from: data)
    }

    func blockUser(userID: String) async throws {
        if useLocal { return }
        let body = ["blocked_user_id": userID]
        let _ = try await request("blocks", method: "POST",
                                  body: JSONSerialization.data(withJSONObject: body))
    }

    func unblockUser(userID: String) async throws {
        if useLocal { return }
        let _ = try await request("blocks?blocked_user_id=eq.\(userID)", method: "DELETE")
    }

    // MARK: - Admin
    func adminFetchAllUsers() async throws -> [UserModel] {
        if useLocal {
            return await LocalBackend.shared.searchUsers(query: "")
        }
        let (data, _) = try await request("admin/users")
        return try supabaseDecoder.decode([UserModel].self, from: data)
    }

    func adminDeleteUser(userID: String) async throws {
        if useLocal { return }
        let _ = try await request("admin/users?id=eq.\(userID)", method: "DELETE")
    }

    func adminFetchReports() async throws -> [ReportModel] {
        if useLocal { return [] }
        let (data, _) = try await request("admin/reports")
        return try supabaseDecoder.decode([ReportModel].self, from: data)
    }

    func adminResolveReport(reportID: String, action: String) async throws {
        if useLocal { return }
        let body = ["action": action]
        let _ = try await request("admin/reports?id=eq.\(reportID)", method: "PATCH",
                                  body: JSONSerialization.data(withJSONObject: body))
    }

    func adminGetStats() async throws -> [String: Any] {
        if useLocal {
            return [
                "users": await LocalBackend.shared.searchUsers(query: "").count,
                "chats": 0,
                "messages": 0
            ]
        }
        let (data, _) = try await request("admin/stats")
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    func adminSendMassNotification(title: String, body: String, target: String) async throws {
        if useLocal { return }
        let payload: [String: Any] = ["title": title, "body": body, "target": target]
        let _ = try await rpc("send_mass_notification", body: payload)
    }
}

// MARK: - Local OTP delivery
/// В локальном режиме код OTP не отправляется по SMS — он показывается на экране.
/// Этот объект хранит последний сгенерированный код, чтобы UI мог его отобразить.
@MainActor
final class LocalOTPStore: ObservableObject {
    static let shared = LocalOTPStore()
    @Published var lastCode: String?
    @Published var lastPhone: String?
    @Published var isLocalMode: Bool = Constants.useLocalBackend
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .invalidResponse: return "Ошибка сервера"
        case .notFound: return "Не найдено"
        case .unauthorized: return "Не авторизован"
        }
    }
}
