import Foundation
import SwiftData

@Model
final class MessageModel: Codable {
    var id: String
    var chatID: String
    var senderID: String
    var type: MessageType
    var encryptedText: String?
    var decryptedText: String? // хранится только локально
    var mediaURL: String?
    var mediaType: String?
    var replyToMessageID: String?
    var forwardFromChatID: String?
    var isRead: Bool
    var readAt: Date?
    var createdAt: Date
    var disappearingAt: Date?
    var reactions: [String: [String]] // [emoji: [userIDs]]
    var isEdited: Bool
    var editedAt: Date?

    init(
        id: String = UUID().uuidString,
        chatID: String,
        senderID: String,
        type: MessageType = .text,
        encryptedText: String? = nil,
        decryptedText: String? = nil,
        mediaURL: String? = nil,
        mediaType: String? = nil,
        replyToMessageID: String? = nil,
        forwardFromChatID: String? = nil,
        isRead: Bool = false,
        readAt: Date? = nil,
        createdAt: Date = Date(),
        disappearingAt: Date? = nil,
        reactions: [String: [String]] = [:],
        isEdited: Bool = false,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.chatID = chatID
        self.senderID = senderID
        self.type = type
        self.encryptedText = encryptedText
        self.decryptedText = decryptedText
        self.mediaURL = mediaURL
        self.mediaType = mediaType
        self.replyToMessageID = replyToMessageID
        self.forwardFromChatID = forwardFromChatID
        self.isRead = isRead
        self.readAt = readAt
        self.createdAt = createdAt
        self.disappearingAt = disappearingAt
        self.reactions = reactions
        self.isEdited = isEdited
        self.editedAt = editedAt
    }

    enum MessageType: String, Codable {
        case text
        case image
        case video
        case audio
        case file
        case sticker
        case system
        case call
    }

    enum CodingKeys: String, CodingKey {
        case id, chatID, senderID, type, encryptedText, decryptedText
        case mediaURL, mediaType, replyToMessageID, forwardFromChatID
        case isRead, readAt, createdAt, disappearingAt, reactions, isEdited, editedAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        chatID = try c.decode(String.self, forKey: .chatID)
        senderID = try c.decode(String.self, forKey: .senderID)
        type = try c.decode(MessageType.self, forKey: .type)
        encryptedText = try c.decodeIfPresent(String.self, forKey: .encryptedText)
        decryptedText = try c.decodeIfPresent(String.self, forKey: .decryptedText)
        mediaURL = try c.decodeIfPresent(String.self, forKey: .mediaURL)
        mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType)
        replyToMessageID = try c.decodeIfPresent(String.self, forKey: .replyToMessageID)
        forwardFromChatID = try c.decodeIfPresent(String.self, forKey: .forwardFromChatID)
        isRead = try c.decode(Bool.self, forKey: .isRead)
        readAt = try c.decodeIfPresent(Date.self, forKey: .readAt)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        disappearingAt = try c.decodeIfPresent(Date.self, forKey: .disappearingAt)
        reactions = try c.decode([String: [String]].self, forKey: .reactions)
        isEdited = try c.decode(Bool.self, forKey: .isEdited)
        editedAt = try c.decodeIfPresent(Date.self, forKey: .editedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(chatID, forKey: .chatID)
        try c.encode(senderID, forKey: .senderID)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(encryptedText, forKey: .encryptedText)
        try c.encodeIfPresent(decryptedText, forKey: .decryptedText)
        try c.encodeIfPresent(mediaURL, forKey: .mediaURL)
        try c.encodeIfPresent(mediaType, forKey: .mediaType)
        try c.encodeIfPresent(replyToMessageID, forKey: .replyToMessageID)
        try c.encodeIfPresent(forwardFromChatID, forKey: .forwardFromChatID)
        try c.encode(isRead, forKey: .isRead)
        try c.encodeIfPresent(readAt, forKey: .readAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(disappearingAt, forKey: .disappearingAt)
        try c.encode(reactions, forKey: .reactions)
        try c.encode(isEdited, forKey: .isEdited)
        try c.encodeIfPresent(editedAt, forKey: .editedAt)
    }
}
