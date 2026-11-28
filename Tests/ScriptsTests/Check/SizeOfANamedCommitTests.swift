import Foundation
import Testing

/// A small real repository with the real rules script and a limit of 10 changed lines: a branch of 15 lines of its
/// own, and the folder itself back on `main`, as when the ready step is run from another copy than the branch's.
private struct ElsewhereOnMain {
    let folder: URL
    private(set) var branch = ""

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: "named-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: Script.check, to: folder.appending(path: "Scripts/check"))
        try write("| Rule | Number |\n|---|--:|\n| Changed lines, added plus deleted | 10 |\n", to: "CONSTRAINTS.md")
        try write("Chete\n", to: "NOW")
        try git("init", "-q", "-b", "main")
        try commit("The first page")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("checkout", "-q", "-b", "work")
        try write((1...15).map { "line \($0)\n" }.joined(), to: "branch.txt")
        try commit("The branch's own change")
        branch = try git("rev-parse", "HEAD").trimmingCharacters(in: .whitespacesAndNewlines)
        try git("checkout", "-q", "main")
    }

    private func write(_ words: String, to name: String) throws {
        try Data(words.utf8).write(to: folder.appending(path: name))
    }

    private func commit(_ message: String) throws {
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", message)
    }

    @discardableResult private func git(_ arguments: String...) throws -> String {
        try run("/usr/bin/env", ["git"] + arguments, naming: nil)
    }

    /// What the size rule says, alone, about the commit named as the request's newest, or about the folder.
    func size(of commit: String?) throws -> String {
        try run(folder.appending(path: "Scripts/check").path, ["size"], naming: commit)
    }

    private func run(_ tool: String, _ arguments: [String], naming commit: String?) throws -> String {
        var environment = Script.withoutGit
        environment["PR_HEAD"] = commit
        return try Script.run(URL(filePath: tool), arguments, in: folder, environment: environment).words
    }
}

/// The rules judge the request's newest commit when it is named, whatever the folder holds, so the ready step can
/// judge a request here exactly as GitHub will before it asks anyone.
@Test func theNamedCommitIsJudgedNotTheFolder() throws {
    let place = try ElsewhereOnMain()
    defer { try? FileManager.default.removeItem(at: place.folder) }
    #expect(try place.size(of: place.branch).hasPrefix("FAIL  size"))
}

/// A named commit this copy has never fetched is judged by nothing, so the rules refuse rather than pass it.
@Test func aNamedCommitThatIsNotHereIsNotJudgedAtAll() throws {
    let place = try ElsewhereOnMain()
    defer { try? FileManager.default.removeItem(at: place.folder) }
    #expect(try place.size(of: String(repeating: "0", count: 39) + "1").contains("cannot be judged"))
}

/// With no commit named, the folder is judged as before: here, main, which changes nothing.
@Test func withNoCommitNamedTheFolderIsJudged() throws {
    let place = try ElsewhereOnMain()
    defer { try? FileManager.default.removeItem(at: place.folder) }
    #expect(try place.size(of: nil).hasPrefix("ok    size"))
}
