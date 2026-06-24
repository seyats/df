import SwiftUI

/// Нижний лист с меню реакций и действий
struct ReactionMenuView: View {
    let message: MessageModel?
    var onReact: (String) -> Void
    var onReply: () -> Void
    var onCopy: () -> Void
    var onDelete: () -> Void
    var onForward: () -> Void

    @Environment(\.dismiss) private var dismiss

    let emojis = ["❤️", "🔥", "💯", "🤣", "👍", "🙏", "😢", "🤯", "😡", "🥳", "+"]

    var body: some View {
        VStack(spacing: 0) {
            // Грид реакций
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onReact(emoji)
                    }) {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .glassCircle(interactive: true)
                    }
                    .buttonAnimation()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            // Действия
            VStack(spacing: 0) {
                ReactionMenuAction(icon: "arrowshape.turn.up.left", title: "Ответить", action: {
                    dismiss()
                    onReply()
                })
                ReactionMenuAction(icon: "arrowshape.turn.up.right", title: "Переслать", action: {
                    dismiss()
                    onForward()
                })
                ReactionMenuAction(icon: "doc.on.doc", title: "Копировать", action: {
                    dismiss()
                    onCopy()
                })
                ReactionMenuAction(icon: "info.circle", title: "Инфо", action: { dismiss() })
                ReactionMenuAction(icon: "trash", title: "Удалить", isDestructive: true, action: {
                    dismiss()
                    onDelete()
                })
                ReactionMenuAction(icon: "flag", title: "Пожаловаться", isDestructive: true, action: { dismiss() })
            }
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 40))
    }
}

struct ReactionMenuAction: View {
    let icon: String
    let title: String
    var isDestructive = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isDestructive ? Color.red : LuminaColor.textPrimary)
                    .frame(width: 28)

                Text(title)
                    .font(LuminaFont.body)
                    .foregroundStyle(isDestructive ? Color.red : LuminaColor.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    ReactionMenuView(
        message: nil,
        onReact: { _ in },
        onReply: {},
        onCopy: {},
        onDelete: {},
        onForward: {}
    )
}
