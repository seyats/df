import SwiftUI

/// Профиль другого пользователя
struct ContactProfileView: View {
    let userName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showBlockConfirm = false
    @State private var showReportConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isBlocked = false
    @State private var disappearingTime = 0
    @State private var screenshotBlocked = false
    @State private var showDisappearPicker = false

    let disappearOptions: [(String, Int)] = [
        ("Выкл", 0), ("5 минут", 300), ("1 час", 3600),
        ("8 часов", 28800), ("1 день", 86400), ("1 неделя", 604800), ("4 недели", 2419200)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Хедер
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(LuminaColor.textPrimary)
                        }
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "pencil")
                                .foregroundStyle(LuminaColor.textPrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Аватар + имя
                    VStack(spacing: 8) {
                        AvatarView(imageURL: nil, name: userName, size: 100)
                        Text(userName)
                            .font(LuminaFont.h3)
                            .foregroundStyle(LuminaColor.textPrimary)
                        Text("@alexsmithmobb")
                            .font(LuminaFont.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 10)

                    // Быстрые действия
                    HStack(spacing: 16) {
                        CircleButton(icon: "person", label: "Профиль") {}
                        CircleButton(icon: "ellipsis", label: "Ещё") {
                            showBlockConfirm = true
                        }
                    }
                    .padding(.horizontal, 16)

                    // Настройки
                    VStack(spacing: 0) {
                        SettingsRow(icon: "photo.on.rectangle", title: "Общие медиа") {}
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "timer", title: "Исчезающие сообщения", value: disappearOptions.first { $0.1 == disappearingTime }?.0 ?? "Выкл") {
                            showDisappearPicker = true
                        }
                        Divider().padding(.leading, 56)
                        SettingsRow(icon: "rectangle.on.rectangle.slash", title: "Блокировка скриншотов", isToggle: true, toggleValue: $screenshotBlocked)
                    }
                    .glassRounded(16)
                    .padding(.horizontal, 16)
                }
            }
            .background(LuminaColor.backgroundMain)
        }
        .sheet(isPresented: $showDisappearPicker) {
            DisappearPickerView(selected: $disappearingTime, options: disappearOptions)
                .presentationDetents([.medium])
        }
        .confirmationDialog("Ещё", isPresented: $showBlockConfirm) {
            Button(isBlocked ? "Разблокировать сообщения" : "Заблокировать сообщения", role: .destructive) {
                isBlocked.toggle()
            }
            Button("Пожаловаться на пользователя", role: .destructive) {
                showReportConfirm = true
            }
            Button("Удалить чат", role: .destructive) {
                showDeleteConfirm = true
            }
        }
        .alert("Заблокировать сообщения", isPresented: $showReportConfirm) {
            Button("Заблокировать", role: .destructive) { isBlocked = true }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы больше не будете получать сообщения от этого пользователя.")
        }
        .alert("Удалить чат", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {}
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все сообщения будут удалены.")
        }
    }
}

struct CircleButton: View {
    let icon: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(LuminaColor.textPrimary)
                    .frame(width: 56, height: 56)
                Text(label)
                    .font(LuminaFont.micro)
                    .foregroundStyle(LuminaColor.textPrimary)
            }
        }
        .glassCircle(interactive: true)
    }
}
