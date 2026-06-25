import SwiftUI

/// Глобальные настройки приложения
struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirm = false
    @State private var showAdminPanel = false
    @State private var showAccount = false
    @State private var showAppearance = false
    @State private var showInteractions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top X close + title (exact match)
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 34, height: 34)
                                .glassCircle()
                        }
                        Spacer()
                        Text("Settings")
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        Color.clear.frame(width: 34, height: 34)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                    // Profile card at top (tappable to Account) - exact match to screenshots
                    Button {
                        showAccount = true
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(
                                imageURL: authService.currentUser?.avatarURL,
                                name: authService.currentUser?.fullName ?? "User",
                                size: 46
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.currentUser?.fullName ?? "Alex Smith")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(LuminaColor.textPrimary)
                                Text("@\(authService.currentUser?.username ?? "alexsmithmobb")")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassCard(radius: 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                    // App section
                    sectionHeader("App")
                    settingsCard {
                        SettingsRow(icon: "moon.circle.fill", title: "Appearance", action: { showAppearance = true })
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "photo.on.rectangle", title: "App Icon", action: { })
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "bell", title: "Notifications", action: { })
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "link", title: "Interactions", action: { showInteractions = true })
                    }

                    // XChat section
                    sectionHeader("XChat")
                    settingsCard {
                        SettingsRow(icon: "tray", title: "Message Requests") {}
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "key", title: "Change Passcode") {}
                    }

                    // Data & Information
                    sectionHeader("Data & Information")
                    settingsCard {
                        SettingsRow(icon: "externaldrive", title: "Storage") {}
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "chart.pie.fill", title: "Data Usage") {}
                    }

                    // Help, Legal, Troubleshooting
                    sectionHeader("Help")
                    settingsCard {
                        SettingsRow(icon: "questionmark.circle", title: "Help") {}
                    }

                    sectionHeader("Legal")
                    settingsCard {
                        SettingsRow(icon: "doc.text", title: "Legal") {}
                    }

                    sectionHeader("Troubleshooting")
                    settingsCard {
                        SettingsRow(icon: "wrench", title: "Troubleshooting") {}
                    }

                    // Red Sign Out (matches screenshots)
                    Button(action: { showSignOutConfirm = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 19))
                            Text("Sign Out")
                                .font(.system(size: 17))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .glassCard(radius: 18)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Text("Version \(Constants.appVersion)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                        .padding(.bottom, 30)

                    if isDurov {
                        sectionHeader("Platform")
                        settingsCard {
                            SettingsRow(icon: "shield", title: "Admin Panel") {
                                showAdminPanel = true
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(LuminaColor.backgroundMain.ignoresSafeArea())
            .sheet(isPresented: $showAccount) {
                AccountView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showAppearance) {
                AppearanceView()
            }
            .sheet(isPresented: $showInteractions) {
                InteractionsView()
            }
            .sheet(isPresented: $showAdminPanel) {
                AdminPanelView()
                    .presentationDetents([.large])
            }
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) { authService.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var isDurov: Bool {
        authService.currentUser?.username.lowercased() == "durov"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 6)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .glassCard(radius: 20)
        .padding(.horizontal, 16)
    }
}

#Preview {
    SettingsView()
        .environment(AuthService.shared)
}
