import Foundation
import Testing

/// A program the tests start, whose end Foundation reports on a queue of its own. Waiting for it sleeps rather than
/// blocks, so the tests running beside these cannot starve it, and every wait has a limit.
private nonisolated final class Started: @unchecked Sendable {
    let process = Process()
    let output: URL
    private let lock = NSLock()
    private var status: Int32?

    init(
        _ program: String, _ arguments: [String], output: URL, in folder: URL? = nil,
        environment: [String: String] = [:]
    )
        throws
    {
        self.output = output
        FileManager.default.createFile(atPath: output.path, contents: nil)
        process.executableURL = URL(filePath: program)
        process.arguments = arguments
        if let folder { process.currentDirectoryURL = folder }
        process.environment = ProcessInfo.processInfo.environment.filter { $0.key != "CI" }.merging(environment) { $1 }
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = try FileHandle(forWritingTo: output)
        process.standardError = process.standardOutput
        process.terminationHandler = { [weak self] ended in
            self?.lock.withLock { self?.status = ended.terminationStatus }
        }
        try process.run()
    }

    /// Its status once it has ended, waiting at most so long; nil, having stopped it, when it has not ended by then.
    func ended(within seconds: Double = 60) async throws -> Int32? {
        for _ in 0..<Int(seconds * 20) {
            if let status = lock.withLock({ status }) { return status }
            try await Task.sleep(for: .milliseconds(50))
        }
        kill(process.processIdentifier, SIGKILL)
        return nil
    }

    var said: String { (try? String(contentsOf: output, encoding: .utf8)) ?? "" }
}

/// Waits at most so long for something to be true.
private func soon(_ seconds: Double = 60, _ condition: () -> Bool) async throws -> Bool {
    for _ in 0..<Int(seconds * 20) where !condition() { try await Task.sleep(for: .milliseconds(50)) }
    return condition()
}

/// The real guest program, built once for all these tests, from the repository's own source.
private let guestProgram = Task<String, any Error> {
    let real = URL(filePath: #filePath).appending(path: "../../../Scripts/Guest").standardizedFileURL
    let built = FileManager.default.temporaryDirectory.appending(path: "hm-\(UUID().uuidString.prefix(8))-guest")
    let sources = try FileManager.default.contentsOfDirectory(atPath: real.path).map { real.appending(path: $0).path }
    let compiler = try Started(
        "/usr/bin/xcrun", ["swiftc", "-swift-version", "6", "-o", built.path] + sources,
        output: URL(filePath: built.path + ".log"))
    guard try await compiler.ended(within: 300) == 0 else { throw Unbuilt(words: compiler.said) }
    return built.path
}

private struct Unbuilt: Error { let words: String }

/// A guest folder in a temporary place, short, because a socket's path may be at most 103 bytes.
private nonisolated struct Project: Sendable {
    let top = FileManager.default.temporaryDirectory.appending(path: "hm-\(UUID().uuidString.prefix(8))")
    var guestFolder: URL { top.appending(path: "Work Guest") }
    let guest: String

    init() async throws {
        guest = try await guestProgram.value
        try FileManager.default.createDirectory(at: guestFolder, withIntermediateDirectories: true)
    }

    func start(_ arguments: [String]) throws -> Started {
        try Started(guest, arguments, output: top.appending(path: "said-\(UUID().uuidString)"))
    }

    /// The real agent, answering on the socket where the guest's would be.
    func agent() async throws -> Started {
        let agent = try start(["agent", guestFolder.appending(path: "guest.sock").path])
        let socket = guestFolder.appending(path: "guest.sock").path
        try #require(try await soon { FileManager.default.fileExists(atPath: socket) }, "The agent made no socket.")
        return agent
    }

    /// Asks the agent, as Scripts/tour does.
    func ask(_ command: String) async throws -> (Int32, String) {
        let asker = try start(["run", guestFolder.path, command])
        guard let status = try await asker.ended() else { return (-1, "no answer in 60 s") }
        return (status, asker.said)
    }
}

/// One after another, so these never wait on each other; each wait still has a limit.
@Suite(.serialized) struct HiddenMac {
    /// What a command prints, and how it ends, come back to the chat that asked.
    @Test func aCommandsAnswerComesBack() async throws {
        let project = try await Project()
        let agent = try await project.agent()
        defer { agent.process.terminate() }
        #expect(
            try await project.ask("echo one; sleep 0.1; echo two >&2; sleep 0.1; echo three; exit 3")
                == (3, "one\ntwo\nthree\n"))
        #expect(try await project.ask("kill -9 $$") == (137, ""))
    }

    /// A command ends with nothing of it left running, and when its asker goes, so does all it started.
    @Test func nothingOfACommandOutlivesIt() async throws {
        let project = try await Project()
        let agent = try await project.agent()
        defer { agent.process.terminate() }
        let (status, group) = try await project.ask("sleep 600 & echo $$")
        #expect(status == 0)
        try await Task.sleep(for: .milliseconds(200))
        #expect(kill(-pid_t(group.trimmingCharacters(in: .newlines))!, 0) != 0)

        let mark = project.top.appending(path: "group").path
        let asker = try project.start(["run", project.guestFolder.path, "echo $$ >'\(mark)'; sleep 600 & sleep 600"])
        try #require(try await soon { (try? String(contentsOfFile: mark, encoding: .utf8))?.hasSuffix("\n") == true })
        let left = pid_t(try String(contentsOfFile: mark, encoding: .utf8).trimmingCharacters(in: .newlines))!
        #expect(kill(-left, 0) == 0)
        asker.process.terminate()
        #expect(try await asker.ended() != nil)
        #expect(try await soon(10) { kill(-left, 0) != 0 })
    }

    /// Two chats ask at once: the second is told whose tour runs, waits, and runs once the first has ended.
    @Test func chatsTakeTurns() async throws {
        let project = try await Project()
        let folder = project.guestFolder.path
        let record = project.top.appending(path: "record").path
        let go = project.top.appending(path: "go").path
        // The first holds its turn until the second has said it waits, however slowly this Mac runs the two.
        let first = try project.start([
            "turn", folder, "chat one", "/bin/sh", "-c",
            "for _ in $(seq 1200); do [ -f '\(go)' ] && break; sleep 0.05; done; echo one >>'\(record)'",
        ])
        let lock = project.guestFolder.appending(path: "turn.lock")
        try #require(try await soon { (try? String(contentsOf: lock, encoding: .utf8)) == "chat one\n" })
        let second = try project.start(["turn", folder, "chat two", "/bin/sh", "-c", "echo two >>'\(record)'"])
        try #require(try await soon { !second.said.isEmpty }, "The second chat said nothing.")
        let waiting = second.said
        FileManager.default.createFile(atPath: go, contents: nil)
        #expect(try await second.ended() == 0)
        #expect(try await first.ended() == 0)
        #expect(waiting == "The hidden Mac is busy with chat one; waiting in line.\n")
        #expect(try String(contentsOfFile: record, encoding: .utf8) == "one\ntwo\n")
    }
}
