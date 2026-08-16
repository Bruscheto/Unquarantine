import Foundation
import UnquarantineCore

@MainActor
protocol RightClickRunReporting {
    func report(_ result: AppleScriptResult, count: Int)
}

@MainActor
final class RightClickRun {
    typealias PathExists = (String) -> Bool
    typealias Execute = (String) -> AppleScriptResult

    private let pathExists: PathExists
    private let execute: Execute
    private let reporters: [any RightClickRunReporting]
    private var pendingSelections: [[String]] = []
    private var isRunning = false

    init(
        pathExists: @escaping PathExists,
        execute: @escaping Execute,
        reporters: [any RightClickRunReporting]
    ) {
        self.pathExists = pathExists
        self.execute = execute
        self.reporters = reporters
    }

    convenience init(status: AppStatus) {
        self.init(
            pathExists: { FileManager.default.fileExists(atPath: $0) },
            execute: PrivilegedRunner.run,
            reporters: [status, NotificationRunReporter()]
        )
    }

    func perform(paths: [String]) {
        pendingSelections.append(paths)
        drainPendingSelections()
    }

    private func drainPendingSelections() {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        while !pendingSelections.isEmpty {
            performNext(paths: pendingSelections.removeFirst())
        }
    }

    private func performNext(paths: [String]) {
        let validPaths = paths.filter(pathExists)
        guard !validPaths.isEmpty else { return }

        let result = execute(CommandBuilder.build(paths: validPaths))
        for reporter in reporters {
            reporter.report(result, count: validPaths.count)
        }
    }
}
