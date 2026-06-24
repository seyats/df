import SwiftUI

/// Настройки группы: медиа, таймер, скриншоты, участники
struct GroupSettingsView: View {
    let chatName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isMuted = false
    @State private var disappearTime = 0 // 0 = выкл
    @State private var screenshotBlocked = false
    @State private var showDisappearPicker = false
    @State private var showClearChat = false

    let disappearOptions: [(String, Int)] = [
        ("Выкл", 0),
        ("5 минут", 300),
        ("1 час", 3600),
        ("8 часов", 28800),
        ("1 день", 86400),
        ("1 неделя", 604800),
        ("4 недели", 2419200)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Аватарка и название
                    VStack(spacing: 8) {
                        AvatarView(imageURL: nil, name: chatName, size: 100)
                        Text(chatName)
                            .font(LuminaFont.h3)
                            .foregroundStyle(LuminaColor.textPrimary)
                        Text("2 участника")
                            .font(LuminaFont.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 20)

                    // Быстрые действия
                    HStack(spacing: 16) {
                        CapsuleButton(icon: "person.badge.plus", label: "Добавить") {}
                        CapsuleButton(icon: isMuted ? "bell.slash" : "bell", label: isMuted ? "Вкл. звук" : "Выкл. звук") {
                            isMuted.toggle()
                        }
                        CapsuleButton(icon: "ellipsis", label: "Ещё") {}
                    }
                    .padding(.horizontal, 16)

                    // Настройки
                    settingsCard {
                        SettingsRow(icon: "photo.on.rectangle", title: "Общие медиа") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "timer", title: "Исчезающие сообщения", value: disappearTimeName) {
                            showDisappearPicker = true
                        }
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "rectangle.on.rectangle.slash", title: "Блокировка скриншотов", isToggle: true, toggleValue: $screenshotBlocked)
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "link", title: "Ссылка для приглашения") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "person.2.fill", title: "Добавить участников") {}
                    }

                    // Участники
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Участники")
                            .font(LuminaFont.caption)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        settingsCard {
                            ParticipantRow(name: "Алекс Сэм", role: "Админ", isAdmin: true) {}
                            Divider().padding(.leading, 56)
                            ParticipantRow(name: "Алекс", role: "", isAdmin: false) {}
                        }
                    }

                    // Очистить чат
                    Button(action: { showClearChat = true }) {
                        HStack {
                            Spacer()
                            Text("Очистить чат")
                                .font(LuminaFont.body)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .glassRounded(16)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(LuminaColor.backgroundMain)
            .navigationTitle("Настройки группы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .sheet(isPresented: $showDisappearPicker) {
            DisappearPickerView(selected: $disappearTime, options: disappearOptions)
                .presentationDetents([.medium])
        }
        .confirmationDialog("Очистить чат", isPresented: $showClearChat) {
            Button("Очистить сообщения", role: .destructive) {}
            Button("Оставить сообщения", role: .cancel) {}
        } message: {
            Text("Вы хотите очистить все сообщения в этой беседе? Они будут навсегда удалены только с ваших устройств.")
        }
    }

    private var disappearTimeName: String {
        disappearOptions.first { $0.1 == disappearTime }?.0 ?? "Выкл"
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .glassRounded(16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Вспомогательные компоненты
struct CapsuleButton: View {
    let icon: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(LuminaColor.textPrimary)
                Text(label)
                    .font(LuminaFont.micro)
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .glassRounded(16)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var isToggle: Bool = false
    var toggleValue: Binding<Bool>? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { if !isToggle { action?() } }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(LuminaColor.textPrimary)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 18))
                    .foregroundStyle(LuminaColor.textPrimary)

                Spacer()

                if isToggle, let binding = toggleValue {
                    Toggle("", isOn: binding)
                        .labelsHidden()
                        .tint(LuminaColor.accentBlue)
                } else if let value = value {
                    Text(value)
                        .font(LuminaFont.body)
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
        }
    }
}

struct ParticipantRow: View {
    let name: String
    let role: String
    var isAdmin: Bool
    var action: () -> Void

    @State private var showMenu = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageURL: nil, name: name, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(LuminaFont.body)
                    .foregroundStyle(LuminaColor.textPrimary)
                if !role.isEmpty {
                    Text(role)
                        .font(LuminaFont.micro)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            Button(action: { showMenu = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
            }
            .glassCircle(interactive: true)
            .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .confirmationDialog("Управление участником", isPresented: $showMenu) {
            Button("Установить никнейм") {}
            Button("Сделать администратором") {}
            Button("Удалить из группы", role: .destructive) {}
        }
    }
}

// MARK: - Исчезающие сообщения пикер
struct DisappearPickerView: View {
    @Binding var selected: Int
    let options: [(String, Int)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options, id: \.1) { option in
                Button(action: {
                    selected = option.1
                    dismiss()
                }) {
                    HStack {
                        Text(option.0)
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                        Spacer()
                        if selected == option.1 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(LuminaColor.accentBlue)
                        }
                    }
                }
            }
            .navigationTitle("Исчезающие сообщения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    GroupSettingsView(chatName: "ASMobbin")
}
