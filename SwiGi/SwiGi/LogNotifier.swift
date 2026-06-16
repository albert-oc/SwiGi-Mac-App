import Foundation
import os
import UserNotifications

@MainActor
final class LogNotifier {
    static let shared = LogNotifier()

    private var authorized = false

    func requestAuthorization() async {
        do {
            authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            authorized = false
        }
    }

    func notify(message: String, level: OSLogType) {
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "SwiGi"
        content.body = message
        if level == .error || level == .fault {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
