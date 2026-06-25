import SwiftUI

/// Экран аккаунта пользователя
struct AccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeactivateConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Spacer().frame(height: 6)

                // Large centered avatar exactly like screenshot
                AvatarView(
                    imageURL: authService.currentUser?.avatarURL,
                    name: authService.currentUser?.fullName ?? "User",
                    size: 104
                )

                Text(authService.currentUser?.fullName ?? "Alex Sam")
                    .font(.system(size: 22, weight: .semibold))

                Text("@\(authService.currentUser?.username ?? "salmobbin")")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Spacer().frame(height: 18)

                // Glass card with actions
                VStack(spacing: 0) {
                    SettingsRow(icon: "gearshape", title: "Manage account") {}
                    Divider().padding(.leading, 52)
                    SettingsRow(icon: "xmark.circle", title: "Deactivate account", isDestructive: true, action: {
                        showDeactivateConfirm = true
                    })
                }
                .glassCard(radius: 20)
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(LuminaColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .glassCircle()
                    }
                }
            }
        }
        .alert("Deactivate account", isPresented: $showDeactivateConfirm) {
            Button("Deactivate", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account will be deactivated. You can restore it later.")
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
