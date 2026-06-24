import SwiftUI

/// Экран 2: «Введите номер телефона»
struct PhoneInputView: View {
    @Binding var phone: String
    @Binding var countryCode: String
    @Binding var isLoading: Bool
    var onContinue: () -> Void
    var errorMessage: String?

    @State private var showCountryPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Хедер
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(LuminaColor.textPrimary)
                }
                .glassCircle(interactive: true)
                .frame(width: 44, height: 44)

                Spacer()

                Button("Использовать email") {}
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Заголовок
            Text("Введите номер телефона")
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 48)
                .padding(.horizontal, 16)

            // Поле ввода
            HStack(spacing: 8) {
                // Флаг + код
                Button(action: { showCountryPicker = true }) {
                    HStack(spacing: 6) {
                        Text("🇷🇺")
                            .font(.system(size: 28))
                        Text(countryCode)
                            .font(LuminaFont.body)
                            .foregroundStyle(LuminaColor.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 12)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 28)

                TextField("9 123456789", text: $phone)
                    .font(LuminaFont.body)
                    .keyboardType(.numberPad)
                    .foregroundStyle(LuminaColor.textPrimary)
            }
            .frame(height: 56)
            .glassInput()
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Text("Продолжая, вы соглашаетесь получать транзакционные сообщения об аккаунте. Другие пользователи смогут найти вас по номеру телефона.")
                .font(LuminaFont.micro)
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Показ ошибок, чтобы пользователь видел, почему ничего не происходит.
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(LuminaFont.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Кнопка "Продолжить"
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onContinue()
            }) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Продолжить")
                        .font(LuminaFont.body)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                phone.sanitizedPhone.count >= Constants.phoneNumberDigits
                ? LuminaColor.accentBlue
                : Color.gray.opacity(0.3),
                in: Capsule()
            )
            .disabled(phone.sanitizedPhone.count < Constants.phoneNumberDigits || isLoading)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCode: $countryCode)
        }
    }
}

// MARK: - Выбор страны
struct CountryPickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss

    let countries: [(flag: String, name: String, code: String)] = [
        ("🇷🇺", "Россия", "+7"),
        ("🇺🇸", "США", "+1"),
        ("🇩🇪", "Германия", "+49"),
        ("🇫🇷", "Франция", "+33"),
        ("🇬🇧", "Великобритания", "+44"),
        ("🇺🇦", "Украина", "+380"),
        ("🇧🇾", "Беларусь", "+375"),
        ("🇰🇿", "Казахстан", "+7"),
        ("🇹🇷", "Турция", "+90"),
        ("🇮🇹", "Италия", "+39"),
    ]

    var body: some View {
        NavigationStack {
            List(countries, id: \.code) { country in
                Button(action: {
                    selectedCode = country.code
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.name)
                                .font(LuminaFont.body)
                                .foregroundStyle(LuminaColor.textPrimary)
                            Text(country.code)
                                .font(LuminaFont.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        if selectedCode == country.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(LuminaColor.accentBlue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Выберите страну")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PhoneInputView(
        phone: .constant(""),
        countryCode: .constant("+7"),
        isLoading: .constant(false),
        onContinue: {},
        errorMessage: .constant(nil)
    )
}
