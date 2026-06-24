import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Query private var chats: [ChatModel]
    @State private var selectedTab: Tab = .chats
    @State private var showSearch = false
    @State private var showNewChat = false
    @State private var showProfile = false

    enum Tab: String {
        case home
        case chats
    }

    var body: some View {
        if authService.isAuthenticated {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(Tab.home)

                    ChatListView()
                        .tag(Tab.chats)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                BottomNavBar(
                    selectedTab: $selectedTab,
                    unreadCount: chats.reduce(0) { $0 + $1.unreadCount },
                    onSearchTap: { showSearch = true },
                    onProfileTap: { showProfile = true }
                )
            }
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showProfile) {
                SettingsView()
                    .presentationDetents([.large])
            }
            .onAppear {
                SocketService.shared.connect()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                SocketService.shared.sendOnlineStatus(
                    userID: KeychainService.shared.currentUserID ?? "",
                    isOnline: false
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                SocketService.shared.sendOnlineStatus(
                    userID: KeychainService.shared.currentUserID ?? "",
                    isOnline: true
                )
            }
        } else {
            RegistrationFlowView()
                .transition(.opacity)
        }
    }
}

// MARK: - HomeView (Главное)
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Хедер
                HStack {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 20))
                    }
                    .glassCircle(interactive: true)
                    .frame(width: 44, height: 44)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                    }
                    .glassCircle(interactive: true)
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Пустое состояние
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray.opacity(0.3))

                    Text("Нет сообщений")
                        .font(LuminaFont.h3)
                        .foregroundStyle(LuminaColor.textPrimary)

                    Text("Начните новую беседу, чтобы начать общаться.")
                        .font(LuminaFont.body)
                        .foregroundStyle(LuminaColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .background(LuminaColor.backgroundMain)
        }
    }
}
