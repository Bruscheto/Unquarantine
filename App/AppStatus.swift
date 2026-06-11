import Foundation
import UnquarantineCore

@MainActor
final class AppStatus: ObservableObject {
    @Published var lastMessage: String = "Right-click a file in Finder and choose \u{201C}Remove Quarantine & Re-sign\u{201D}."

    func update(_ result: AppleScriptResult, count: Int) {
        lastMessage = result.message(count: count)
    }
}
