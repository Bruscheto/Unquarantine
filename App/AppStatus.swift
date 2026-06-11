import Foundation
import UnquarantineCore

@MainActor
final class AppStatus: ObservableObject {
    @Published var lastMessage: String = "Right-click a file in Finder and choose \u{201C}Remove Quarantine & Re-sign\u{201D}."

    func update(_ result: AppleScriptResult, count: Int) {
        switch result {
        case .success:
            lastMessage = "Done \u{2014} processed \(count) item\(count == 1 ? "" : "s")."
        case .cancelled:
            lastMessage = "Cancelled."
        case .failed(let reason):
            lastMessage = "Failed: \(reason)"
        }
    }
}
