import Foundation
import Testing

/// Gives the real rules script GitHub's recorded list of a pull request's comments and that pull request's newest
/// commit, and returns whether it finds the reviewer's reply to that commit.
private func reviewed(_ record: String, newest commit: String) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["reviewed", commit]
    process.standardInput = try FileHandle(forReadingFrom: here.appending(path: "Fixtures/\(record).json"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

private nonisolated let newestOf46 = "3619bf5e2df1ffb7d4f57be54d5c66b144365f60"
private nonisolated let newestOf48 = "b37a8072345ecb907f9f921e1222b404f37f7777"

/// The recorded comments of a real pull request, with the app's name changed. Its last one came after its last commit, but reports a reading of the one before.
@Test func aReplyAboutAnEarlierCommitDoesNotCount() throws {
    #expect(try reviewed("The Unread Last Commit", newest: newestOf46) == "no\n")
}

/// The recorded comments of another real pull request: the agents' folded reply names the commit the reviewer read.
@Test func aFoldedReplyThatNamesTheNewestCommitCounts() throws {
    #expect(try reviewed("A Reply That Names Its Commit", newest: newestOf48) == "yes\n")
}

/// The same real reply stops counting once another commit is the newest, or when no commit is given at all.
@Test(arguments: [newestOf46, ""])
func theSameReplyDoesNotCoverAnotherCommit(commit: String) throws {
    #expect(try reviewed("A Reply That Names Its Commit", newest: commit) == "no\n")
}

/// The environment without git's own settings, which would send git to another repository than the small one.
private func withoutGitsOwnSettings(_ environment: [String: String]) -> [String: String] {
    environment.filter { !$0.key.hasPrefix("GIT_") }
}

/// A small real repository with the real rules script in it: `main`, a branch whose change the reviewer read,
/// then `main` moving on and the branch brought up to date with it. A change to the working rules changes a
/// file beside the rules script; any other changes a page of its own.
private struct Branch {
    let folder: URL
    private(set) var read = ""

    init(changing changed: String = "changed.txt") throws {
        folder = FileManager.default.temporaryDirectory.appending(path: "reviewed-\(UUID().uuidString)")
        let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
        try FileManager.default.createDirectory(
            at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: script, to: folder.appending(path: "Scripts/check"))
        try git("init", "-q", "-b", "main")
        try write("one", to: "kept.txt")
        try commit("The first page")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("checkout", "-q", "-b", "work")
        try write("the change", to: changed)
        try commit("The change the reviewer read")
        read = try git("rev-parse", "HEAD")
        try git("checkout", "-q", "main")
        try write("two", to: "elsewhere.txt")
        try commit("Main moves on")
        try git("update-ref", "refs/remotes/origin/main", "HEAD")
        try git("checkout", "-q", "work")
        try git("merge", "-q", "--no-edit", "main")
    }

    func write(_ words: String, to name: String) throws {
        try Data(words.utf8).write(to: folder.appending(path: name))
    }

    func commit(_ message: String) throws {
        try git("add", "-A")
        try git("-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com", "commit", "-q", "-m", message)
    }

    @discardableResult func git(_ arguments: String...) throws -> String {
        try run("/usr/bin/env", ["git"] + arguments, input: nil)
    }

    /// A commit after the reading, as a mend of what it found.
    @discardableResult mutating func mend(_ words: String) throws -> String {
        try write(words, to: "mend.txt")
        try commit("A mend of the reading")
        return try git("rev-parse", "HEAD").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the script, given a folded reply from the agents' app, counts the branch as it now stands as
    /// read. Unless another reply is given, it names the commit read.
    func countsAsRead(_ words: String? = nil) throws -> String {
        let reply: [[String: Any]] = [
            ["user": ["login": "sagar-agent[bot]"], "body": words ?? "<details>Read at \(read.prefix(7)).</details>"]
        ]
        let newest = try git("rev-parse", "HEAD")
        return try run(
            folder.appending(path: "Scripts/check").path, ["reviewed", newest],
            input: JSONSerialization.data(withJSONObject: reply))
    }

    private func run(_ tool: String, _ arguments: [String], input: Data?) throws -> String {
        let process = Process()
        let answer = Pipe()
        let given = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = withoutGitsOwnSettings(ProcessInfo.processInfo.environment)
        process.standardOutput = answer
        process.standardInput = given
        try process.run()
        given.fileHandleForWriting.write(input ?? Data())
        try given.fileHandleForWriting.close()
        process.waitUntilExit()
        return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Bringing a branch up to date with `main` changes its newest commit, but not what it changes.
@Test func aChangeAlreadyReadNeedsNoSecondReadingWhenOnlyMainMoved() throws {
    let branch = try Branch()
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    #expect(try branch.countsAsRead() == "yes")
}

@Test func aChangeThatChangedAfterItWasReadNeedsANewReading() throws {
    let branch = try Branch()
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    try branch.write("the change, and more", to: "changed.txt")
    try branch.commit("More, after the reading")
    #expect(try branch.countsAsRead() == "no")
}

/// Its one mend, answered on the reading, is not read again: only a change to the change itself is.
@Test func theOneMendAnsweredOnTheReadingNeedsNoSecondReading() throws {
    var branch = try Branch()
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    let mend = try branch.mend("mended")
    let reply = "<details><summary>The reviewer read \(branch.read.prefix(7)), answered at \(mend.prefix(7))</summary>"
    #expect(try branch.countsAsRead(reply) == "yes")
}

/// A second commit after the reading is more than its mend.
@Test func aSecondCommitAfterTheReadingNeedsANewReading() throws {
    var branch = try Branch()
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    try branch.mend("mended")
    let more = try branch.mend("mended, and more")
    let reply = "<details><summary>The reviewer read \(branch.read.prefix(7)), answered at \(more.prefix(7))</summary>"
    #expect(try branch.countsAsRead(reply) == "no")
}

/// A reply that names only the mend, and no commit read, is no reading.
@Test func aMendNamedWithoutTheCommitReadIsNoReading() throws {
    var branch = try Branch()
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    let mend = try branch.mend("mended")
    #expect(
        try branch.countsAsRead("<details><summary>Reviewer's reading, answered at \(mend.prefix(7))</summary>") == "no"
    )
}

/// A change to the working rules could weaken a check, so its mend is read again, and that reading counts.
@Test func aMendOfTheWorkingRulesIsReadAgain() throws {
    var branch = try Branch(changing: "Scripts/rule.txt")
    defer { try? FileManager.default.removeItem(at: branch.folder) }
    let mend = try branch.mend("mended")
    let answered =
        "<details><summary>The reviewer read \(branch.read.prefix(7)), answered at \(mend.prefix(7))</summary>"
    #expect(try branch.countsAsRead(answered) == "no")
    #expect(try branch.countsAsRead("<details><summary>The reviewer read \(mend.prefix(7))</summary>") == "yes")
}

/// Inside a commit hook, git names its own folder: in a second working copy it reaches the test as `GIT_DIR`.
@Test func gitsOwnSettingsAreLeftOutOfTheSmallRepository() {
    let hook = ["GIT_DIR": "/a/real/.git/worktrees/one", "GIT_INDEX_FILE": "index", "PATH": "/usr/bin"]
    #expect(withoutGitsOwnSettings(hook) == ["PATH": "/usr/bin"])
}
