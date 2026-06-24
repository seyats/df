import SwiftUI

/// Модальный лист «Новый чат»
struct NewChatView: View {
    var onChatCreated: ((ChatModel) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @State private var searchQuery = ""
    @State private var searchResults: [UserModel] = []
    @State private var selectedUsers: [UserModel] = []
    @State private var groupName = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поиск
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Поиск пользователей", text: $searchQuery)
                        .font(LuminaFont.body)
                        .onChange(of: searchQuery) { _, query in
                            searchUsers(query: query)
                        }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(16)

                // Выбранные пользователи
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selectedUsers, id: \.id) { user in
                                VStack(spacing: 4) {
                                    AvatarView(
                                        imageURL: user.avatarURL,
                                        name: user.fullName,
                                        size: 52
                                    )
                                    Text(user.fullName)
                                        .font(LuminaFont.micro)
                                        .foregroundStyle(LuminaColor.textPrimary)
                                        .lineLimit(1)
                                }
                                .onTapGesture {
                                    selectedUsers.removeAll { $0.id == user.id }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 80)

                    if selectedUsers.count > 1 {
                        TextField("Название группы", text: $groupName)
                            .font(LuminaFont.body)
                            .padding()
                            .glassInput()
                            .padding(.horizontal, 16)
                    }
                }

                // Результаты поиска
                List(searchResults) { user in
                    HStack(spacing: 12) {
                        AvatarView(
                            imageURL: user.avatarURL,
                            name: user.fullName,
                            size: 44
                        )

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

                        Spacer()

                        if selectedUsers.contains(where: { $0.id == user.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LuminaColor.accentBlue)
                        } else {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleUser(user)
                    }
                }
                .listStyle(.plain)
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") {
                        createChat()
                    }
                    .disabled(selectedUsers.isEmpty || isLoading)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func searchUsers(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        Task {
            do {
                let users = try await APIService.shared.searchUsers(query: query)
                await MainActor.run {
                    searchResults = users
                }
            } catch {
                searchResults = []
            }
        }
    }

    private func toggleUser(_ user: UserModel) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }

    private func createChat() {
        isLoading = true
        Task {
            do {
                let participantIDs = selectedUsers.map { $0.id }
                let type = selectedUsers.count > 1 ? "group" : "direct"
                let name = selectedUsers.count > 1 ? (groupName.isEmpty ? nil : groupName) : selectedUsers.first?.fullName
                let chat = try await APIService.shared.createChat(participantIDs: participantIDs, type: type, name: name)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onChatCreated?(chat)
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
