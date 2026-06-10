import Testing
@testable import UnquarantineCore

@Suite struct CommandBuilderTests {
    @Test func shellQuoteWrapsInSingleQuotes() {
        #expect(CommandBuilder.shellQuote("/a/b") == "'/a/b'")
    }

    @Test func shellQuoteEscapesEmbeddedSingleQuote() {
        #expect(CommandBuilder.shellQuote("a'b") == "'a'\\''b'")
    }

    @Test func buildIsSingleLine() {
        let script = CommandBuilder.build(paths: ["/a", "/b"])
        #expect(!script.contains("\n"))
    }

    @Test func buildContainsBothCommandsPerPath() {
        let script = CommandBuilder.build(paths: ["/Applications/Foo.app"])
        #expect(script.contains("xattr -r -d com.apple.quarantine '/Applications/Foo.app' 2>/dev/null || true"))
        #expect(script.contains("codesign --force --deep --sign - '/Applications/Foo.app' || status=1"))
    }

    @Test func buildInitializesAndExitsWithStatus() {
        let script = CommandBuilder.build(paths: ["/a"])
        #expect(script.hasPrefix("status=0; "))
        #expect(script.hasSuffix("exit $status"))
    }

    @Test func maliciousFilenameCannotInject() {
        let script = CommandBuilder.build(paths: ["/x/; rm -rf /"])
        #expect(script.contains("'/x/; rm -rf /'"))
    }
}
