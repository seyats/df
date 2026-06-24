import SwiftUI

/// Экран 8: «Создайте PIN-код»
enum PINMode {
    case create
    case confirm(String)
    case verify
}

struct PINCreateView: View {
    @Binding var pin: String
    let mode: PINMode
    var onComplete: () -> Void

    @State private var enteredPin = ""
    @State private var confirmPin = ""
    @State private var errorShake = false

    private let pinLength = 4

    var body: some View {
        VStack(spacing: 0) {
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer().frame(height: 40)

            // Иконка замка
            Image(systemName: "lock.open")
                .font(.system(size: 48))
                .foregroundStyle(LuminaColor.textPrimary)
                .padding(.bottom, 24)

            // Заголовок
            Text(titleText)
                .font(LuminaFont.h3)
                .foregroundStyle(LuminaColor.textPrimary)

            Text(instructionText)
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)

            // 4 круга
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    ZStack {
                        Circle()
                            .stroke(
                                enteredPin.count > index
                                ? LuminaColor.textPrimary
                                : Color.gray.opacity(0.4),
                                lineWidth: 2
                            )
                            .frame(width: 48, height: 48)

                        if enteredPin.count > index {
                            Circle()
                                .fill(LuminaColor.textPrimary)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding(.top, 40)
            .modifier(ShakeEffect(shakes: errorShake ? 2 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.3), value: errorShake)

            Spacer()

            // Клавиатура
            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 40) {
                        ForEach(0..<3) { col in
                            let digit = row * 3 + col + 1
                            Button(action: { enterDigit(digit) }) {
                                Text("\(digit)")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(LuminaColor.textPrimary)
                                    .frame(width: 72, height: 56)
                                    .glassCapsule(interactive: true)
                            }
                        }
                    }
                }
                HStack(spacing: 40) {
                    // Пустая (или Face ID)
                    Button(action: {}) {
                        Image(systemName: "faceid")
                            .font(.system(size: 22))
                            .foregroundStyle(LuminaColor.textPrimary)
                            .frame(width: 72, height: 56)
                            .glassCapsule(interactive: true)
                    }

                    Button(action: { enterDigit(0) }) {
                        Text("0")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(LuminaColor.textPrimary)
                            .frame(width: 72, height: 56)
                            .glassCapsule(interactive: true)
                    }

                    // Удалить
                    Button(action: { deleteDigit() }) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 20))
                            .foregroundStyle(.gray)
                            .frame(width: 72, height: 56)
                            .glassCapsule(interactive: true)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(LuminaColor.backgroundMain)
    }

    private var titleText: String {
        switch mode {
        case .create: return "Создайте PIN-код"
        case .confirm: return "Подтвердите PIN-код"
        case .verify: return "Введите PIN-код"
        }
    }

    private var instructionText: String {
        switch mode {
        case .create:
            return "Этот PIN-код должен быть легко запоминающимся и храниться в секрете. Без него вы не сможете получить доступ к сообщениям."
        case .confirm:
            return "Введите PIN-код ещё раз для подтверждения."
        case .verify:
            return "Введите ваш PIN-код для входа."
        }
    }

    private func enterDigit(_ digit: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard enteredPin.count < pinLength else { return }
        enteredPin += "\(digit)"

        if enteredPin.count == pinLength {
            handleComplete()
        }
    }

    private func deleteDigit() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard !enteredPin.isEmpty else { return }
        enteredPin.removeLast()
    }

    private func handleComplete() {
        switch mode {
        case .create:
            pin = enteredPin
            // For now, auto-complete - in real app, would move to confirm
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        case .confirm(let originalPin):
            if enteredPin == originalPin {
                pin = enteredPin
                onComplete()
            } else {
                enteredPin = ""
                errorShake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    errorShake = false
                }
            }
        case .verify:
            let savedPin = KeychainService.shared.pinCode ?? ""
            if enteredPin == savedPin || enteredPin == pin {
                onComplete()
            } else {
                enteredPin = ""
                errorShake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    errorShake = false
                }
            }
        }
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var amplitude: CGFloat = 10

    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amplitude * sin(CGFloat(shakes) * .pi), y: 0)
        )
    }
}
