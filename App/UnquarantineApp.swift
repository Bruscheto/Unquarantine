import AppKit
import SwiftUI
import UnquarantineCore

@main
struct UnquarantineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // No auto-opening window. The agent stays invisible; the setup window is
        // created on demand by AppDelegate (direct launch / reopen).
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let status = AppStatus()
    private let permissions = PermissionsModel()
    private var setupWindow: NSWindow?
    private var didHandleURL = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Notifier.requestAuthorization()

        // If launched to process a URL, `application(_:open:)` runs first and sets the
        // flag; otherwise the user opened the app directly, so show the setup window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.didHandleURL else { return }
            self.showSetupWindow()
        }
    }

    // Right-click action: run the work and report via a notification. No window.
    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleURL = true
        for url in urls { handle(url) }
    }

    private func handle(_ url: URL) {
        guard url.scheme == "unquarantine", url.host == "strip",
              let query = url.query, query.hasPrefix("paths=") else { return }
        // Use the raw (still percent-encoded) query so PathCodec's comma separator is
        // intact; URLComponents would percent-decode and could reintroduce a literal comma.
        let value = String(query.dropFirst("paths=".count))
        let paths = PathCodec.decode(value).filter { FileManager.default.fileExists(atPath: $0) }
        guard !paths.isEmpty else { return }

        let script = CommandBuilder.build(paths: paths)
        let result = PrivilegedRunner.run(script: script)
        Notifier.notify(result, count: paths.count)
        status.update(result, count: paths.count)
    }

    // Setup / onboarding window — only when the user opens the app themselves.
    private func showSetupWindow() {
        if let window = setupWindow {
            bringToFront(window)
            return
        }
        let root = ContentView()
            .environmentObject(status)
            .environmentObject(permissions)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "Unquarantine"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        setupWindow = window
        bringToFront(window)
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Drop back to a background agent once the setup window is dismissed.
        NSApp.setActivationPolicy(.accessory)
    }

    // Re-open the setup window if the user launches the app again while it's running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSetupWindow()
        return true
    }
}
