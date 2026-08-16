import Foundation

public struct FinderHandoff: Equatable, Sendable {
    public let paths: [String]
    public let url: URL

    private static let scheme = "unquarantine"
    private static let host = "strip"
    private static let queryPrefix = "paths="
    private static let allowedPathCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    public init?(paths: [String]) {
        guard !paths.isEmpty, paths.allSatisfy(Self.isAbsolutePath) else { return nil }

        let encodedPaths = paths.compactMap {
            $0.addingPercentEncoding(withAllowedCharacters: Self.allowedPathCharacters)
        }
        guard encodedPaths.count == paths.count,
              let url = URL(string: "\(Self.scheme)://\(Self.host)?\(Self.queryPrefix)\(encodedPaths.joined(separator: ","))")
        else { return nil }

        self.paths = paths
        self.url = url
    }

    public init?(url: URL) {
        guard url.scheme == Self.scheme,
              url.host == Self.host,
              url.user == nil,
              url.password == nil,
              url.port == nil,
              url.path.isEmpty,
              url.fragment == nil,
              let query = url.query,
              query.hasPrefix(Self.queryPrefix)
        else { return nil }

        let encodedValue = String(query.dropFirst(Self.queryPrefix.count))
        guard !encodedValue.isEmpty, !encodedValue.contains("&") else { return nil }

        let encodedPaths = encodedValue.split(separator: ",", omittingEmptySubsequences: false)
        guard encodedPaths.allSatisfy({ !$0.isEmpty }) else { return nil }

        let paths = encodedPaths.compactMap { String($0).removingPercentEncoding }
        guard paths.count == encodedPaths.count, paths.allSatisfy(Self.isAbsolutePath) else { return nil }

        self.paths = paths
        self.url = url
    }

    private static func isAbsolutePath(_ path: String) -> Bool {
        !path.isEmpty && (path as NSString).isAbsolutePath
    }
}
