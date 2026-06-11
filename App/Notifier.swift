import Foundation
import UserNotifications
import UnquarantineCore

enum Notifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func notify(_ result: AppleScriptResult, count: Int) {
        // The user dismissed the password dialog themselves — no notification needed.
        if case .cancelled = result { return }

        let content = UNMutableNotificationContent()
        content.title = "Unquarantine"
        content.body = result.message(count: count)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
