import SwiftUI
import SwiftData

@main
struct LUMINAApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .preferredColorScheme(nil)
        }
        .modelContainer(for: [
            UserModel.self,
            ChatModel.self,
            MessageModel.self,
            ReportModel.self
        ])
    }
}
