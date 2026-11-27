import Foundation
import Testing

/// A project in a temporary folder, holding the real guest program.
/// Its hidden Mac would live beside it, in "Work Guest", as the real one lives beside the real project.
private nonisolated struct Project: Sendable {
    let top = FileManager.default.temporaryDirectory.appending(path: "hidden-mac-\(UUID().uuidString)")
    var work: URL { top.appending(path: "Work") }
    var guestFolder: URL { top.appending(path: "Work Guest") }

    init() throws {
        let real = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
        try FileManager.default.createDirectory(at: work.appending(path: "Scripts"), withIntermediateDirectories: true)
        for file in ["Scripts/Guest"] {
            try FileManager.default.copyItem(at: real.appending(path: file), to: work.appending(path: file))
        }
        _ = try run("/usr/bin/git", ["init", "-q"])
    }

    func run(_ program: String, _ arguments: [String], environment: [String: String] = [:]) throws -> (Int32, String) {
        let process = Process()
        let said = Pipe()
        process.executableURL = URL(filePath: program)
        process.arguments = arguments
        process.currentDirectoryURL = work
        process.environment = ProcessInfo.processInfo.environment.filter { $0.key != "CI" }.merging(environment) { $1 }
        process.standardOutput = said
        process.standardError = said
        try process.run()
        let words = String(decoding: said.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        return (process.terminationStatus, words)
    }
}

/// Two chats ask at once: the second is told whose tour runs, waits, and runs once the first has ended.
@Test(.timeLimit(.minutes(1))) func chatsTakeTurns() async throws {
    let project = try Project()
    let guest = project.top.appending(path: "guest").path
    let sources = try FileManager.default.contentsOfDirectory(
        atPath: project.work.appending(path: "Scripts/Guest").path)
    let (built, words) = try project.run(
        "/usr/bin/xcrun", ["swiftc", "-swift-version", "6", "-o", guest] + sources.map { "Scripts/Guest/\($0)" })
    try #require(built == 0, Comment(rawValue: words))
    let folder = project.guestFolder.path
    try FileManager.default.createDirectory(at: project.guestFolder, withIntermediateDirectories: true)
    let record = project.top.appending(path: "record").path

    // The first holds its turn until the second has said it waits, however slowly this Mac runs the two.
    let go = project.top.appending(path: "go").path
    let first = Task.detached {
        try project.run(
            guest,
            [
                "turn", folder, "chat one", "/bin/sh", "-c",
                "until [ -f '\(go)' ]; do sleep 0.05; done; echo one >>'\(record)'",
            ])
    }
    let lock = project.guestFolder.appending(path: "turn.lock")
    while (try? String(contentsOf: lock, encoding: .utf8)) != "chat one\n" {
        try await Task.sleep(for: .milliseconds(50))
    }
    let second = Process()
    let said = Pipe()
    second.executableURL = URL(filePath: guest)
    second.arguments = ["turn", folder, "chat two", "/bin/sh", "-c", "echo two >>'\(record)'"]
    second.standardOutput = said
    second.standardError = FileHandle.nullDevice
    try second.run()
    let waiting = String(decoding: said.fileHandleForReading.availableData, as: UTF8.self)
    FileManager.default.createFile(atPath: go, contents: nil)
    second.waitUntilExit()
    _ = try await first.value
    #expect(waiting == "The hidden Mac is busy with chat one; waiting in line.\n")
    #expect(second.terminationStatus == 0)
    #expect(try String(contentsOfFile: record, encoding: .utf8) == "one\ntwo\n")
}
