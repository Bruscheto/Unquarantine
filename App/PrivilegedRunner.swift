import Foundation
import UnquarantineCore

enum PrivilegedRunner {
    /// Run `script` (a single-line /bin/sh script) as administrator. Shows the
    /// standard macOS password dialog once.
    static func run(script: String) -> AppleScriptResult {
        let source = "do shell script \"\(escapeForAppleScript(script))\" with administrator privileges"
        guard let appleScript = NSAppleScript(source: source) else {
            return .failed(reason: "Could not construct AppleScript.")
        }
        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)
        let number = errorInfo?["NSAppleScriptErrorNumber"] as? Int
        let message = errorInfo?["NSAppleScriptErrorMessage"] as? String
        return AppleScriptResult.from(errorNumber: number, message: message)
    }

    /// Escape a string for embedding inside an AppleScript double-quoted literal.
    private static func escapeForAppleScript(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
