import SwiftUI

/// Экран поиска (лупа в нижней навигации)
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [UserModel] = []
    @State private var searchResultsChats: [ChatModel] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поисковая строка
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Поиск...", text: $searchText)
                        .font(LuminaFont.body)
                        .onChange(of: searchText) { _, query in
                            performSearch(query: query)
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding()
                .glassInput()
                .padding(16)

                if searchText.isEmpty {
                    Spacer()
                    Text("Введите имя пользователя или название чата")
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                    Spacer()
                } else if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchResults.isEmpty && searchResultsChats.isEmpty {
                    Spacer()
                    Text("Ничего не найдено")
                        .font(LuminaFont.body)
                        .foregroundStyle(.gray)
                    Spacer()
                } else {
                    List {
                        if !searchResultsChats.isEmpty {
                            Section("Чаты") {
                                ForEach(searchResultsChats) { chat in
                                    ChatRow(chat: chat, currentUserID: "")
                                }
                            }
                        }
                        if !searchResults.isEmpty {
                            Section("Пользователи") {
                                ForEach(searchResults) { user in
                                    HStack(spacing: 12) {
                                        AvatarView(imageURL: user.avatarURL, name: user.fullName, size: 44)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Text(user.fullName)
                                                    .font(LuminaFont.body)
                                                    .foregroundStyle(LuminaColor.textPrimary)
                                                if user.isVerified {
                                                    VerifiedBadge(size: 14)
                                                }
                                            }
                                            Text("@\(user.username)")
                                                .font(LuminaFont.caption)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func performSearch(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            searchResultsChats = []
            return
        }
        isSearching = true
        Task {
            do {
                let users = try await APIService.shared.searchUsers(query: query)
                await MainActor.run {
                    searchResults = users
                    isSearching = false
                }
            } catch {
                await MainActor.run { isSearching = false }
            }
        }
    }
}
