import Foundation
import SwiftData

@Model
final class ChatModel: Codable {
    var id: String
    var type: ChatType
    var name: String?
    var avatarURL: String?
    var lastMessage: String?
    var lastMessageTime: Date?
    var lastMessageSenderID: String?
    var unreadCount: Int
    var isPinned: Bool
    var isMuted: Bool
    var disappearingMessageSeconds: Int // 0 = выкл
    var screenshotBlocked: Bool
    var inviteLink: String?
    var createdAt: Date
    var participants: [String] // user IDs
    var adminIDs: [String]

    init(
        id: String = UUID().uuidString,
        type: ChatType = .direct,
        name: String? = nil,
        avatarURL: String? = nil,
        lastMessage: String? = nil,
        lastMessageTime: Date? = nil,
        lastMessageSenderID: String? = nil,
        unreadCount: Int = 0,
        isPinned: Bool = false,
        isMuted: Bool = false,
        disappearingMessageSeconds: Int = 0,
        screenshotBlocked: Bool = false,
        inviteLink: String? = nil,
        createdAt: Date = Date(),
        participants: [String] = [],
        adminIDs: [String] = []
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.avatarURL = avatarURL
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.lastMessageSenderID = lastMessageSenderID
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.disappearingMessageSeconds = disappearingMessageSeconds
        self.screenshotBlocked = screenshotBlocked
        self.inviteLink = inviteLink
        self.createdAt = createdAt
        self.participants = participants
        self.adminIDs = adminIDs
    }

    enum ChatType: String, Codable {
        case direct
        case group
        case channel
    }

    enum CodingKeys: String, CodingKey {
        case id, type, name, avatarURL, lastMessage, lastMessageTime
        case lastMessageSenderID, unreadCount, isPinned, isMuted
        case disappearingMessageSeconds, screenshotBlocked, inviteLink
        case createdAt, participants, adminIDs
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(ChatType.self, forKey: .type)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        lastMessage = try c.decodeIfPresent(String.self, forKey: .lastMessage)
        lastMessageTime = try c.decodeIfPresent(Date.self, forKey: .lastMessageTime)
        lastMessageSenderID = try c.decodeIfPresent(String.self, forKey: .lastMessageSenderID)
        unreadCount = try c.decode(Int.self, forKey: .unreadCount)
        isPinned = try c.decode(Bool.self, forKey: .isPinned)
        isMuted = try c.decode(Bool.self, forKey: .isMuted)
        disappearingMessageSeconds = try c.decode(Int.self, forKey: .disappearingMessageSeconds)
        screenshotBlocked = try c.decode(Bool.self, forKey: .screenshotBlocked)
        inviteLink = try c.decodeIfPresent(String.self, forKey: .inviteLink)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        participants = try c.decode([String].self, forKey: .participants)
        adminIDs = try c.decode([String].self, forKey: .adminIDs)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try c.encodeIfPresent(lastMessage, forKey: .lastMessage)
        try c.encodeIfPresent(lastMessageTime, forKey: .lastMessageTime)
        try c.encodeIfPresent(lastMessageSenderID, forKey: .lastMessageSenderID)
        try c.encode(unreadCount, forKey: .unreadCount)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(isMuted, forKey: .isMuted)
        try c.encode(disappearingMessageSeconds, forKey: .disappearingMessageSeconds)
        try c.encode(screenshotBlocked, forKey: .screenshotBlocked)
        try c.encodeIfPresent(inviteLink, forKey: .inviteLink)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(participants, forKey: .participants)
        try c.encode(adminIDs, forKey: .adminIDs)
    }
}
