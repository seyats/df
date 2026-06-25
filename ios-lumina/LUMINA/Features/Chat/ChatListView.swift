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
                // Хедер — как на референсе (жидкое стекло) + X badge
                HStack {
                    // Левая аватарка
                    Button(action: { showProfile = true }) {
                        AvatarView(
                            imageURL: authService.currentUser?.avatarURL,
                            name: authService.currentUser?.fullName ?? "Я",
                            size: 34
                        )
                    }

                    Spacer()

                    Text("Chat")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LuminaColor.textPrimary)

                    Spacer()

                    // X with red badge (exact to screenshot)
                    Button(action: { /* X actions / notifications */ }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "xmark")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(LuminaColor.textPrimary)
                                .frame(width: 34, height: 34)
                                .glassCircle(interactive: true)

                            Text("1")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 0)
                                .background(Color.red, in: Capsule())
                                .offset(x: 4, y: -3)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .glassToolbar()

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
