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

// MARK: - X / Twitter-style Home Feed (жидкое стекло + дизайн как в X)
struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @State private var posts: [XPost] = XPost.demoPosts
    @State private var showCompose = false
    @State private var selectedPost: XPost?
    @State private var showPostDetail = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Glass top bar как в X / на референсах
                        HStack {
                            Text("X")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(LuminaColor.textPrimary)

                            Spacer()

                            Button {
                                // search
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18))
                            }
                            .glassCircle()
                            .frame(width: 36, height: 36)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassToolbar()

                        // Compose quick bar (как в X)
                        HStack(spacing: 12) {
                            AvatarView(
                                imageURL: authService.currentUser?.avatarURL,
                                name: authService.currentUser?.fullName ?? "You",
                                size: 36
                            )

                            Button {
                                showCompose = true
                            } label: {
                                Text("Что нового?")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .frame(height: 42)
                                    .glassInput()
                            }
                            .buttonStyle(.plain)

                            Button {
                                showCompose = true
                            } label: {
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                            }
                            .glassCircle()
                            .frame(width: 36, height: 36)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        Divider().opacity(0.1)

                        // Feed
                        ForEach(posts) { post in
                            XPostRow(
                                post: post,
                                onTap: {
                                    selectedPost = post
                                    showPostDetail = true
                                },
                                onLike: {
                                    toggleLike(post)
                                },
                                onRepost: {
                                    repost(post)
                                },
                                onReply: {
                                    selectedPost = post
                                    showPostDetail = true
                                }
                            )
                            .contextMenu {
                                Button("Reply") { selectedPost = post; showPostDetail = true }
                                Button("Repost") { repost(post) }
                                Button("Copy text") { UIPasteboard.general.string = post.text }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    posts.removeAll { $0.id == post.id }
                                }
                            }
                        }
                    }
                }
                .background(LuminaColor.backgroundMain)
                .refreshable {
                    // mock refresh
                }

                // Floating compose (X style)
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(LuminaColor.accentBlue, in: Circle())
                        .shadow(radius: 8)
                }
                .padding(20)
            }
            .sheet(isPresented: $showCompose) {
                XComposeView { newPost in
                    posts.insert(newPost, at: 0)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPostDetail) {
                if let post = selectedPost {
                    XPostDetailView(post: post, onReplyAdded: { replyText in
                        addReply(to: post, text: replyText)
                    })
                }
            }
        }
    }

    private func toggleLike(_ post: XPost) {
        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
            posts[idx].isLiked.toggle()
            posts[idx].likeCount += posts[idx].isLiked ? 1 : -1
        }
    }

    private func repost(_ post: XPost) {
        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
            posts[idx].repostCount += 1
        }
        // Add a repost entry (simple)
        let repostPost = XPost(
            id: UUID().uuidString,
            authorName: authService.currentUser?.fullName ?? "You",
            authorHandle: "@" + (authService.currentUser?.username ?? "you"),
            text: "Reposted: " + post.text,
            imageName: nil,
            likeCount: 0,
            repostCount: 0,
            replyCount: 0,
            timestamp: "now",
            isLiked: false
        )
        posts.insert(repostPost, at: 0)
    }

    private func addReply(to post: XPost, text: String) {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[idx].replyCount += 1
        // In real would append to replies array
    }
}

// Simple post model for X feed
struct XPost: Identifiable, Equatable {
    let id: String
    var authorName: String
    var authorHandle: String
    var text: String
    var imageName: String?   // system name or asset for demo
    var likeCount: Int
    var repostCount: Int
    var replyCount: Int
    var timestamp: String
    var isLiked: Bool = false

    static var demoPosts: [XPost] = [
        XPost(id: "p1", authorName: "Alex Sam", authorHandle: "@salmobbin", text: "It looks great", imageName: "photo", likeCount: 124, repostCount: 18, replyCount: 7, timestamp: "5m"),
        XPost(id: "p2", authorName: "Jane Smith", authorHandle: "@janesmith", text: "Just shipped a new update. Liquid glass everywhere 🔥", imageName: nil, likeCount: 89, repostCount: 12, replyCount: 23, timestamp: "17m"),
        XPost(id: "p3", authorName: "Pavel Durov", authorHandle: "@durov", text: "Privacy is not a crime.", imageName: nil, likeCount: 12400, repostCount: 3200, replyCount: 890, timestamp: "1h", isLiked: true),
    ]
}

// Post row (X style)
struct XPostRow: View {
    let post: XPost
    var onTap: () -> Void
    var onLike: () -> Void
    var onRepost: () -> Void
    var onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(imageURL: nil, name: post.authorName, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.authorName).font(.system(size: 16, weight: .semibold))
                        Text(post.authorHandle).foregroundStyle(.secondary)
                        Text("· \(post.timestamp)").foregroundStyle(.secondary)
                    }

                    Text(post.text)
                        .font(.system(size: 16))
                        .foregroundStyle(LuminaColor.textPrimary)

                    if let img = post.imageName {
                        // Mock image
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.15))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: img)
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 4)
                    }

                    // Action bar — X style
                    HStack(spacing: 40) {
                        Button(action: onReply) {
                            Label("\(post.replyCount)", systemImage: "bubble.left")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(.secondary)

                        Button(action: onRepost) {
                            Label("\(post.repostCount)", systemImage: "arrow.2.squarepath")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(.secondary)

                        Button(action: onLike) {
                            Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 14))
                                .foregroundStyle(post.isLiked ? .red : .secondary)
                        }

                        Button {
                            // share
                            UIPasteboard.general.string = post.text
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.08)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .glassCard()
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// Compose sheet
struct XComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var text = ""
    var onPost: (XPost) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Button("Cancel") { dismiss() }
                    Spacer()
                    Button("Post") {
                        let new = XPost(
                            id: UUID().uuidString,
                            authorName: authService.currentUser?.fullName ?? "You",
                            authorHandle: "@" + (authService.currentUser?.username ?? "you"),
                            text: text,
                            imageName: nil,
                            likeCount: 0,
                            repostCount: 0,
                            replyCount: 0,
                            timestamp: "now"
                        )
                        onPost(new)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                TextEditor(text: $text)
                    .font(.system(size: 20))
                    .padding(.horizontal)
                    .frame(minHeight: 180)

                Spacer()
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Post detail + comments (basic)
struct XPostDetailView: View {
    let post: XPost
    var onReplyAdded: (String) -> Void

    @State private var replyText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    XPostRow(post: post, onTap: {}, onLike: {}, onRepost: {}, onReply: {})

                    Divider()

                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)

                    // Simple demo comments
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { AvatarView(imageURL: nil, name: "Support", size: 28); Text("Nice!").font(.callout) }
                        HStack { AvatarView(imageURL: nil, name: "Jane", size: 28); Text("Love the glass effect").font(.callout) }
                    }
                    .padding(.horizontal)
                }
            }
            .background(LuminaColor.backgroundMain)

            // Reply bar
            HStack {
                TextField("Post your reply", text: $replyText)
                    .textFieldStyle(.roundedBorder)

                Button("Reply") {
                    if !replyText.isEmpty {
                        onReplyAdded(replyText)
                        replyText = ""
                    }
                }
                .disabled(replyText.isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}
