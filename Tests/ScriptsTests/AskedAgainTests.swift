import Foundation
import Testing

/// Gives the real rules script what GitHub says of a pull request's reviews and requested reviewers, and returns
/// whether the owner is asked, as the ready step must leave him whenever he answered before.
private func asked(_ state: String) throws -> String {
    let process = Process()
    let answer = Pipe()
    let given = Pipe()
    process.executableURL = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    process.arguments = ["asked", "amansinghphotos"]
    process.standardInput = given
    process.standardOutput = answer
    try process.run()
    given.fileHandleForWriting.write(Data(state.utf8))
    try given.fileHandleForWriting.close()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

private nonisolated let answered = #"[{"author": {"login": "amansinghphotos"}, "state": "CHANGES_REQUESTED"}]"#

@Test(arguments: [
    // He never answered: nothing to ask him again, as GitHub asks him the first time.
    (#"{"reviews": [], "reviewRequests": []}"#, "yes"),
    // He answered and is asked again.
    (#"{"reviews": \#(answered), "reviewRequests": [{"login": "amansinghphotos"}]}"#, "yes"),
    // He answered and nobody asked him again: what happened on #216.
    (#"{"reviews": \#(answered), "reviewRequests": []}"#, "no"),
    // Someone else is asked, not he.
    (#"{"reviews": \#(answered), "reviewRequests": [{"login": "someone"}]}"#, "no"),
    // GitHub gave no answer, as when the allowance runs out: never read as asked.
    ("", "unanswered"), (#"{"message": "API rate limit exceeded"}"#, "unanswered"),
])
func heIsAskedWheneverHeAnsweredBefore(state: String, said: String) throws {
    #expect(try asked(state) == said + "\n")
}
