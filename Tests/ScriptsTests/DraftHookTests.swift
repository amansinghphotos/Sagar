import Foundation
import Testing

/// Gives the real hook a shell command, as Claude Code does before running one, and says whether it was refused.
private func refused(_ command: String) throws -> Bool {
    let hook = URL(filePath: #filePath).appending(path: "../../../.claude/hooks/draft").standardizedFileURL
    let process = Process()
    let input = Pipe()
    process.executableURL = hook
    process.standardInput = input
    process.standardError = Pipe()
    try process.run()
    let asked = try JSONSerialization.data(withJSONObject: ["tool_input": ["command": command]])
    input.fileHandleForWriting.write(asked)
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    return process.terminationStatus == 2
}

@Test(arguments: [
    "gh pr create --title x --body y", "gh pr ready 5", "cd a && gh pr ready 5",
    "gh pr create --title x && gh pr create --draft --title y", "gh pr ready 5; gh pr ready 6 --undo",
])
func openingUndraftedOrMarkingReadyByHandIsRefused(command: String) throws {
    #expect(try refused(command))
}

@Test(arguments: [
    "gh pr create --draft --title x", "gh pr ready 5 --undo", "Scripts/check ready 5", "gh pr view 5", "git status",
])
func everythingElseGoesThrough(command: String) throws {
    #expect(try !refused(command))
}
