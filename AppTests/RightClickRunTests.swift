import Testing
import UnquarantineCore
@testable import Unquarantine

@MainActor
@Suite struct RightClickRunTests {
    @Test func processesAllExistingPathsOnceInOrder() throws {
        let reporter = RecordingRunReporter()
        var executedScripts: [String] = []
        let run = RightClickRun(
            pathExists: { _ in true },
            execute: {
                executedScripts.append($0)
                return .success
            },
            reporters: [reporter]
        )

        run.perform(paths: ["/first.app", "/second.app"])

        #expect(executedScripts.count == 1)
        let script = try #require(executedScripts.first)
        let firstRange = try #require(script.range(of: "'/first.app'"))
        let secondRange = try #require(script.range(of: "'/second.app'"))
        #expect(firstRange.lowerBound < secondRange.lowerBound)
        #expect(reporter.reports.count == 1)
        let report = try #require(reporter.reports.first)
        #expect(report.count == 2)
    }

    @Test func skipsMissingPathsAndReportsValidCount() throws {
        let reporter = RecordingRunReporter()
        var executedScript: String?
        let run = RightClickRun(
            pathExists: { $0 != "/missing.app" },
            execute: {
                executedScript = $0
                return .success
            },
            reporters: [reporter]
        )

        run.perform(paths: ["/first.app", "/missing.app", "/last.app"])

        #expect(executedScript?.contains("'/first.app'") == true)
        #expect(executedScript?.contains("'/missing.app'") == false)
        #expect(executedScript?.contains("'/last.app'") == true)
        let report = try #require(reporter.reports.first)
        #expect(report.count == 2)
    }

    @Test func allMissingPathsAreANoOp() {
        let reporter = RecordingRunReporter()
        var executionCount = 0
        let run = RightClickRun(
            pathExists: { _ in false },
            execute: { _ in
                executionCount += 1
                return .success
            },
            reporters: [reporter]
        )

        run.perform(paths: ["/missing.app"])

        #expect(executionCount == 0)
        #expect(reporter.reports.isEmpty)
    }

    @Test(arguments: [
        (AppleScriptResult.success, "Done — processed 2 items."),
        (AppleScriptResult.failed(reason: "codesign failed"), "Failed: codesign failed")
    ])
    func successAndFailureReachStatusAndNotification(
        result: AppleScriptResult,
        expectedMessage: String
    ) {
        let status = AppStatus()
        var deliveredMessages: [String] = []
        let notification = NotificationRunReporter { deliveredMessages.append($0) }
        let run = RightClickRun(
            pathExists: { _ in true },
            execute: { _ in result },
            reporters: [status, notification]
        )

        run.perform(paths: ["/one.app", "/two.app"])

        #expect(status.lastMessage == expectedMessage)
        #expect(deliveredMessages == [expectedMessage])
    }

    @Test func cancellationReachesStatusButNotNotification() {
        let status = AppStatus()
        var deliveredMessages: [String] = []
        let notification = NotificationRunReporter { deliveredMessages.append($0) }
        let run = RightClickRun(
            pathExists: { _ in true },
            execute: { _ in .cancelled },
            reporters: [status, notification]
        )

        run.perform(paths: ["/one.app"])

        #expect(status.lastMessage == "Cancelled.")
        #expect(deliveredMessages.isEmpty)
    }

    @Test func reentrantRunsExecuteSerially() {
        var events: [String] = []
        var activeExecutions = 0
        var maximumActiveExecutions = 0
        var executionCount = 0
        var run: RightClickRun!
        run = RightClickRun(
            pathExists: { _ in true },
            execute: { _ in
                executionCount += 1
                activeExecutions += 1
                maximumActiveExecutions = max(maximumActiveExecutions, activeExecutions)
                events.append("start-\(executionCount)")
                if executionCount == 1 {
                    run.perform(paths: ["/second.app"])
                }
                events.append("end-\(executionCount)")
                activeExecutions -= 1
                return .success
            },
            reporters: []
        )

        run.perform(paths: ["/first.app"])

        #expect(maximumActiveExecutions == 1)
        #expect(events == ["start-1", "end-1", "start-2", "end-2"])
    }
}

@MainActor
private final class RecordingRunReporter: RightClickRunReporting {
    private(set) var reports: [(result: AppleScriptResult, count: Int)] = []

    func report(_ result: AppleScriptResult, count: Int) {
        reports.append((result, count))
    }
}
