import SwiftUI

/// Нижняя навигация: сдвоенная капсула (Главное + Чаты) + лупа
struct BottomNavBar: View {
    @Binding var selectedTab: RootView.Tab
    let unreadCount: Int
    var onSearchTap: () -> Void
    var onProfileTap: () -> Void

    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 16) {
            // Сдвоенная стеклянная капсула
            HStack(spacing: 0) {
                // Кнопка "Главное"
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = .home
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaColor.textPrimary)

                        Text("Главное")
                            .font(LuminaFont.micro)
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                    .frame(width: 80)
                }

                // Кнопка "Чаты" с бейджиком
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = .chats
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(LuminaColor.textPrimary)

                            // Бейджик
                            if unreadCount > 0 {
                                Text("\(min(unreadCount, 99))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(LuminaColor.accentBlue, in: Circle())
                                    .offset(x: 10, y: -10)
                                    .transition(.scale(scale: 0).combined(with: .opacity))
                            }
                        }

                        Text("Чаты")
                            .font(LuminaFont.micro)
                            .foregroundStyle(LuminaColor.textPrimary)
                    }
                    .frame(width: 80)
                }
            }
            .frame(height: 60)
            .glassCapsule(interactive: true)

            if selectedTab == .chats {
                Color.clear.frame(width: 0, height: 0)
            }

            // Круглая кнопка поиска
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSearchTap()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundStyle(LuminaColor.textPrimary)
                    .frame(width: 60, height: 60)
            }
            .glassCircle(interactive: true)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: unreadCount)
    }
}

#Preview {
    BottomNavBar(
        selectedTab: .constant(.chats),
        unreadCount: 12,
        onSearchTap: {},
        onProfileTap: {}
    )
    .padding()
    .background(LuminaColor.backgroundMain)
}
