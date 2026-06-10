import Testing
@testable import UnquarantineCore

@Suite struct AppleScriptResultTests {
    @Test func nilErrorIsSuccess() {
        #expect(AppleScriptResult.from(errorNumber: nil, message: nil) == .success)
    }

    @Test func minus128IsCancelled() {
        #expect(AppleScriptResult.from(errorNumber: -128, message: "User cancelled.") == .cancelled)
    }

    @Test func otherErrorIsFailedWithMessage() {
        #expect(AppleScriptResult.from(errorNumber: 1, message: "codesign failed") == .failed(reason: "codesign failed"))
    }

    @Test func otherErrorWithoutMessageSynthesizesReason() {
        #expect(AppleScriptResult.from(errorNumber: 42, message: nil) == .failed(reason: "Unknown error (42)"))
    }
}
