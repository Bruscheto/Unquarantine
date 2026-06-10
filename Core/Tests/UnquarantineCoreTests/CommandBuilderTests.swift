import XCTest
@testable import UnquarantineCore

final class CommandBuilderTests: XCTestCase {
    func testShellQuoteWrapsInSingleQuotes() {
        XCTAssertEqual(CommandBuilder.shellQuote("/a/b"), "'/a/b'")
    }

    func testShellQuoteEscapesEmbeddedSingleQuote() {
        XCTAssertEqual(CommandBuilder.shellQuote("a'b"), "'a'\\''b'")
    }

    func testBuildIsSingleLine() {
        let script = CommandBuilder.build(paths: ["/a", "/b"])
        XCTAssertFalse(script.contains("\n"))
    }

    func testBuildContainsBothCommandsPerPath() {
        let script = CommandBuilder.build(paths: ["/Applications/Foo.app"])
        XCTAssertTrue(script.contains("xattr -r -d com.apple.quarantine '/Applications/Foo.app' 2>/dev/null || true"))
        XCTAssertTrue(script.contains("codesign --force --deep --sign - '/Applications/Foo.app' || status=1"))
    }

    func testBuildInitializesAndExitsWithStatus() {
        let script = CommandBuilder.build(paths: ["/a"])
        XCTAssertTrue(script.hasPrefix("status=0;"))
        XCTAssertTrue(script.hasSuffix("exit $status"))
    }

    func testMaliciousFilenameCannotInject() {
        let script = CommandBuilder.build(paths: ["/x/; rm -rf /"])
        XCTAssertTrue(script.contains("'/x/; rm -rf /'"))
    }
}
