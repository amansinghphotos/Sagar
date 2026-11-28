import Foundation

/// The real scripts, and the one way these tests run them.
enum Script {
    static let repository = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL
    static let check = repository.appending(path: "Scripts/check")
    static let release = repository.appending(path: "Scripts/release")

    /// The settings a tool is started with, without git's own. Inside a commit hook git names its folder there,
    /// and a test's small repository must not be sent to the real one.
    static var withoutGit: [String: String] {
        ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
    }

    /// A recorded answer, kept in `Fixtures`.
    static func recorded(_ name: String) throws -> Data {
        try Data(contentsOf: repository.appending(path: "Tests/ScriptsTests/Fixtures/\(name)"))
    }

    /// What a tool printed, and how it ended.
    struct Said {
        var words: String
        var status: Int32
        var passed: Bool { status == 0 }
        var trimmed: String { words.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// Where a tool's errors go: the test's own log, nowhere, or in with what it printed.
    enum Errors { case shown, hidden, joined }

    /// Runs a real tool, hands it its input, waits for it, and returns what it said.
    @discardableResult static func run(
        _ tool: URL, _ arguments: [String] = [], input: Data? = nil, in folder: URL? = nil,
        environment: [String: String]? = nil, errors: Errors = .shown
    ) throws -> Said {
        let process = Process()
        let answer = Pipe()
        let given = Pipe()
        process.executableURL = tool
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = environment
        process.standardOutput = answer
        if input != nil { process.standardInput = given }
        switch errors {
        case .shown: break
        case .hidden: process.standardError = FileHandle.nullDevice
        case .joined: process.standardError = answer
        }
        try process.run()
        if let input {
            given.fileHandleForWriting.write(input)
            try given.fileHandleForWriting.close()
        }
        let words = String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        return Said(words: words, status: process.terminationStatus)
    }
}
