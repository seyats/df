import Foundation
import UserNotifications
import UIKit
import Combine

/// Сервис пуш-уведомлений через APNs.
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var pushToken: String?
    @Published var pendingNotification: (chatID: String, message: String)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        pushToken = token
        // Отправляем токен на сервер (только если Supabase настроен).
        // В локальном режиме push-нотификации не нужны.
        guard Constants.isSupabaseConfigured else { return }
        Task {
            let body = ["push_token": token]
            let _ = try? await APIService.shared.updatePushToken(body: body)
        }
    }

    func scheduleLocalNotification(title: String, body: String, chatID: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["chat_id": chatID]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let chatID = userInfo["chat_id"] as? String {
            pendingNotification = (chatID, "")
        }
    }
}
