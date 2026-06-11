import AppKit
import FinderSync
import Foundation
import UserNotifications

@MainActor
final class PermissionsModel: ObservableObject {
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in self.notificationStatus = settings.authorizationStatus }
        }
    }

    /// Opens System Settings to the Finder extension management list.
    func openExtensionSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    /// Shows the system notification prompt (only effective while status is .notDetermined).
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            Task { @MainActor in self.refresh() }
        }
    }

    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
