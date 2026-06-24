import SwiftUI

/// Админ-панель — 10 разделов управления платформой (только для durov)
struct AdminPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: AdminSection = .dashboard

    enum AdminSection: String, CaseIterable {
        case dashboard = "Обзор системы"
        case users = "Все пользователи"
        case chats = "Активные чаты"
        case moderation = "Жалобы и модерация"
        case security = "Безопасность"
        case settings = "Настройки платформы"
        case logs = "Логи и мониторинг"
        case analytics = "Аналитика"
        case notifications = "Массовое уведомление"
        case export = "Экспорт данных"
    }

    var body: some View {
        NavigationStack {
            List(AdminSection.allCases, id: \.rawValue) { section in
                Button(action: { selectedSection = section }) {
                    AdminSectionRow(section: section)
                }
            }
            .listStyle(.plain)
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Управление платформой")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .sheet(isPresented: .constant(true)) {
            adminContent
        }
    }

    @ViewBuilder
    private var adminContent: some View {
        switch selectedSection {
        case .dashboard:
            AdminDashboardView()
        case .users:
            AdminUsersView()
        case .chats:
            AdminChatsView()
        case .moderation:
            AdminModerationView()
        case .security:
            AdminSecurityView()
        case .settings:
            AdminPlatformSettingsView()
        case .logs:
            AdminLogsView()
        case .analytics:
            AdminAnalyticsView()
        case .notifications:
            AdminMassNotificationView()
        case .export:
            AdminExportView()
        }
    }
}

// MARK: - Строка раздела
struct AdminSectionRow: View {
    let section: AdminPanelView.AdminSection

    var icon: String {
        switch section {
        case .dashboard: return "shield.checkerboard"
        case .users: return "person.2.fill"
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .moderation: return "flag"
        case .security: return "lock.shield.fill"
        case .settings: return "gearshape.2.fill"
        case .logs: return "doc.text.magnifyingglass"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .notifications: return "megaphone.fill"
        case .export: return "square.and.arrow.up"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(LuminaColor.textPrimary)
                .frame(width: 28)
            Text(section.rawValue)
                .font(.system(size: 18))
                .foregroundStyle(LuminaColor.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 4)
        .frame(height: 56)
    }
}

// MARK: - 1. Обзор системы
struct AdminDashboardView: View {
    @State private var stats: [String: Any] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Метрики
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StatCard(title: "Онлайн", value: "0", icon: "circle.fill", color: .green)
                        StatCard(title: "Пользователей", value: "0", icon: "person.2.fill", color: LuminaColor.accentBlue)
                        StatCard(title: "Сообщений сегодня", value: "0", icon: "message.fill", color: .orange)
                        StatCard(title: "Активных групп", value: "0", icon: "bubble.left.and.bubble.right.fill", color: .purple)
                    }
                    .padding(.horizontal, 16)

                    // График
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Активность за 7 дней")
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                            .padding(.horizontal, 16)
                        MiniChartView()
                            .frame(height: 160)
                            .glassRounded(16)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Обзор системы")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    let result = try? await APIService.shared.adminGetStats()
                    if let r = result { stats = r }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(value)
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
            Text(title)
                .font(LuminaFont.micro)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassRounded(16)
    }
}

struct MiniChartView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    let points: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.5]
                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    for (i, p) in points.enumerated() {
                        let x = width * CGFloat(i) / CGFloat(points.count - 1)
                        let y = height * (1 - p)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(LuminaColor.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .padding(16)
            }
        }
    }
}

// MARK: - 2. Все пользователи
struct AdminUsersView: View {
    @State private var users: [UserModel] = []
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredUsers, id: \.id) { user in
                HStack(spacing: 12) {
                    AvatarView(imageURL: user.avatarURL, name: user.fullName, size: 44, showOnlineDot: true, isOnline: user.isOnline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullName)
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                        Text("@\(user.username)")
                            .font(LuminaFont.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    if user.isBlocked {
                        Image(systemName: "hand.raised.slash")
                            .foregroundStyle(.red)
                    }
                }
                .contextMenu {
                    Button("Просмотреть") {}
                    Button("Уведомить") {}
                    Button("Заблокировать", role: .destructive) {}
                    Button("Удалить", role: .destructive) {}
                }
            }
            .listStyle(.plain)
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Поиск пользователей")
            .navigationTitle("Все пользователи")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    if let result = try? await APIService.shared.adminFetchAllUsers() {
                        users = result
                    }
                }
            }
        }
    }

    private var filteredUsers: [UserModel] {
        if searchText.isEmpty { return users }
        return users.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - 3. Активные чаты
struct AdminChatsView: View {
    @State private var chats: [ChatModel] = []

    var body: some View {
        NavigationStack {
            List(chats) { chat in
                ChatRow(chat: chat, currentUserID: "")
                    .contextMenu {
                        Button("Просмотреть") {}
                        Button("Удалить", role: .destructive) {}
                    }
            }
            .listStyle(.plain)
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Активные чаты")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 4. Жалобы и модерация
struct AdminModerationView: View {
    @State private var reports: [ReportModel] = []

    var body: some View {
        NavigationStack {
            List(reports) { report in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Жалоба #\(report.id.prefix(8))")
                        .font(LuminaFont.body)
                        .foregroundStyle(LuminaColor.textPrimary)
                    Text(report.reason)
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                    HStack(spacing: 8) {
                        Text(report.status.rawValue)
                            .font(LuminaFont.micro)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                report.status == .pending ? Color.orange.opacity(0.2) : Color.green.opacity(0.2)
                            )
                            .clipShape(Capsule())
                    }
                }
                .contextMenu {
                    Button("Удалить сообщение") {}
                    Button("Предупреждение") {}
                    Button("Заблокировать", role: .destructive) {}
                    Button("Отклонить") {}
                }
            }
            .listStyle(.plain)
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Жалобы и модерация")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    if let result = try? await APIService.shared.adminFetchReports() {
                        reports = result
                    }
                }
            }
        }
    }
}

