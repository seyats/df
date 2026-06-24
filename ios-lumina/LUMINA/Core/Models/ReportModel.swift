import Foundation
import SwiftData

@Model
final class ReportModel: Codable {
    var id: String
    var reporterID: String
    var reportedUserID: String
    var chatID: String?
    var messageID: String?
    var reason: String
    var status: ReportStatus
    var createdAt: Date
    var resolvedAt: Date?
    var resolvedBy: String?

    enum ReportStatus: String, Codable {
        case pending
        case reviewed
        case resolved
        case dismissed
    }

    init(
        id: String = UUID().uuidString,
        reporterID: String,
        reportedUserID: String,
        chatID: String? = nil,
        messageID: String? = nil,
        reason: String = "",
        status: ReportStatus = .pending,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil,
        resolvedBy: String? = nil
    ) {
        self.id = id
        self.reporterID = reporterID
        self.reportedUserID = reportedUserID
        self.chatID = chatID
        self.messageID = messageID
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
    }

    enum CodingKeys: String, CodingKey {
        case id, reporterID, reportedUserID, chatID, messageID
        case reason, status, createdAt, resolvedAt, resolvedBy
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        reporterID = try c.decode(String.self, forKey: .reporterID)
        reportedUserID = try c.decode(String.self, forKey: .reportedUserID)
        chatID = try c.decodeIfPresent(String.self, forKey: .chatID)
        messageID = try c.decodeIfPresent(String.self, forKey: .messageID)
        reason = try c.decode(String.self, forKey: .reason)
        status = try c.decode(ReportStatus.self, forKey: .status)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        resolvedAt = try c.decodeIfPresent(Date.self, forKey: .resolvedAt)
        resolvedBy = try c.decodeIfPresent(String.self, forKey: .resolvedBy)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(reporterID, forKey: .reporterID)
        try c.encode(reportedUserID, forKey: .reportedUserID)
        try c.encodeIfPresent(chatID, forKey: .chatID)
        try c.encodeIfPresent(messageID, forKey: .messageID)
        try c.encode(reason, forKey: .reason)
        try c.encode(status, forKey: .status)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(resolvedAt, forKey: .resolvedAt)
        try c.encodeIfPresent(resolvedBy, forKey: .resolvedBy)
    }
}
