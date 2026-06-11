public extension AppleScriptResult {
    /// Human-readable summary of the result for the status window and notifications.
    func message(count: Int) -> String {
        switch self {
        case .success:
            return "Done — processed \(count) item\(count == 1 ? "" : "s")."
        case .cancelled:
            return "Cancelled."
        case .failed(let reason):
            return "Failed: \(reason)"
        }
    }
}
