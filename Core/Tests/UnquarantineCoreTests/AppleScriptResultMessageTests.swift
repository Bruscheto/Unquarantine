import Testing
@testable import UnquarantineCore

@Suite struct AppleScriptResultMessageTests {
    @Test func successSingular() {
        #expect(AppleScriptResult.success.message(count: 1) == "Done — processed 1 item.")
    }

    @Test func successPlural() {
        #expect(AppleScriptResult.success.message(count: 3) == "Done — processed 3 items.")
    }

    @Test func cancelled() {
        #expect(AppleScriptResult.cancelled.message(count: 2) == "Cancelled.")
    }

    @Test func failed() {
        #expect(AppleScriptResult.failed(reason: "boom").message(count: 1) == "Failed: boom.")
    }
}
