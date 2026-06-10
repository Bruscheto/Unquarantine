public enum CommandBuilder {
    /// Single-quote a path for safe POSIX shell embedding.
    public static func shellQuote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Build a single-line /bin/sh script that strips quarantine (best-effort) and
    /// ad-hoc re-signs each path, exiting non-zero if any re-sign fails.
    public static func build(paths: [String]) -> String {
        var parts = ["status=0"]
        for path in paths {
            let quoted = shellQuote(path)
            parts.append("xattr -r -d com.apple.quarantine \(quoted) 2>/dev/null || true")
            parts.append("codesign --force --deep --sign - \(quoted) || status=1")
        }
        parts.append("exit $status")
        return parts.joined(separator: "; ")
    }
}
