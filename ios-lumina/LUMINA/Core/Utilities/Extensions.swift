import SwiftUI
import UIKit

// MARK: - View + тактильная обратная связь
extension View {
    func withHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    func buttonAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
    }
}

// MARK: - View + скрытие клавиатуры
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - String + валидация
extension String {
    var isValidPhoneNumber: Bool {
        let digits = self.filter { $0.isNumber }
        return digits.count >= Constants.phoneNumberDigits
    }

    var sanitizedPhone: String {
        self.filter { $0.isNumber }
    }

    var isValidPassword: Bool {
        self.count >= Constants.minPasswordLength
    }

    var isValidUsername: Bool {
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9_]{3,32}$")
        return regex?.firstMatch(in: self, range: NSRange(location: 0, length: self.utf16.count)) != nil
    }
}

// MARK: - Date + форматирование
extension Date {
    var chatTimeString: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Вчера"
        } else {
            formatter.dateFormat = "dd.MM"
        }
        return formatter.string(from: self)
    }

    var messageTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Color + hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
