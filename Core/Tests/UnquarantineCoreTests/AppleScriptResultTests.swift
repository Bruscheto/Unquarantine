import XCTest
@testable import UnquarantineCore

final class AppleScriptResultTests: XCTestCase {
    func testNilErrorIsSuccess() {
        XCTAssertEqual(AppleScriptResult.from(errorNumber: nil, message: nil), .success)
    }

    func testMinus128IsCancelled() {
        XCTAssertEqual(AppleScriptResult.from(errorNumber: -128, message: "User cancelled."), .cancelled)
    }

    func testOtherErrorIsFailedWithMessage() {
        XCTAssertEqual(
            AppleScriptResult.from(errorNumber: 1, message: "codesign failed"),
            .failed(reason: "codesign failed")
        )
    }

    func testOtherErrorWithoutMessageSynthesizesReason() {
        XCTAssertEqual(
            AppleScriptResult.from(errorNumber: 42, message: nil),
            .failed(reason: "Unknown error (42)")
        )
    }
}
