import SwiftUI

/// Пузырь сообщения — входящее или исходящее
struct MessageBubble: View {
    let message: MessageModel
    let isFromMe: Bool
    let senderName: String?
    let onReactionTap: (() -> Void)?
    let onReply: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var showContextMenu = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isFromMe {
                // Аватар слева для входящих
                AvatarView(
                    imageURL: nil,
                    name: senderName ?? "?",
                    size: 30
                )
            }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
                // Имя отправителя (только для входящих в группах)
                if !isFromMe, let name = senderName {
                    Text(name)
                        .font(LuminaFont.micro)
                        .foregroundStyle(.gray)
                        .padding(.leading, 4)
                }

                // Цитируемое сообщение
                if let replyID = message.replyToMessageID {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(isFromMe ? Color.white.opacity(0.5) : LuminaColor.accentBlue)
                            .frame(width: 3)
                            .clipShape(.rect(cornerRadius: 2))
                        Text("Ответ на сообщение")
                            .font(LuminaFont.micro)
                            .foregroundStyle(isFromMe ? .white.opacity(0.7) : .gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isFromMe ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 10))
                }

                // Тело сообщения
                HStack(alignment: .bottom, spacing: 6) {
                    Text(message.decryptedText ?? "Зашифрованное сообщение")
                        .font(LuminaFont.body)
                        .foregroundStyle(isFromMe ? .white : LuminaColor.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            isFromMe
                            ? LuminaColor.accentBlue
                            : LuminaColor.messageReceived,
                            in: RoundedRectangle(cornerRadius: 18)
                        )

                    // Время
                    Text(message.createdAt.messageTimeString)
                        .font(.system(size: 11))
                        .foregroundStyle(isFromMe ? .white.opacity(0.7) : .gray)
                }

                // Статус прочитано
                if isFromMe && message.isRead {
                    Text("Прочитано")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .padding(.trailing, 4)
                }

                // Реакции
                if !message.reactions.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(message.reactions.keys.sorted()), id: \.self) { emoji in
                            Text("\(emoji) \(message.reactions[emoji]?.count ?? 0)")
                                .font(LuminaFont.micro)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isFromMe ? .trailing : .leading)

            if isFromMe {
                Spacer(minLength: 50)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: { onReactionTap?() }) {
                Label("Реакции", systemImage: "face.smiling")
            }
            Button(action: { onReply?() }) {
                Label("Ответить", systemImage: "arrowshape.turn.up.left")
            }
            Button(action: { UIPasteboard.general.string = message.decryptedText }) {
                Label("Копировать", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive, action: { onDelete?() }) {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

// MARK: - Системное сообщение
struct SystemMessageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}