// MARK: - 5. Безопасность
struct AdminSecurityView: View {
    @State private var registrationEnabled = true
    @State private var emergencyLockdown = false

    var body: some View {
        NavigationStack {
            List {
                Section("Аутентификация") {
                    Toggle("Регистрация открыта", isOn: $registrationEnabled)
                    Toggle("Экстренная блокировка", isOn: $emergencyLockdown)
                }
                Section("Журнал входа") {
                    Text("Последний вход: сегодня, 12:34")
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                }
            }
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Безопасность")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 6. Настройки платформы
struct AdminPlatformSettingsView: View {
    @State private var maxParticipants = 256
    @State private var maxFileSize = 100
    @State private var retentionDays = 30
    @State private var maintenanceMode = false

    var body: some View {
        NavigationStack {
            List {
                Section("Ограничения") {
                    HStack {
                        Text("Макс. участников")
                        Spacer()
                        Text("\(maxParticipants)")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Макс. размер файла (МБ)")
                        Spacer()
                        Text("\(maxFileSize)")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Срок хранения (дней)")
                        Spacer()
                        Text("\(retentionDays)")
                            .foregroundStyle(.gray)
                    }
                }
                Section {
                    Toggle("Режим обслуживания", isOn: $maintenanceMode)
                }
            }
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Настройки платформы")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 7. Логи и мониторинг
struct AdminLogsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Ошибки") {
                    Text("Нет критических ошибок")
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                }
                Section("Действия администратора") {
                    Text("Журнал пуст")
                        .font(LuminaFont.caption)
                        .foregroundStyle(.gray)
                }
                Section("Мониторинг сервера") {
                    HStack {
                        Text("CPU")
                        Spacer()
                        Text("12%").foregroundStyle(.green)
                    }
                    HStack {
                        Text("RAM")
                        Spacer()
                        Text("45%").foregroundStyle(.orange)
                    }
                    HStack {
                        Text("WebSocket")
                        Spacer()
                        Text("Активен").foregroundStyle(.green)
                    }
                }
            }
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Логи и мониторинг")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 8. Аналитика
struct AdminAnalyticsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MiniChartView()
                        .frame(height: 200)
                        .glassRounded(16)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Топ-10 пользователей")
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                        ForEach(1...5, id: \.self) { _ in
                            HStack {
                                AvatarView(imageURL: nil, name: "Пользователь", size: 36)
                                VStack(alignment: .leading) {
                                    Text("Пользователь").font(LuminaFont.body)
                                    Text("100 сообщений").font(LuminaFont.caption).foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .glassRounded(16)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 9. Массовое уведомление
struct AdminMassNotificationView: View {
    @State private var title = ""
    @State private var bodyText = ""
    @State private var target = "all"
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Заголовок") {
                    TextField("Заголовок уведомления", text: $title)
                }
                Section("Текст") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 100)
                }
                Section("Целевая аудитория") {
                    Picker("Аудитория", selection: $target) {
                        Text("Все").tag("all")
                        Text("Активные").tag("active")
                        Text("Неактивные").tag("inactive")
                    }
                }
                Section {
                    Button(action: sendNotification) {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Отправить")
                        }
                    }
                    .disabled(title.isEmpty || bodyText.isEmpty)
                }
            }
            .navigationTitle("Массовое уведомление")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendNotification() {
        isSending = true
        Task {
            try? await APIService.shared.adminSendMassNotification(
                title: title,
                body: bodyText,
                target: target
            )
            await MainActor.run { isSending = false }
        }
    }
}

// MARK: - 10. Экспорт данных
struct AdminExportView: View {
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            List {
                Section("Экспорт статистики") {
                    Button("CSV") { export(format: "csv") }
                    Button("JSON") { export(format: "json") }
                }
                Section {
                    Button("Очистить кэш", role: .destructive) {
                        // Clear cache
                    }
                }
            }
            .background(LuminaColor.backgroundMain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Экспорт данных")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func export(format: String) {
        isExporting = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { isExporting = false }
        }
    }
}
