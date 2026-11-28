import Foundation
import Testing

/// Asks the real rules script whether a change to these files is words only, and so skips build, tests and tour.
private func wordsOnly(_ files: [String]) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["words"] + files
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
}

@Test(arguments: [
    ["docs/bolo/appcast.xml", "docs/index.html"], ["spec/chete.md"], ["README.md", "SPEC.md"],
    [".github/CODEOWNERS"], [".github/pull_request_template.md"], ["Checklists/Start.md"],
])
func aChangeToWordsSkipsBuildingAndTouring(files: [String]) throws {
    #expect(try wordsOnly(files))
}

@Test(arguments: [
    ["CONSTRAINTS.md"], ["README.md", "CONSTRAINTS.md"], ["Sources/Shell/Notes.md"], ["Tests/Fixtures/note.md"],
    ["Apps/Bolo/Main.swift"], ["Scripts/check"], [".github/workflows/check.yml"], ["NOW"], ["Package.swift"],
    ["docs/index.html", "Sources/Shell/Updates.swift"], ["Config/Info.plist"], [".claude/hooks/start"],
])
func anyOtherChangeRunsEverything(files: [String]) throws {
    #expect(try !wordsOnly(files))
}

/// Asks the real rules script, in a small real repository whose branch changes `files` since main, whether the
/// branch's own change is words only: what GitHub asks to choose the machine its check runs on.
private func branchIsWordsOnly(_ files: [String]) throws -> String {
    let folder = FileManager.default.temporaryDirectory.appending(path: "words-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: folder) }
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    try FileManager.default.createDirectory(at: folder.appending(path: "Scripts"), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: script, to: folder.appending(path: "Scripts/check"))
    func run(_ tool: String, _ arguments: String...) throws -> String {
        let process = Process()
        let answer = Pipe()
        process.executableURL = URL(filePath: tool)
        process.arguments = arguments
        process.currentDirectoryURL = folder
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        process.standardOutput = answer
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CocoaError(.executableLoad) }
        return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }
    func commit() throws {
        _ = try run("/usr/bin/env", "git", "add", "-A")
        _ = try run(
            "/usr/bin/env", "git", "-c", "user.name=Test", "-c", "user.email=test@users.noreply.github.com",
            "commit", "-q", "-m", "A change")
    }
    try Data("Chete\n".utf8).write(to: folder.appending(path: "NOW"))
    _ = try run("/usr/bin/env", "git", "init", "-q", "-b", "main")
    try commit()
    _ = try run("/usr/bin/env", "git", "update-ref", "refs/remotes/origin/main", "HEAD")
    for file in files {
        let url = folder.appending(path: file)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("words\n".utf8).write(to: url)
    }
    if !files.isEmpty { try commit() }
    return try run(folder.appending(path: "Scripts/check").path, "words")
}

@Test func aBranchOfWordsAloneIsCheckedWithoutBuilding() throws {
    #expect(try branchIsWordsOnly(["spec/chete.md", "Checklists/Start.md"]) == "yes\n")
}

/// Main as it stands, after a merge, has changed nothing since itself: it is always built, tested and toured.
@Test(arguments: [["spec/chete.md", "Sources/Keep/Store.swift"], ["Scripts/release"], []])
func anyOtherBranchIsBuilt(files: [String]) throws {
    #expect(try branchIsWordsOnly(files) == "no\n")
}
