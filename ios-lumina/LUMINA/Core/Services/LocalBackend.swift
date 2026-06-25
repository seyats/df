import Foundation

/// Локальный офлайн-бэкенд ("SwiftBase").
///
/// Полностью заменяет Supabase REST API, когда Supabase не сконфигурирован.
/// Все данные хранятся в виде JSON-файла в Documents-директории приложения.
/// Это позволяет пройти регистрацию, OTP, создать чаты и отправлять сообщения
/// без какого-либо сервера — эмуляция работает прямо на устройстве.
///
/// В локальном режиме:
///  - OTP-код показывается прямо на экране (см. Constants.localOTPDisplayEnabled).
///  - "Поиск пользователей" возвращает демо-аккаунты + ранее созданных локальных юзеров.
///  - Все пароли хранятся в виде простого SHA-256 хэша (только для демо).
actor LocalBackend {
    static let shared = LocalBackend()

    // MARK: - Хранилище
    private struct Store: Codable {
        var users: [UserModel] = []
        var chats: [ChatModel] = []
        var messages: [MessageModel] = []
        var otpByPhone: [String: String] = [:]
        var passwordByUserID: [String: String] = [:]
        var usernameByLowercase: [String: String] = [:] // lowercase username -> userID
        var phoneByUserID: [String: String] = [:]
    }

    private var store = Store()
    private let fileURL: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("lumina_local_backend.json")
        load()
        seedDemoDataIfNeeded()
        ensureDurovCredentials()
    }

    private func ensureDurovCredentials() {
        if store.users.contains(where: { $0.id == "durov" }) {
            if store.passwordByUserID["durov"] == nil {
                store.passwordByUserID["durov"] = sha256(Constants.officialAccountPassword)
                save()
            }
        }
    }

    // MARK: - Persistence
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(Store.self, from: data) else {
            return
        }
        store = decoded
    }

    private func save() {
        do {
            let data = try encoder.encode(store)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("[LocalBackend] save error: \(error)")
            #endif
        }
    }

    // MARK: - Seed
    private func seedDemoDataIfNeeded() {
        guard store.users.isEmpty else { return }
        let durov = UserModel(
            id: "durov",
            phone: "+70000000001",
            fullName: "Pavel Durov",
            username: "durov",
            bio: "Официальный аккаунт LUMINA",
            isVerified: true,
            isOnline: true,
            isAdmin: true
        )
        let support = UserModel(
            id: "support",
            phone: "+70000000002",
            fullName: "LUMINA Support",
            username: "support",
            bio: "Поддержка пользователей",
            isVerified: true
        )
        let demo = UserModel(
            id: "demo",
            phone: "+70000000003",
            fullName: "Demo User",
            username: "demo",
            bio: "Демо-аккаунт для тестов"
        )
        store.users = [durov, support, demo]
        store.usernameByLowercase = [
            "durov": "durov",
            "support": "support",
            "demo": "demo"
        ]
        store.phoneByUserID = [
            "durov": "+70000000001",
            "support": "+70000000002",
            "demo": "+70000000003"
        ]
        // Ensure official durov account can sign in locally with the known password
        store.passwordByUserID["durov"] = sha256(Constants.officialAccountPassword)
        save()
    }

    // MARK: - Auth
    func requestOTP(phone: String) -> String {
        let code: String
        if let fixed = Constants.localOTPFixedCode {
            code = fixed
        } else {
            code = String(format: "%06d", Int.random(in: 100000...999999))
        }
        store.otpByPhone[phone] = code
        save()
        return code
    }

    func verifyOTP(phone: String, code: String) throws -> (user: UserModel, token: String) {
        guard let expected = store.otpByPhone[phone] else {
            throw LocalBackendError.otpNotFound
        }
        guard expected == code else {
            throw LocalBackendError.invalidOTP
        }
        store.otpByPhone.removeValue(forKey: phone)

        // Найти существующего юзера или создать нового (pre-registration).
        var user: UserModel
        if let existing = store.users.first(where: { $0.phone == phone }) {
            user = existing
        } else {
            user = UserModel(
                id: UUID().uuidString,
                phone: phone,
                fullName: "",
                username: ""
            )
            store.users.append(user)
            store.phoneByUserID[user.id] = phone
        }
        save()

        let token = "local-token-\(user.id)-\(Int(Date().timeIntervalSince1970))"
        return (user, token)
    }

    func signUp(phone: String, password: String) throws -> (user: UserModel, token: String) {
        if store.users.contains(where: { $0.phone == phone }) {
            throw LocalBackendError.phoneTaken
        }
        let user = UserModel(
            id: UUID().uuidString,
            phone: phone,
            fullName: "",
            username: ""
        )
        store.users.append(user)
        store.phoneByUserID[user.id] = phone
        store.passwordByUserID[user.id] = sha256(password)
        save()
        let token = "local-token-\(user.id)-\(Int(Date().timeIntervalSince1970))"
        return (user, token)
    }

    func signIn(phone: String, password: String) throws -> (user: UserModel, token: String) {
        guard let user = store.users.first(where: { $0.phone == phone }) else {
            throw LocalBackendError.notFound
        }
        guard store.passwordByUserID[user.id] == sha256(password) else {
            throw LocalBackendError.invalidPassword
        }
        let token = "local-token-\(user.id)-\(Int(Date().timeIntervalSince1970))"
        return (user, token)
    }

    func signInWithUsername(_ username: String, password: String) throws -> (user: UserModel, token: String) {
        let lower = username.lowercased()
        guard let userID = store.usernameByLowercase[lower],
              let user = store.users.first(where: { $0.id == userID }) else {
            throw LocalBackendError.notFound
        }
        guard store.passwordByUserID[user.id] == sha256(password) else {
            throw LocalBackendError.invalidPassword
        }
        let token = "local-token-\(user.id)-\(Int(Date().timeIntervalSince1970))"
        return (user, token)
    }

    // MARK: - Profile
    func updateProfile(userID: String, fullName: String?, username: String?, bio: String?) throws -> UserModel {
        guard let idx = store.users.firstIndex(where: { $0.id == userID }) else {
            throw LocalBackendError.notFound
        }
        if let n = fullName, !n.isEmpty { store.users[idx].fullName = n }
        if let b = bio { store.users[idx].bio = b }
        if let u = username, !u.isEmpty {
            let lower = u.lowercased()
            // Освободить старый username, если был.
            if let oldLower = store.usernameByLowercase.first(where: { $0.value == userID })?.key {
                store.usernameByLowercase.removeValue(forKey: oldLower)
            }
            // Проверка занятости.
            if let owner = store.usernameByLowercase[lower], owner != userID {
                throw LocalBackendError.usernameTaken
            }
            store.users[idx].username = u
            store.usernameByLowercase[lower] = userID
        }
        save()
        return store.users[idx]
    }

    func fetchUser(userID: String) throws -> UserModel {
        guard let user = store.users.first(where: { $0.id == userID }) else {
            throw LocalBackendError.notFound
        }
        return user
    }

    func searchUsers(query: String) -> [UserModel] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        return store.users.filter { user in
            user.username.lowercased().contains(q)
                || user.fullName.lowercased().contains(q)
                || user.phone.contains(q)
        }
    }

    // MARK: - Chats
    func fetchChats(userID: String) -> [ChatModel] {
        store.chats
            .filter { $0.participants.contains(userID) }
            .sorted { ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast) }
    }

    func createChat(participantIDs: [String], type: String, name: String?, creatorID: String) throws -> ChatModel {
        let allParticipants = Array(Set(participantIDs + [creatorID]))
        // Не создавать дубликат direct-чата.
        if type == "direct" {
            let existing = store.chats.first { chat in
                chat.type == .direct
                    && Set(chat.participants) == Set(allParticipants)
            }
            if let existing = existing { return existing }
        }
        let chat = ChatModel(
            id: UUID().uuidString,
            type: ChatModel.ChatType(rawValue: type) ?? .direct,
            name: name,
            participants: allParticipants,
            adminIDs: [creatorID]
        )
        store.chats.append(chat)
        save()
        return chat
    }

    // MARK: - Messages
    func fetchMessages(chatID: String, limit: Int) -> [MessageModel] {
        store.messages
            .filter { $0.chatID == chatID }
            .sorted { $0.createdAt < $1.createdAt }
            .suffix(limit)
            .map { $0 }
    }

    func sendMessage(_ message: MessageModel) throws -> MessageModel {
        store.messages.append(message)
        // Обновить lastMessage у чата.
        if let idx = store.chats.firstIndex(where: { $0.id == message.chatID }) {
            store.chats[idx].lastMessage = message.decryptedText ?? "[вложение]"
            store.chats[idx].lastMessageTime = message.createdAt
            store.chats[idx].lastMessageSenderID = message.senderID
        }
        save()
        return message
    }

    // MARK: - Demo content
    /// Создаёт приветственный чат с Support для нового пользователя.
    func ensureWelcomeChat(for userID: String) {
        guard !store.chats.contains(where: { $0.participants.contains(userID) }) else { return }
        let supportID = "support"
        guard store.users.contains(where: { $0.id == supportID }) else { return }
        let chat = ChatModel(
            id: UUID().uuidString,
            type: .direct,
            name: "LUMINA Support",
            participants: [userID, supportID],
            adminIDs: [supportID]
        )
        store.chats.append(chat)
        let msg = MessageModel(
            chatID: chat.id,
            senderID: supportID,
            decryptedText: "Добро пожаловать в LUMINA! 👋\n\nЭто локальный демо-режим — приложение работает полностью офлайн без сервера. Чтобы подключить Supabase, отредактируйте Constants.swift.",
            isRead: false,
            createdAt: Date()
        )
        store.messages.append(msg)
        store.chats[store.chats.firstIndex(of: chat)!].lastMessage = msg.decryptedText
        store.chats[store.chats.firstIndex(of: chat)!].lastMessageTime = msg.createdAt
        store.chats[store.chats.firstIndex(of: chat)!].lastMessageSenderID = supportID
        save()
    }

    // MARK: - Helpers
    private func sha256(_ string: String) -> String {
        // Простой FNV-1a хэш — НЕ криптостойкий, достаточен для локального демо.
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }
}

// MARK: - Errors
enum LocalBackendError: Error, LocalizedError {
    case otpNotFound
    case invalidOTP
    case notFound
    case phoneTaken
    case usernameTaken
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .otpNotFound: return "Запросите новый код"
        case .invalidOTP: return "Неверный код"
        case .notFound: return "Пользователь не найден"
        case .phoneTaken: return "Номер уже зарегистрирован"
        case .usernameTaken: return "Имя пользователя занято"
        case .invalidPassword: return "Неверный пароль"
        }
    }
}
