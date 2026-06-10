import XCTest
@testable import UnquarantineCore

final class PathCodecTests: XCTestCase {
    func testRoundTripSimple() {
        let paths = ["/Applications/Foo.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testRoundTripMultiple() {
        let paths = ["/Applications/Foo.app", "/Users/x/Bar.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testRoundTripSpecialCharacters() {
        let paths = ["/Users/x/My App, v2.app", "/Users/x/a&b?c .app", "/Users/x/café.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testEncodedValueHasNoLiteralComma() {
        let encoded = PathCodec.encode(["/a,b", "/c"])
        XCTAssertEqual(encoded.split(separator: ",").count, 2)
    }

    func testDecodeEmptyReturnsEmpty() {
        XCTAssertEqual(PathCodec.decode(""), [])
    }
}
