import Foundation
import Testing

/// A small real repository with the real rules script in it: `main` as GitHub has it, and one chat's change made
/// from an older `main`, the way two chats work side by side.
private struct TwoChats {
    let folder: URL

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: "clash-\(UUID().uuidString)")
        let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: script, to: folder.appending(path: "Scripts/check"))
        try git("init", "-q", "-b", "main")
        try write("one\ntwo\nthree\n", to: "Package.swift")
        try commit("The first page")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("switch", "-q", "-c", "chete")
    }

    func write(_ words: String, to name: String) throws {
        try Data(words.utf8).write(to: folder.appending(path: name))
    }

    func commit(_ message: String) throws {
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", message)
    }

    /// The other chat's change, merged into `main` on GitHub while this one worked.
    func mainTakes(_ words: String, in name: String) throws {
        try git("switch", "-q", "main")
        try write(words, to: name)
        try commit("The other chat's change")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("switch", "-q", "chete")
    }

    @discardableResult func git(_ arguments: String...) throws -> String {
        try run("/usr/bin/env", ["git"] + arguments).words
    }

    /// What the rules script says of this chat's newest commit against `main` as GitHub has it.
    func clashes() throws -> (words: String, clear: Bool) {
        try run(folder.appending(path: "Scripts/check").path, ["clashes", try git("rev-parse", "HEAD")])
    }

    private func run(_ tool: String, _ arguments: [String]) throws -> (words: String, clear: Bool) {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        // Inside a commit hook git names its own folder; the small repository must not be sent to the real one.
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        process.standardOutput = answer
        try process.run()
        process.waitUntilExit()
        let words = String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return (words.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus == 0)
    }
}

/// Two chats changed the same line of the package file: GitHub cannot merge the later one as it is.
@Test func twoChangesToTheSameLineClash() throws {
    let chats = try TwoChats()
    defer { try? FileManager.default.removeItem(at: chats.folder) }
    try chats.write("one\ntwo, for Chete\nthree\n", to: "Package.swift")
    try chats.commit("Chete's change")
    try chats.mainTakes("one\ntwo, for the Look\nthree\n", in: "Package.swift")
    #expect(try chats.clashes() == ("Package.swift", false))
}

@Test func changesToDifferentFilesDoNotClash() throws {
    let chats = try TwoChats()
    defer { try? FileManager.default.removeItem(at: chats.folder) }
    try chats.write("one\ntwo, for Chete\nthree\n", to: "Package.swift")
    try chats.commit("Chete's change")
    try chats.mainTakes("colours\n", in: "Colour.swift")
    #expect(try chats.clashes() == ("", true))
}
