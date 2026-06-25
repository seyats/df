import SwiftUI

/// Нижняя навигация: сдвоенная капсула (Главное + Чаты) + лупа
struct BottomNavBar: View {
    @Binding var selectedTab: RootView.Tab
    let unreadCount: Int
    var onSearchTap: () -> Void
    var onProfileTap: () -> Void

    @Namespace private var tabAnimation

    var body: some View {
        if selectedTab == .chats {
            // Bottom bar exactly like screenshot 7 for Chat list
            HStack(spacing: 12) {
                // Filter
                Button {
                    // filter action
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 20))
                        .foregroundStyle(LuminaColor.textPrimary)
                        .frame(width: 38, height: 38)
                        .glassCircle()
                }

                // Search pill
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("Search")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.6))
                .onTapGesture {
                    onSearchTap()
                }

                Spacer()

                // Edit / compose
                Button(action: {
                    // edit / new chat action
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundStyle(LuminaColor.textPrimary)
                        .frame(width: 38, height: 38)
                        .glassCircle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        } else {
            // Original glass capsule for Home
            HStack(spacing: 16) {
                HStack(spacing: 0) {
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
                            Text("Home")
                                .font(LuminaFont.micro)
                                .foregroundStyle(LuminaColor.textPrimary)
                        }
                        .frame(width: 80)
                    }

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

                                if unreadCount > 0 {
                                    Text("\(min(unreadCount, 99))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 20, height: 20)
                                        .background(LuminaColor.accentBlue, in: Circle())
                                        .offset(x: 10, y: -10)
                                }
                            }
                            Text("Chat")
                                .font(LuminaFont.micro)
                                .foregroundStyle(LuminaColor.textPrimary)
                        }
                        .frame(width: 80)
                    }
                }
                .frame(height: 60)
                .glassCapsule(interactive: true)

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
        }
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
