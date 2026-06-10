public enum AppleScriptResult: Equatable {
    case success
    case cancelled
    case failed(reason: String)

    public static func from(errorNumber: Int?, message: String?) -> AppleScriptResult {
        guard let errorNumber else { return .success }
        if errorNumber == -128 { return .cancelled }
        return .failed(reason: message ?? "Unknown error (\(errorNumber))")
    }
}
