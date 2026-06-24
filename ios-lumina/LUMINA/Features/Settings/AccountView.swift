import SwiftUI

/// Экран аккаунта пользователя
struct AccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeactivateConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer().frame(height: 20)

                // Аватарка + имя
                AvatarView(
                    imageURL: authService.currentUser?.avatarURL,
                    name: authService.currentUser?.fullName ?? "Я",
                    size: 100
                )

                HStack(spacing: 4) {
                    Text(authService.currentUser?.fullName ?? "Пользователь")
                        .font(LuminaFont.h3)
                        .foregroundStyle(LuminaColor.textPrimary)
                    if authService.currentUser?.isVerified == true {
                        VerifiedBadge(size: 18)
                    }
                }

                Text("@\(authService.currentUser?.username ?? "")")
                    .font(LuminaFont.caption)
                    .foregroundStyle(.gray)

                // Опции
                VStack(spacing: 0) {
                    SettingsRow(icon: "gearshape", title: "Управление аккаунтом") {}
                    Divider().padding(.leading, 56)
                    SettingsRow(icon: "xmark.circle", title: "Деактивировать аккаунт", isDestructive: true, action: {
                        showDeactivateConfirm = true
                    })
                }
                .glassRounded(16)
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Аккаунт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .alert("Деактивировать аккаунт", isPresented: $showDeactivateConfirm) {
            Button("Деактивировать", role: .destructive) {}
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Ваш аккаунт будет деактивирован. Вы сможете восстановить его позже.")
        }
    }
}

// Destructive settings row
extension SettingsRow {
    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }
}
