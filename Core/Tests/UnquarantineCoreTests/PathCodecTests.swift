import Testing
@testable import UnquarantineCore

@Suite struct PathCodecTests {
    @Test func roundTripSimple() {
        let paths = ["/Applications/Foo.app"]
        #expect(PathCodec.decode(PathCodec.encode(paths)) == paths)
    }

    @Test func roundTripMultiple() {
        let paths = ["/Applications/Foo.app", "/Users/x/Bar.app"]
        #expect(PathCodec.decode(PathCodec.encode(paths)) == paths)
    }

    @Test func roundTripSpecialCharacters() {
        let paths = ["/Users/x/My App, v2.app", "/Users/x/a&b?c .app", "/Users/x/café.app"]
        #expect(PathCodec.decode(PathCodec.encode(paths)) == paths)
    }

    @Test func roundTripCommaInPath() {
        let paths = ["/a,b", "/c"]
        #expect(PathCodec.decode(PathCodec.encode(paths)) == paths)
    }

    @Test func encodedValueHasNoLiteralComma() {
        let encoded = PathCodec.encode(["/a,b", "/c"])
        #expect(encoded.split(separator: ",").count == 2)
    }

    @Test func decodeEmptyReturnsEmpty() {
        #expect(PathCodec.decode("") == [])
    }
}
