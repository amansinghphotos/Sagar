import Foundation
import Testing

private let project = Script.repository

/// Runs a tool in a folder and returns what it printed, its last line break left off.
private func run(_ tool: URL, _ arguments: [String], in folder: URL, environment: [String: String]) throws -> String {
    try Script.run(tool, arguments, in: folder, environment: environment).words.trimmingCharacters(in: .newlines)
}

/// Where a folder really is, past the links macOS puts in front of its temporary folders.
private func real(_ path: String) -> String {
    URL(filePath: path).resolvingSymlinksInPath().path
}

/// Inside a commit hook git names this project's own folder in the environment. A tool the rules start, such as a
/// package fetch working in a repository of its own, must reach that repository and not this project.
@Test func aToolTheRulesStartWorksInItsOwnRepository() throws {
    let plain = Script.withoutGit
    let git = URL(filePath: "/usr/bin/env")
    let ours = try run(git, ["git", "rev-parse", "--absolute-git-dir"], in: project, environment: plain)
    let fetched = FileManager.default.temporaryDirectory.appending(path: "fetched-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: fetched, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: fetched) }
    _ = try run(git, ["git", "init", "-q"], in: fetched, environment: plain)

    var hook = plain
    hook["GIT_DIR"] = ours
    hook["GIT_INDEX_FILE"] = ours + "/index"
    let answer = try run(
        project.appending(path: "Scripts/check"),
        ["tool", "git", "-C", fetched.path, "rev-parse", "--absolute-git-dir"],
        in: project, environment: hook)
    #expect(real(answer) == real(fetched.appending(path: ".git").path))
}
