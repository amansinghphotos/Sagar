import Foundation
import Testing

/// A small real repository with the real rules script and a limit of 10 changed lines: a branch that changes
/// `own` lines, and `main` that has since moved on by 30 lines of its own, being merged into the branch.
private struct Merging {
    let folder: URL

    init(own: Int) throws {
        folder = FileManager.default.temporaryDirectory.appending(path: "size-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: Script.check, to: folder.appending(path: "Scripts/check"))
        try write("| Rule | Number |\n|---|--:|\n| Changed lines, added plus deleted | 10 |\n", to: "CONSTRAINTS.md")
        try write("Chete\n", to: "NOW")
        try git("init", "-q", "-b", "main")
        try commit("The first page")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("checkout", "-q", "-b", "work")
        try write(lines(own), to: "branch.txt")
        try commit("The branch's own change")
        try git("checkout", "-q", "main")
        try write(lines(30), to: "main.txt")
        try commit("Main moves on")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("checkout", "-q", "work")
        // As in the commit hook: the merge is resolved, and waits to be committed.
        try git("merge", "-q", "--no-commit", "--no-ff", "main")
    }

    private func lines(_ count: Int) -> String {
        (1...count).map { "line \($0)\n" }.joined()
    }

    private func write(_ words: String, to name: String) throws {
        try Data(words.utf8).write(to: folder.appending(path: name))
    }

    private func commit(_ message: String) throws {
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", message)
    }

    @discardableResult private func git(_ arguments: String...) throws -> String {
        try run("/usr/bin/env", ["git"] + arguments)
    }

    /// What the size rule says about the merge, alone.
    func size() throws -> String {
        try run(folder.appending(path: "Scripts/check").path, ["size"])
    }

    private func run(_ tool: String, _ arguments: [String]) throws -> String {
        try Script.run(URL(filePath: tool), arguments, in: folder, environment: Script.withoutGit).words
    }
}

/// Bringing a branch up to date with main adds main's lines, which are not the branch's to answer for.
@Test func mergingMainCountsOnlyTheBranchsOwnLines() throws {
    let merging = try Merging(own: 3)
    defer { try? FileManager.default.removeItem(at: merging.folder) }
    #expect(try merging.size().hasPrefix("ok    size"))
}

/// Each rule says how many seconds it took, so that where a check's minutes go is always on its page.
@Test func aRuleSaysItsSeconds() throws {
    let merging = try Merging(own: 3)
    defer { try? FileManager.default.removeItem(at: merging.folder) }
    #expect(try merging.size().split(separator: "\n").first?.wholeMatch(of: /ok    size +\d+ s/) != nil)
}

@Test func aBranchTooLargeOfItsOwnStillFailsWhileMergingMain() throws {
    let merging = try Merging(own: 15)
    defer { try? FileManager.default.removeItem(at: merging.folder) }
    #expect(try merging.size().hasPrefix("FAIL  size"))
}
