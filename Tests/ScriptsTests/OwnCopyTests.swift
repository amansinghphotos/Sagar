import Foundation
import Testing

/// A small real repository with the real rules script committed in it, and a second copy of it made the way each
/// chat makes its own: the shared folder, and a linked copy beside it.
private struct Shared {
    let folder: URL
    let copy: URL

    init() throws {
        let top = FileManager.default.temporaryDirectory.appending(path: "own-copy-\(UUID().uuidString)")
        folder = top.appending(path: "shared")
        copy = top.appending(path: "copy")
        let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: script, to: folder.appending(path: "Scripts/check"))
        try git("init", "-q", "-b", "main")
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", "First")
        try git("worktree", "add", "-q", "-b", "71-a-slice", copy.path)
    }

    @discardableResult func git(_ arguments: String...) throws -> String {
        try run("/usr/bin/env", ["git"] + arguments, in: folder).words
    }

    /// What the commit gate's folder rule says in a folder, and whether it lets the commit through.
    func gate(in place: URL) throws -> (words: String, passes: Bool) {
        try run(place.appending(path: "Scripts/check").path, ["folder"], in: place)
    }

    private func run(_ tool: String, _ arguments: [String], in place: URL) throws -> (words: String, passes: Bool) {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = place
        // Inside a commit hook git names its own folder; the small repository must not be sent to the real one.
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        process.standardOutput = answer
        process.standardError = answer
        try process.run()
        process.waitUntilExit()
        let words = String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return (words.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus == 0)
    }
}

/// Two chats in one folder: when one switches branch, the other's commit lands on it.
@Test func aCommitInTheSharedFolderIsRefused() throws {
    let shared = try Shared()
    defer { try? FileManager.default.removeItem(at: shared.folder.deletingLastPathComponent()) }
    try shared.git("switch", "-q", "-c", "15-another-slice")
    let gate = try shared.gate(in: shared.folder)
    #expect(!gate.passes)
    #expect(gate.words.contains("your own copy"))
}

@Test func aCommitOnMainInTheSharedFolderIsRefused() throws {
    let shared = try Shared()
    defer { try? FileManager.default.removeItem(at: shared.folder.deletingLastPathComponent()) }
    #expect(try !shared.gate(in: shared.folder).passes)
}

@Test func aCommitInAChatsOwnCopyPasses() throws {
    let shared = try Shared()
    defer { try? FileManager.default.removeItem(at: shared.folder.deletingLastPathComponent()) }
    #expect(try shared.gate(in: shared.copy) == ("", true))
}

/// The release is made in the shared folder, from clean `main`, when nothing else is open.
@Test func aReleaseCommitsInTheSharedFolder() throws {
    let shared = try Shared()
    defer { try? FileManager.default.removeItem(at: shared.folder.deletingLastPathComponent()) }
    try shared.git("switch", "-q", "-c", "release/chete-1.0")
    #expect(try shared.gate(in: shared.folder) == ("", true))
}
