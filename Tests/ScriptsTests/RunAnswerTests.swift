import Foundation
import Testing

/// Gives the real rules script what `gh run view --json status,conclusion` answered, and how it ended, and returns
/// what the ready step reads from it: passed, failed, running, or unanswered.
private func reading(_ record: String, ended status: Int32) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["run", String(status)]
    process.standardInput = try FileHandle(forReadingFrom: here.appending(path: "Fixtures/\(record)"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// Recorded from GitHub on 27 November 2026: a check that passed, one that failed, and one still running.
@Test(arguments: [
    ("A Run That Passed.json", "passed\n"), ("A Run That Failed.json", "failed\n"),
    ("A Run Still Going.json", "running\n"),
])
func githubsAnswerAboutARunIsReadAsItSays(record: String, reading expected: String) throws {
    #expect(try reading(record, ended: 0) == expected)
}

/// Recorded the same day, when the agents' hourly allowance ran out: gh ended with 1 and this error. The ready step
/// once read it as a failed check, though the check was still running and passed.
@Test func githubNotAnsweringIsNeitherAFailureNorAPass() throws {
    #expect(try reading("Out of Allowance.txt", ended: 1) == "unanswered\n")
}

/// A pass is believed only when gh itself ended well: the same recorded pass from a gh that failed counts for nothing,
/// and so does an answer that is not GitHub's at all.
@Test(arguments: [("A Run That Passed.json", Int32(1)), ("Out of Allowance.txt", Int32(0))])
func aPassIsNeverTakenFromAnythingButAnAnswer(record: String, ended status: Int32) throws {
    #expect(try reading(record, ended: status) == "unanswered\n")
}
