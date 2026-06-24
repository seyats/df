import SwiftUI

/// Единая цветовая палитра LUMINA.
/// Поддерживает светлую и тёмную темы через @Environment(\.colorScheme).
enum LuminaColor {
    // MARK: - Фоны
    static let backgroundMain = Color("BackgroundMain") // #F2F2F7 light / #1C1C1E dark
    static let backgroundWhite = Color("BackgroundWhite") // #FFFFFF light / #2C2C2E dark
    static let messageReceived = Color("MessageReceivedGray") // #E9E9EB light / #3A3A3C dark
    static let inputBarBackground = Color("InputBarBackground") // стеклянный фон панели ввода

    // MARK: - Акценты
    static let accentBlue = Color("AccentBlue") // #1B90FF
    static let errorRed = Color.red

    // MARK: - Текст
    static let textPrimary = Color("TextPrimary") // #000000 light / #FFFFFF dark
    static let textSecondary = Color.gray.opacity(0.8)

    // MARK: - Верификация
    static let verifiedBadge = Color("AccentBlue") // #1B90FF
}

extension ShapeStyle where Self == Color {
    static var luminaBackground: Color { LuminaColor.backgroundMain }
    static var luminaWhite: Color { LuminaColor.backgroundWhite }
    static var luminaAccent: Color { LuminaColor.accentBlue }
    static var luminaText: Color { LuminaColor.textPrimary }
    static var luminaTextSecondary: Color { LuminaColor.textSecondary }
    static var luminaMessageReceived: Color { LuminaColor.messageReceived }
}
