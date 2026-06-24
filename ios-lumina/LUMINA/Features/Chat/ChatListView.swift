import SwiftUI
import SwiftData

/// Главный экран — список чатов
struct ChatListView: View {
    @Environment(AuthService.self) private var authService
    @Query(sort: \ChatModel.lastMessageTime, order: .reverse) private var allChats: [ChatModel]
    @State private var showNewChat = false
    @State private var selectedChat: ChatModel?
    @State private var showChatDetail = false
    @State private var showProfile = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Хедер
                HStack {
                    // Аватарка профиля
                    Button(action: { showProfile = true }) {
                        AvatarView(
                            imageURL: authService.currentUser?.avatarURL,
                            name: authService.currentUser?.fullName ?? "Я",
                            size: 44
                        )
                    }

                    Spacer()

                    Text("Чаты")
                        .font(LuminaFont.h3)
                        .foregroundStyle(LuminaColor.textPrimary)

                    Spacer()

                    Button(action: { showNewChat = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                    .glassCircle(interactive: true)
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if allChats.isEmpty {
                    emptyState
                } else {
                    List {
                        // Закреплённые
                        ForEach(pinnedChats) { chat in
                            ChatRow(chat: chat, currentUserID: authService.currentUser?.id ?? "")
                                .onTapGesture { navigateToChat(chat) }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button("Удалить") {}
                                        .tint(.red)
                                }
                        }

                        // Остальные
                        ForEach(unpinnedChats) { chat in
                            ChatRow(chat: chat, currentUserID: authService.currentUser?.id ?? "")
                                .onTapGesture { navigateToChat(chat) }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button("Удалить") {}
                                        .tint(.red)
                                    Button("В архив") {}
                                        .tint(.gray)
                                }
                                .swipeActions(edge: .leading) {
                                    Button(chat.isPinned ? "Открепить" : "Закрепить") {
                                        chat.isPinned.toggle()
                                    }
                                    .tint(chat.isPinned ? .gray : .orange)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(LuminaColor.backgroundMain)
            .sheet(isPresented: $showNewChat) {
                NewChatView(onChatCreated: { chat in
                    selectedChat = chat
                    showNewChat = false
                    showChatDetail = true
                })
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showProfile) {
                SettingsView()
                    .presentationDetents([.large])
            }
            .navigationDestination(isPresented: $showChatDetail) {
                if let chat = selectedChat {
                    ChatDetailView(chatID: chat.id, chatName: chat.name ?? "Чат")
                }
            }
        }
    }

    private var pinnedChats: [ChatModel] {
        allChats.filter { $0.isPinned }
    }

    private var unpinnedChats: [ChatModel] {
        allChats.filter { !$0.isPinned }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.25))
            Text("Нет сообщений")
                .font(LuminaFont.h3)
                .foregroundStyle(LuminaColor.textPrimary)
            Text("Начните новую беседу, чтобы начать общаться.")
                .font(LuminaFont.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func navigateToChat(_ chat: ChatModel) {
        selectedChat = chat
        showChatDetail = true
    }
}
