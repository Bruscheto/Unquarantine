import Foundation
import UserNotifications
import UnquarantineCore

enum Notifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func notify(_ result: AppleScriptResult, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Unquarantine"
        switch result {
        case .success:
            content.body = "Done \u{2014} processed \(count) item\(count == 1 ? "" : "s")."
        case .cancelled:
            content.body = "Cancelled."
        case .failed(let reason):
            content.body = "Failed: \(reason)"
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
