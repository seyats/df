import SwiftUI

/// Экран 3: «Введите код» (OTP)
struct OTPView: View {
    @Binding var code: String
    let phone: String
    @Binding var isLoading: Bool
    var onVerify: () -> Void
    var onResend: () -> Void
    @StateObject private var otpStore = LocalOTPStore.shared

    @FocusState private var isFocused: Bool

    private let codeLength = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(LuminaColor.textPrimary)
                }
                .glassCircle(interactive: true)
                .frame(width: 44, height: 44)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Text("Введите код, который мы отправили вам")
                .font(LuminaFont.h2)
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.top, 48)
                .padding(.horizontal, 16)

            Text("Мы отправили его на \(phone) для подтверждения.")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Локальный режим: показываем код прямо на экране, так как SMS не отправляется.
            if otpStore.isLocalMode, let codeHint = otpStore.lastCode {
                Button(action: {
                    code = codeHint
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Локальный режим — SMS не отправляется")
                                .font(LuminaFont.caption)
                                .foregroundStyle(LuminaColor.textPrimary)
                            Text("Код: \(codeHint) — нажмите, чтобы подставить")
                                .font(LuminaFont.micro)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .buttonStyle(.plain)
            }

            // 6 ячеек
            HStack(spacing: 12) {
                ForEach(0..<codeLength, id: \.self) { index in
                    OTPCell(
                        value: character(at: index),
                        isActive: code.count == index
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .overlay(
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .opacity(0.001)
                    .onChange(of: code) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= codeLength {
                            code = filtered
                        } else {
                            code = String(filtered.prefix(codeLength))
                        }
                        if code.count == codeLength {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onVerify()
                        }
                    }
            )
            .onAppear { isFocused = true }

            // Повторная отправка
            HStack(spacing: 4) {
                Text("Не пришло?")
                    .font(LuminaFont.caption)
                    .foregroundStyle(.gray)
                Button("Отправить повторно") {
                    onResend()
                }
                .font(LuminaFont.caption)
                .foregroundStyle(LuminaColor.accentBlue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()

            Button(action: onVerify) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Продолжить")
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                code.count == codeLength ? LuminaColor.accentBlue : Color.gray.opacity(0.3),
                in: Capsule()
            )
            .disabled(code.count != codeLength || isLoading)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .buttonAnimation()
        }
        .background(LuminaColor.backgroundMain)
    }

    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return code[code.index(code.startIndex, offsetBy: index)]
    }
}

// MARK: - Ячейка OTP
struct OTPCell: View {
    let value: Character?
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .frame(width: 48, height: 56)
            .overlay(
                Group {
                    if let value = value {
                        Text(String(value))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? LuminaColor.accentBlue : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
            )
            .ifAvailable(iOS: 26) { view in
                if #available(iOS 26.0, *) {
                    view.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    view
                }
            }
    }
}

// MARK: - Условный модификатор
extension View {
    @ViewBuilder
    func ifAvailable<Content: View>(iOS version: Int, @ViewBuilder transform: (Self) -> Content) -> some View {
        if #available(iOS 26, *) {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    OTPView(
        code: .constant("123"),
        phone: "+79161234567",
        isLoading: .constant(false),
        onVerify: {},
        onResend: {}
    )
}
