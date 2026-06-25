import SwiftUI
import SwiftData

/// Экран чата с лентой сообщений, панелью ввода и меню реакций
struct ChatDetailView: View {
    let chatID: String
    let chatName: String

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Query private var messages: [MessageModel]
    @State private var messageText = ""
    @State private var showReactionMenu = false
    @State private var selectedMessage: MessageModel?
    @State private var replyMessage: MessageModel?
    @State private var showAttachments = false
    @State private var isRecording = false
    @State private var showCallActions = false
    @State private var showGroupSettings = false
    @State private var showContactProfile = false

    init(chatID: String, chatName: String) {
        self.chatID = chatID
        self.chatName = chatName
        _messages = Query(
            filter: #Predicate<MessageModel> { $0.chatID == chatID },
            sort: \MessageModel.createdAt,
            order: .forward
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Хедер чата
            chatHeader

            // Лента сообщений
            ScrollViewReader { proxy in
                List(messages) { message in
                    if message.type == .system {
                        SystemMessageBubble(text: message.decryptedText ?? "")
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .id(message.id)
                    } else {
                        let isFromMe = message.senderID == (authService.currentUser?.id ?? "")
                        MessageBubble(
                            message: message,
                            isFromMe: isFromMe,
                            senderName: isFromMe ? nil : "Пользователь",
                            onReactionTap: {
                                selectedMessage = message
                                showReactionMenu = true
                            },
                            onReply: {
                                replyMessage = message
                            },
                            onDelete: {
                                // delete
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .id(message.id)
                        .onLongPressGesture {
                            selectedMessage = message
                            showReactionMenu = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Панель ответа
            if let reply = replyMessage {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(LuminaColor.accentBlue)
                        .frame(width: 3)
                        .clipShape(.rect(cornerRadius: 2))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ответ на сообщение")
                            .font(LuminaFont.micro)
                            .foregroundStyle(LuminaColor.accentBlue)
                        Text(reply.decryptedText ?? "")
                            .font(LuminaFont.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: { replyMessage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }

            // Нижняя панель ввода
            inputBar
        }
        .background(LuminaColor.backgroundMain)
        .navigationBarHidden(true)
        .sheet(isPresented: $showReactionMenu) {
            ReactionMenuView(
                message: selectedMessage,
                onReact: { emoji in
                    // Add reaction
                    showReactionMenu = false
                },
                onReply: {
                    replyMessage = selectedMessage
                    showReactionMenu = false
                },
                onCopy: {
                    if let text = selectedMessage?.decryptedText {
                        UIPasteboard.general.string = text
                    }
                    showReactionMenu = false
                },
                onDelete: {
                    showReactionMenu = false
                },
                onForward: {
                    showReactionMenu = false
                }
            )
            .presentationDetents([.medium])
            if #available(iOS 26.0, *) {
                // .glassEffectTransition(.materialize)
            }
        }
        .sheet(isPresented: $showCallActions) {
            CallActionSheet(
                chatName: chatName,
                onAudioCall: { startCall(isVideo: false) },
                onVideoCall: { startCall(isVideo: true) }
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showGroupSettings) {
            GroupSettingsView(chatName: chatName)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showContactProfile) {
            ContactProfileView(userName: chatName)
                .presentationDetents([.large])
        }
        .onAppear {
            // Отмечаем прочитанным
            SocketService.shared.markRead(
                chatID: chatID,
                userID: authService.currentUser?.id ?? ""
            )
        }
    }

    // MARK: - Хедер чата
    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(width: 36, height: 36)
            .glassCircle(interactive: true)

            Button(action: {
                if chatName.contains("Группа") {
                    showGroupSettings = true
                } else {
                    showContactProfile = true
                }
            }) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(chatName)
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                        // Verified badge placeholder
                    }

                    Text("5 минут")
                        .font(LuminaFont.micro)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            Button(action: { showCallActions = true }) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(width: 44, height: 44)
            .glassCircle(interactive: true)

            Button(action: { showCallActions = true }) {
                Image(systemName: "video.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(width: 44, height: 44)
            .glassCircle(interactive: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial)
    }

    // MARK: - Панель ввода
    private var inputBar: some View {
        HStack(spacing: 8) {
            // Кнопка вложений
            Button(action: { showAttachments.toggle() }) {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(width: 36, height: 36)
            .glassCircle(interactive: true)

            // Поле ввода
            TextField("Сообщение", text: $messageText)
                .font(LuminaFont.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassInput()

            // Кнопка отправки / микрофон
            if messageText.isEmpty && !isRecording {
                Button(action: { startRecording() }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LuminaColor.textPrimary)
                }
                .frame(width: 36, height: 36)
                .glassCircle(interactive: true)
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
                .background(LuminaColor.accentBlue, in: Circle())
                .buttonAnimation()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let msg = MessageModel(
            chatID: chatID,
            senderID: authService.currentUser?.id ?? "",
            decryptedText: messageText,
            isRead: false,
            createdAt: Date()
        )
        SocketService.shared.sendMessage(msg)
        messageText = ""
    }

    private func startRecording() {
        isRecording = true
        MediaService.shared.startRecording()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    private func startCall(isVideo: Bool) {
        showCallActions = false
        CallService.shared.startCall(
            to: chatName,
            chatID: chatID,
            isVideo: isVideo
        )
    }
}

// MARK: - CallActionSheet
struct CallActionSheet: View {
    let chatName: String
    var onAudioCall: () -> Void
    var onVideoCall: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text(chatName)
                .font(LuminaFont.body)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 20)
                .padding(.bottom, 20)

            HStack(spacing: 40) {
                Button(action: { dismiss(); onAudioCall() }) {
                    VStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green, in: Circle())
                        Text("Аудио")
                            .font(LuminaFont.caption)
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                }

                Button(action: { dismiss(); onVideoCall() }) {
                    VStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(LuminaColor.accentBlue, in: Circle())
                        Text("Видео")
                            .font(LuminaFont.caption)
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ChatDetailView(chatID: "test", chatName: "ASMobbin")
        .environment(AuthService.shared)
}
