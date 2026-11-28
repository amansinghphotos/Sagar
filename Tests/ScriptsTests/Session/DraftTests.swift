import Foundation
import Testing

/// Gives the real hook a shell command, as Claude Code does before running one, and says whether it was refused.
private func refused(_ command: String) throws -> Bool {
    let asked = try JSONSerialization.data(withJSONObject: ["tool_input": ["command": command]])
    let hook = Script.repository.appending(path: ".claude/hooks/draft")
    return try Script.run(hook, input: asked, errors: .hidden).status == 2
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
