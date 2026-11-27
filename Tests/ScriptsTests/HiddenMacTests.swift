import Foundation
import Testing

/// A project in a temporary folder, holding the real guest program.
/// Its hidden Mac would live beside it, in "Work Guest", as the real one lives beside the real project.
private nonisolated struct Project: Sendable {
    // Short, because a socket's path may be at most 103 bytes.
    let top = FileManager.default.temporaryDirectory.appending(path: "hm-\(UUID().uuidString.prefix(8))")
    var work: URL { top.appending(path: "Work") }
    var guestFolder: URL { top.appending(path: "Work Guest") }
    var guest: String { top.appending(path: "guest").path }

    init() throws {
        let real = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
        try FileManager.default.createDirectory(at: work.appending(path: "Scripts"), withIntermediateDirectories: true)
        for file in ["Scripts/Guest"] {
            try FileManager.default.copyItem(at: real.appending(path: file), to: work.appending(path: file))
        }
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

    /// Builds the real guest program, as Scripts/tour does.
    func build() throws {
        let sources = try FileManager.default.contentsOfDirectory(atPath: work.appending(path: "Scripts/Guest").path)
        let (built, words) = try run(
            "/usr/bin/xcrun", ["swiftc", "-swift-version", "6", "-o", guest] + sources.map { "Scripts/Guest/\($0)" })
        try #require(built == 0, Comment(rawValue: words))
        try FileManager.default.createDirectory(at: guestFolder, withIntermediateDirectories: true)
    }

    /// The real agent, answering on the socket where the guest's would be.
    func agent() async throws -> Process {
        let agent = Process()
        agent.executableURL = URL(filePath: guest)
        agent.arguments = ["agent", guestFolder.appending(path: "guest.sock").path]
        try agent.run()
        while !FileManager.default.fileExists(atPath: guestFolder.appending(path: "guest.sock").path) {
            try await Task.sleep(for: .milliseconds(20))
        }
        return agent
    }

    /// Asks the agent, as Scripts/tour does. An answer that never comes fails, rather than holding the tests.
    func ask(_ command: String) async throws -> (Int32, String) {
        let asker = Process()
        let answer = top.appending(path: "answer-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: answer.path, contents: nil)
        asker.executableURL = URL(filePath: guest)
        asker.arguments = ["run", guestFolder.path, command]
        asker.standardOutput = try FileHandle(forWritingTo: answer)
        asker.standardError = asker.standardOutput
        try asker.run()
        for _ in 0..<200 where asker.isRunning { try await Task.sleep(for: .milliseconds(50)) }
        if asker.isRunning { asker.terminate() }
        asker.waitUntilExit()
        return (asker.terminationStatus, try String(contentsOf: answer, encoding: .utf8))
    }
}

/// What a command prints, and how it ends, come back to the chat that asked.
@Test(.timeLimit(.minutes(1))) func aCommandsAnswerComesBack() async throws {
    let project = try Project()
    try project.build()
    let agent = try await project.agent()
    defer { agent.terminate() }
    #expect(
        try await project.ask("echo one; sleep 0.1; echo two >&2; sleep 0.1; echo three; exit 3") == (
            3, "one\ntwo\nthree\n"
        ))
    #expect(try await project.ask("kill -9 $$") == (137, ""))
}

/// A command ends with nothing of it left running, and when its asker goes, so does all it started.
@Test(.timeLimit(.minutes(1))) func nothingOfACommandOutlivesIt() async throws {
    let project = try Project()
    try project.build()
    let agent = try await project.agent()
    defer { agent.terminate() }
    let (status, group) = try await project.ask("sleep 600 & echo $$")
    #expect(status == 0)
    try await Task.sleep(for: .milliseconds(200))
    #expect(kill(-pid_t(group.trimmingCharacters(in: .newlines))!, 0) != 0)

    let mark = project.top.appending(path: "group").path
    let asker = Process()
    asker.executableURL = URL(filePath: project.guest)
    asker.arguments = ["run", project.guestFolder.path, "echo $$ >'\(mark)'; sleep 600 & sleep 600"]
    try asker.run()
    while (try? String(contentsOfFile: mark, encoding: .utf8))?.hasSuffix("\n") != true {
        try await Task.sleep(for: .milliseconds(20))
    }
    let left = pid_t(try String(contentsOfFile: mark, encoding: .utf8).trimmingCharacters(in: .newlines))!
    #expect(kill(-left, 0) == 0)
    asker.terminate()
    asker.waitUntilExit()
    try await Task.sleep(for: .milliseconds(500))
    #expect(kill(-left, 0) != 0)
}

/// Two chats ask at once: the second is told whose tour runs, waits, and runs once the first has ended.
@Test(.timeLimit(.minutes(1))) func chatsTakeTurns() async throws {
    let project = try Project()
    try project.build()
    let guest = project.guest
    let folder = project.guestFolder.path
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
