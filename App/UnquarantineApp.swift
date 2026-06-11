import SwiftUI
import UnquarantineCore

@main
struct UnquarantineApp: App {
    @StateObject private var status = AppStatus()
    @StateObject private var permissions = PermissionsModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(status)
                .environmentObject(permissions)
                .onOpenURL { handle($0) }
        }
        .windowResizability(.contentSize)
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
}
