import SwiftUI

/// Глобальные настройки приложения
struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirm = false
    @State private var showAdminPanel = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Профиль
                    profileSection

                    // Раздел «Приложение»
                    sectionHeader("Приложение")
                    settingsCard {
                        SettingsRow(icon: "paintbrush", title: "Оформление") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "app.gift", title: "Иконка приложения") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "bell", title: "Уведомления") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "hand.point.up.left", title: "Жесты") {}
                    }

                    // Раздел «LUMINA»
                    sectionHeader("LUMINA")
                    settingsCard {
                        SettingsRow(icon: "tray", title: "Запросы сообщений") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "key", title: "Сменить PIN-код") {}
                    }

                    // Раздел «Данные и Информация»
                    sectionHeader("Данные и Информация")
                    settingsCard {
                        SettingsRow(icon: "cylinder", title: "Хранилище") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "chart.pie", title: "Использование данных") {}
                    }

                    // Раздел «Поддержка»
                    sectionHeader("Поддержка")
                    settingsCard {
                        SettingsRow(icon: "questionmark.circle", title: "Помощь") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "doc.text", title: "Правовая информация") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "wrench", title: "Устранение неполадок") {}
                    }

                    // Админ-панель (только для durov)
                    if isDurov {
                        sectionHeader("Управление платформой")
                        settingsCard {
                            SettingsRow(icon: "shield.checkerboard", title: "Обзор системы") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "person.2.fill", title: "Все пользователи") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Активные чаты") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "flag", title: "Жалобы и модерация") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "lock.shield.fill", title: "Безопасность") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "gearshape.2.fill", title: "Настройки платформы") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "doc.text.magnifyingglass", title: "Логи и мониторинг") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "chart.line.uptrend.xyaxis", title: "Аналитика") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "megaphone.fill", title: "Массовое уведомление") {
                                showAdminPanel = true
                            }
                            Divider().padding(.leading, 56)
                            SettingsRow(icon: "square.and.arrow.up", title: "Экспорт данных") {
                                showAdminPanel = true
                            }
                        }
                    }

                    // Выход
                    Button(action: { showSignOutConfirm = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 22))
                            Text("Выйти")
                                .font(.system(size: 18))
                        }
                        .foregroundStyle(.red)
                    }
                    .padding(.top, 20)

                    Text("Версия \(Constants.appVersion)")
                        .font(LuminaFont.micro)
                        .foregroundStyle(.gray)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                }
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .alert("Выйти", isPresented: $showSignOutConfirm) {
            Button("Выйти", role: .destructive) {
                authService.signOut()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы уверены, что хотите выйти из аккаунта?")
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminPanelView()
                .presentationDetents([.large])
        }
    }

    // MARK: - Секция профиля
    private var profileSection: some View {
        VStack(spacing: 12) {
            AvatarView(
                imageURL: authService.currentUser?.avatarURL,
                name: authService.currentUser?.fullName ?? "Я",
                size: 80
            )

            HStack(spacing: 4) {
                Text(authService.currentUser?.fullName ?? "Пользователь")
                    .font(LuminaFont.h3)
                    .foregroundStyle(LuminaColor.textPrimary)

                if authService.currentUser?.isVerified == true {
                    VerifiedBadge(size: 18)
                }
            }

            Text("@\(authService.currentUser?.username ?? "username")")
                .font(LuminaFont.caption)
                .foregroundStyle(.gray)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var isDurov: Bool {
        authService.currentUser?.username.lowercased() == "durov"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(LuminaFont.caption)
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .glassRounded(16)
        .padding(.horizontal, 16)
    }
}

#Preview {
    SettingsView()
        .environment(AuthService.shared)
}
