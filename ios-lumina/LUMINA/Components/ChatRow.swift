import SwiftUI

/// Ячейка чата в списке
struct ChatRow: View {
    let chat: ChatModel
    let currentUserID: String

    var body: some View {
        HStack(spacing: 12) {
            // Аватарка
            AvatarView(
                imageURL: chat.avatarURL,
                name: chat.name ?? "Чат",
                size: 52
            )

            // Контент
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(chat.name ?? "Чат")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LuminaColor.textPrimary)
                        .lineLimit(1)

                    if chat.type == .group {
                        Text("\(chat.participants.count)")
                            .font(LuminaFont.micro)
                            .foregroundStyle(.gray)
                    }

                    if chat.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(LuminaColor.verifiedBadge)
                    }
                }

                if let lastMessage = chat.lastMessage {
                    Text(lastMessage)
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Правая сторона
            VStack(alignment: .trailing, spacing: 6) {
                if let time = chat.lastMessageTime {
                    Text(time.chatTimeString)
                        .font(LuminaFont.micro)
                        .foregroundStyle(.gray)
                }

                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(LuminaColor.accentBlue, in: Circle())
                }

                if chat.isMuted {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }

                if chat.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Verified extension for ChatModel
extension ChatModel {
    var isVerified: Bool { false }
}
