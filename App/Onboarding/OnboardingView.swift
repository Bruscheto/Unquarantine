import AppKit
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var permissions: PermissionsModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("Welcome to Unquarantine")
                    .font(.title2).bold()
                Text("Two quick steps to get the right-click action working.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // No public API exposes whether the Finder extension is enabled, so this
            // step has no live checkmark — we just provide the button.
            PermissionRow(
                index: 1,
                title: "Enable the Finder extension",
                detail: "Adds \u{201C}Remove Quarantine & Re-sign\u{201D} to Finder\u{2019}s right-click menu.",
                isDone: false,
                buttonTitle: "Open Extension Settings",
                buttonDisabled: false,
                action: permissions.openExtensionSettings
            )

            PermissionRow(
                index: 2,
                title: "Allow notifications",
                detail: "So you get a result after each run.",
                isDone: isNotificationsAuthorized,
                buttonTitle: notificationButtonTitle,
                buttonDisabled: isNotificationsAuthorized,
                action: notificationAction
            )

            Button("Get Started") {
                hasCompletedOnboarding = true
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(width: 460)
        .onAppear { permissions.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
    }

    private var isNotificationsAuthorized: Bool {
        switch permissions.notificationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var notificationButtonTitle: String {
        switch permissions.notificationStatus {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Open Notification Settings"
        default: return "Allow Notifications"
        }
    }

    private func notificationAction() {
        switch permissions.notificationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .denied:
            permissions.openNotificationSettings()
        default:
            permissions.requestNotifications()
        }
    }
}
