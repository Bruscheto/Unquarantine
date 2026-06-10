import Foundation

public enum PathCodec {
    /// Characters left un-escaped. Deliberately excludes "," so the comma can be
    /// used as an unambiguous separator between encoded paths.
    private static let allowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    public static func encode(_ paths: [String]) -> String {
        paths
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? $0 }
            .joined(separator: ",")
    }

    public static func decode(_ value: String) -> [String] {
        value
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.removingPercentEncoding ?? String($0) }
    }
}
