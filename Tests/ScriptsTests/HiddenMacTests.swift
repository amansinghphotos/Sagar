import Foundation
import Testing

/// Waits at most so long for a process to end, and never longer: its status, or nil, having stopped it, when it
/// did not end in time. It sleeps rather than blocks, because Foundation hears of a child's end on this thread.
private func ended(_ process: Process, within seconds: Double = 30) async throws -> Int32? {
    guard try await soon(seconds, { !process.isRunning }) else {
        kill(process.processIdentifier, SIGKILL)
        return nil
    }
    return process.terminationStatus
}

/// Waits at most so long for something to be true.
private func soon(_ seconds: Double = 30, _ condition: () -> Bool) async throws -> Bool {
    for _ in 0..<Int(seconds * 20) where !condition() { try await Task.sleep(for: .milliseconds(50)) }
    return condition()
}

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

    func run(_ program: String, _ arguments: [String], environment: [String: String] = [:]) async throws -> (
        Int32, String
    ) {
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
        return (try await ended(process, within: 120) ?? -1, words)
    }

    /// Builds the real guest program, as Scripts/tour does.
    func build() async throws {
        let sources = try FileManager.default.contentsOfDirectory(atPath: work.appending(path: "Scripts/Guest").path)
        let (built, words) = try await run(
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
        let socket = guestFolder.appending(path: "guest.sock").path
        guard try await soon(10, { FileManager.default.fileExists(atPath: socket) }) else {
            agent.terminate()
            throw Fault.noAgent
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
        guard let status = try await ended(asker) else { return (-1, "no answer in 30 s") }
        return (status, try String(contentsOf: answer, encoding: .utf8))
    }
}

/// What a command prints, and how it ends, come back to the chat that asked.
@Test(.timeLimit(.minutes(1))) func aCommandsAnswerComesBack() async throws {
    let project = try Project()
    try await project.build()
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
    try await project.build()
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
    try #require(try await soon { (try? String(contentsOfFile: mark, encoding: .utf8))?.hasSuffix("\n") == true })
    let left = pid_t(try String(contentsOfFile: mark, encoding: .utf8).trimmingCharacters(in: .newlines))!
    #expect(kill(-left, 0) == 0)
    asker.terminate()
    #expect(try await ended(asker) != nil)
    try await Task.sleep(for: .milliseconds(500))
    #expect(kill(-left, 0) != 0)
}

/// Two chats ask at once: the second is told whose tour runs, waits, and runs once the first has ended.
@Test(.timeLimit(.minutes(1))) func chatsTakeTurns() async throws {
    let project = try Project()
    try await project.build()
    let guest = project.guest
    let folder = project.guestFolder.path
    let record = project.top.appending(path: "record").path

    // The first holds its turn until the second has said it waits, however slowly this Mac runs the two.
    let go = project.top.appending(path: "go").path
    let first = Task.detached {
        try await project.run(
            guest,
            [
                "turn", folder, "chat one", "/bin/sh", "-c",
                "for _ in $(seq 600); do [ -f '\(go)' ] && break; sleep 0.05; done; echo one >>'\(record)'",
            ])
    }
    let lock = project.guestFolder.appending(path: "turn.lock")
    try #require(try await soon { (try? String(contentsOf: lock, encoding: .utf8)) == "chat one\n" })
    let second = Process()
    let said = Pipe()
    second.executableURL = URL(filePath: guest)
    second.arguments = ["turn", folder, "chat two", "/bin/sh", "-c", "echo two >>'\(record)'"]
    second.standardOutput = said
    second.standardError = FileHandle.nullDevice
    try second.run()
    let waiting = String(decoding: said.fileHandleForReading.availableData, as: UTF8.self)
    FileManager.default.createFile(atPath: go, contents: nil)
    let status = try await ended(second)
    _ = try await first.value
    #expect(waiting == "The hidden Mac is busy with chat one; waiting in line.\n")
    #expect(status == 0)
    #expect(try String(contentsOfFile: record, encoding: .utf8) == "one\ntwo\n")
}

private enum Fault: Error { case noAgent }
