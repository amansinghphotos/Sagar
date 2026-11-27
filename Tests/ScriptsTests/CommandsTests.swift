import Foundation
import Testing

/// A small real repository holding the real rules script, as main has it.
private struct Commands {
    let folder = FileManager.default.temporaryDirectory.appending(path: "commands-\(UUID().uuidString)")
    var script: URL { folder.appending(path: "Scripts/check") }

    init() throws {
        let real = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: real, to: script)
        try Data("Chete\n".utf8).write(to: folder.appending(path: "NOW"))
        try git("init", "-q", "-b", "main")
        try commit("The rules")
    }

    /// Adds a command the way a piece of work would: one line where the script answers it, after `place`.
    func add(_ name: String, after place: String) throws {
        var lines = try String(contentsOf: script, encoding: .utf8).components(separatedBy: "\n")
        let at = try #require(lines.firstIndex { $0.hasPrefix(place) })
        lines.insert("[ \"${1:-}\" != \(name) ] || { echo \"\(name) answered\"; exit; }", at: at + 1)
        try Data(lines.joined(separator: "\n").utf8).write(to: script)
    }

    func commit(_ message: String) throws {
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", message)
    }

    @discardableResult func git(_ arguments: String...) throws -> (said: String, status: Int32) {
        try run("/usr/bin/env", ["git"] + arguments)
    }

    func check(_ arguments: String...) throws -> (said: String, status: Int32) {
        try run(script.path, arguments)
    }

    private func run(_ tool: String, _ arguments: [String]) throws -> (said: String, status: Int32) {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        process.standardOutput = answer
        process.standardError = answer
        try process.run()
        let said = answer.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (String(decoding: said, as: UTF8.self), process.terminationStatus)
    }
}

/// Two pieces of work each add a command where the script answers it, and touch no shared line: git merges them
/// both, and both are answered.
@Test func twoNewCommandsMergeWithoutAClash() throws {
    let commands = try Commands()
    defer { try? FileManager.default.removeItem(at: commands.folder) }
    try commands.git("checkout", "-q", "-b", "one")
    try commands.add("alpha", after: "[ \"${1:-}\" != title ]")
    try commands.commit("Alpha")
    try commands.git("checkout", "-q", "main")
    try commands.git("checkout", "-q", "-b", "two")
    try commands.add("omega", after: "[ \"${1:-}\" != reviewed ]")
    try commands.commit("Omega")
    #expect(try commands.git("merge", "-q", "--no-edit", "one").status == 0)
    #expect(try commands.check("alpha").said == "alpha answered\n")
    #expect(try commands.check("omega").said == "omega answered\n")
}

/// A word the script does not answer is a mistake, even one that reads as a pattern: it stops with the usage, never
/// running every rule.
@Test(arguments: ["tours", ".*", "w.*", "words\nsize", "Words"])
func anUnknownCommandStopsWithTheUsage(word: String) throws {
    let commands = try Commands()
    defer { try? FileManager.default.removeItem(at: commands.folder) }
    let answer = try commands.check(word)
    #expect(answer.status == 2)
    #expect(answer.said.hasPrefix("Usage: Scripts/check"))
    #expect(answer.said.contains("| words"))
    #expect(!answer.said.contains("All rules hold"))
}
