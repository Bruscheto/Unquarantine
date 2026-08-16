import Foundation
import Testing
@testable import UnquarantineCore

@Suite struct FinderHandoffTests {
    @Test func createsExistingURLFormat() throws {
        let handoff = try #require(FinderHandoff(paths: ["/Applications/Foo.app"]))

        #expect(handoff.url.absoluteString == "unquarantine://strip?paths=%2FApplications%2FFoo.app")
    }

    @Test func roundTripsMultiplePathsInOrder() throws {
        let paths = ["/Applications/Foo.app", "/Users/x/Bar.app"]
        let outgoing = try #require(FinderHandoff(paths: paths))
        let incoming = try #require(FinderHandoff(url: outgoing.url))

        #expect(incoming.paths == paths)
    }

    @Test func roundTripsSpecialCharactersExactly() throws {
        let paths = [
            "/Users/x/My App, v2.app",
            "/Users/x/a&b?c café.app",
            "/Users/x/'; $(touch nope); `echo nope`.app"
        ]
        let outgoing = try #require(FinderHandoff(paths: paths))
        let incoming = try #require(FinderHandoff(url: outgoing.url))

        #expect(incoming.paths == paths)
    }

    @Test func refusesEmptySelection() {
        #expect(FinderHandoff(paths: []) == nil)
        #expect(FinderHandoff(paths: [""]) == nil)
    }

    @Test func refusesRelativePaths() {
        #expect(FinderHandoff(paths: ["relative/Foo.app"]) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?paths=relative%2FFoo.app")!) == nil)
    }

    @Test func rejectsForeignURL() {
        #expect(FinderHandoff(url: URL(string: "https://strip?paths=%2Ftmp%2FFoo.app")!) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://other?paths=%2Ftmp%2FFoo.app")!) == nil)
    }

    @Test func rejectsMissingOrUnexpectedQuery() {
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip")!) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?items=%2Ftmp%2FFoo.app")!) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?paths=")!) == nil)
    }

    @Test func rejectsMalformedPathList() {
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?paths=%2Fone,,%2Ftwo")!) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?paths=%2Fone&extra=1")!) == nil)
        #expect(FinderHandoff(url: URL(string: "unquarantine://strip?paths=%2Fone#fragment")!) == nil)
    }
}
