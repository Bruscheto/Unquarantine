import Foundation
import UserNotifications
import UnquarantineCore

enum Notifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

@MainActor
struct NotificationRunReporter: RightClickRunReporting {
    private let deliver: @MainActor (String) -> Void

    init(deliver: @escaping @MainActor (String) -> Void = NotificationRunReporter.deliverNotification) {
        self.deliver = deliver
    }

    func report(_ result: AppleScriptResult, count: Int) {
        if case .cancelled = result { return }
        deliver(result.message(count: count))
    }

    private static func deliverNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Unquarantine"
        content.body = message
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
