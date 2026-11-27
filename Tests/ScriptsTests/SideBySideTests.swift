import Foundation
import Testing

/// A small real package with the real rules script and three test targets: one whose test passes, one whose test
/// fails, and one with no test at all. The tests rule runs them side by side, as on GitHub's Mac.
private struct ThreeTargets {
    let folder = FileManager.default.temporaryDirectory.appending(path: "side-\(UUID().uuidString)")

    init() throws {
        let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: script, to: folder.appending(path: "Scripts/check"))
        try write(
            """
            // swift-tools-version: 6.4
            import PackageDescription

            let package = Package(
                name: "Three", platforms: [.macOS(.v27)],
                targets: [
                    .testTarget(name: "EmptyTests"), .testTarget(name: "FailingTests"),
                    .testTarget(name: "PassingTests"),
                ])

            """, to: "Package.swift")
        try write("import Testing\n", to: "Tests/EmptyTests/Empty.swift")
        try write("import Testing\n\n@Test func fails() { #expect(1 == 2) }\n", to: "Tests/FailingTests/Failing.swift")
        try write("import Testing\n\n@Test func passes() { #expect(1 == 1) }\n", to: "Tests/PassingTests/Passing.swift")
        try write("Chete\n", to: "NOW")
        try write(".build/\n", to: ".gitignore")
        try run("/usr/bin/env", ["git", "init", "-q", "-b", "main"])
        try run("/usr/bin/env", ["git", "add", "-A"])
        try run(
            "/usr/bin/env",
            ["git", "-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-qm", "Three"])
        try run("/usr/bin/env", ["git", "update-ref", "refs/remotes/origin/main", "HEAD"])
    }

    func write(_ words: String, to name: String) throws {
        let url = folder.appending(path: name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(words.utf8).write(to: url)
    }

    /// What the tests rule says, alone, as GitHub's Mac runs it: every test target.
    func tests() throws -> String {
        try run(folder.appending(path: "Scripts/check").path, ["tests"], ci: true)
    }

    @discardableResult private func run(_ tool: String, _ arguments: [String], ci: Bool = false) throws -> String {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        if ci { environment["CI"] = "true" }
        process.environment = environment
        process.standardOutput = answer
        try process.run()
        let said = answer.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: said, as: UTF8.self)
    }
}

/// Every target runs, each in its own process: a failing one fails the rule and says why, one that ran no test
/// fails it too, and the one that passed says how many tests it ran.
@Test func eachTestTargetRunsAndAnswersForItself() throws {
    let three = try ThreeTargets()
    defer { try? FileManager.default.removeItem(at: three.folder) }
    let said = try three.tests()
    #expect(said.hasPrefix("FAIL  tests"))
    #expect(said.contains("FailingTests failed"))
    #expect(said.contains("EmptyTests ran no test"))
    #expect(said.contains("PassingTests, 1 test"))

    try FileManager.default.removeItem(at: three.folder.appending(path: "Tests/FailingTests"))
    try FileManager.default.removeItem(at: three.folder.appending(path: "Tests/EmptyTests"))
    try three.write(
        """
        // swift-tools-version: 6.4
        import PackageDescription

        let package = Package(name: "Three", platforms: [.macOS(.v27)], targets: [.testTarget(name: "PassingTests")])

        """, to: "Package.swift")
    #expect(try three.tests().hasPrefix("ok    tests"))
}
