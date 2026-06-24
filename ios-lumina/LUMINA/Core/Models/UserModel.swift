import Foundation
import SwiftData

@Model
final class UserModel: Codable {
    var id: String
    var phone: String
    var email: String?
    var fullName: String
    var username: String
    var bio: String?
    var avatarURL: String?
    var isVerified: Bool
    var isOnline: Bool
    var lastSeen: Date
    var createdAt: Date
    var isBlocked: Bool
    var isAdmin: Bool
    var pinCode: String?
    var passwordHash: String
    var publicKey: String?
    var pushToken: String?

    init(
        id: String = UUID().uuidString,
        phone: String,
        email: String? = nil,
        fullName: String = "",
        username: String = "",
        bio: String? = nil,
        avatarURL: String? = nil,
        isVerified: Bool = false,
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        createdAt: Date = Date(),
        isBlocked: Bool = false,
        isAdmin: Bool = false,
        pinCode: String? = nil,
        passwordHash: String = "",
        publicKey: String? = nil,
        pushToken: String? = nil
    ) {
        self.id = id
        self.phone = phone
        self.email = email
        self.fullName = fullName
        self.username = username
        self.bio = bio
        self.avatarURL = avatarURL
        self.isVerified = isVerified
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.createdAt = createdAt
        self.isBlocked = isBlocked
        self.isAdmin = isAdmin
        self.pinCode = pinCode
        self.passwordHash = passwordHash
        self.publicKey = publicKey
        self.pushToken = pushToken
    }

    enum CodingKeys: String, CodingKey {
        case id, phone, email, fullName, username, bio, avatarURL
        case isVerified, isOnline, lastSeen, createdAt, isBlocked, isAdmin
        case pinCode, passwordHash, publicKey, pushToken
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        phone = try c.decode(String.self, forKey: .phone)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        fullName = try c.decode(String.self, forKey: .fullName)
        username = try c.decode(String.self, forKey: .username)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        isVerified = try c.decode(Bool.self, forKey: .isVerified)
        isOnline = try c.decode(Bool.self, forKey: .isOnline)
        lastSeen = try c.decode(Date.self, forKey: .lastSeen)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        isBlocked = try c.decode(Bool.self, forKey: .isBlocked)
        isAdmin = try c.decode(Bool.self, forKey: .isAdmin)
        pinCode = try c.decodeIfPresent(String.self, forKey: .pinCode)
        passwordHash = try c.decode(String.self, forKey: .passwordHash)
        publicKey = try c.decodeIfPresent(String.self, forKey: .publicKey)
        pushToken = try c.decodeIfPresent(String.self, forKey: .pushToken)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(phone, forKey: .phone)
        try c.encodeIfPresent(email, forKey: .email)
        try c.encode(fullName, forKey: .fullName)
        try c.encode(username, forKey: .username)
        try c.encodeIfPresent(bio, forKey: .bio)
        try c.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try c.encode(isVerified, forKey: .isVerified)
        try c.encode(isOnline, forKey: .isOnline)
        try c.encode(lastSeen, forKey: .lastSeen)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(isBlocked, forKey: .isBlocked)
        try c.encode(isAdmin, forKey: .isAdmin)
        try c.encodeIfPresent(pinCode, forKey: .pinCode)
        try c.encode(passwordHash, forKey: .passwordHash)
        try c.encodeIfPresent(publicKey, forKey: .publicKey)
        try c.encodeIfPresent(pushToken, forKey: .pushToken)
    }
}
