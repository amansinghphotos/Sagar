import Foundation
import Testing

/// Gives the real rules script GitHub's recorded answer about where a pull request stands, and returns whether the
/// ready step may merge it at once.
private func merging(_ record: String) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["merging"]
    process.standardInput = try FileHandle(forReadingFrom: here.appending(path: "Fixtures/\(record).json"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// Recorded from GitHub for Pasting for You: both checks passed and nobody had to answer, so GitHub refused to wait
/// and left it open.
@Test func workWithNothingLeftToWaitForIsMergedNow() throws {
    #expect(try merging("Nothing Left to Wait For") == "now\n")
}

/// Recorded from GitHub for a pull request it still blocked, as it blocks one that waits for the owner's approval.
@Test func workGitHubStillBlocksIsNotMergedNow() throws {
    #expect(try merging("Still Blocked") == "wait\n")
}

/// Recorded from GitHub for a pull request just brought up to date, before it had worked out where it stands.
@Test func workGitHubHasNotWorkedOutIsNotMergedNow() throws {
    #expect(try merging("Not Yet Worked Out") == "wait\n")
}

/// Made up, since no pull request has had one yet: the owner asked for changes on files he does not own, so GitHub
/// itself would merge it, but his words still stand.
@Test func workTheOwnerAskedToChangeIsNotMergedNow() throws {
    #expect(try merging("Changes Asked For") == "wait\n")
}
