import Foundation
import Testing

/// Gives the real session-start hook GitHub's recorded reply about pull requests, and returns what it would tell a
/// new session if the repository belonged to `owner`.
private func told(owner: String) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../.claude/hooks/start").standardizedFileURL
    process.arguments = ["answers", owner]
    process.standardInput = try FileHandle(
        forReadingFrom: here.appending(path: "Fixtures/An Approval and a Comment.json"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// The record is a real one, with a comment's words changed: one pull request the owner approved, and one on
/// which he left a comment.
@Test func theOwnersReviewIsTheAnswerAndHisWordsAreShown() throws {
    let told = try told(owner: "amansinghphotos")
    #expect(told.contains("#38 You Approve Only Your Decisions: approved\n"))
    #expect(told.contains("amansinghphotos wrote: It opens where I left it now.\n"))
}

/// Read as another person's repository, the same review and comment come from an outsider.
@Test func anyoneElsesReviewIsNoAnswerAndTheirWordsAreNotShown() throws {
    let told = try told(owner: "someone-else")
    #expect(told.contains("#38 You Approve Only Your Decisions: no answer yet\n"))
    #expect(!told.contains("wrote:"))
}
