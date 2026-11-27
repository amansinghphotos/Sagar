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

/// Pasting for You, as GitHub answered for it: both checks passed and nobody had to answer, so GitHub refused to
/// wait and left it open.
@Test func workWithNothingLeftToWaitForIsMergedNow() throws {
    #expect(try merging("Nothing Left to Wait For") == "now\n")
}

/// Clips Are Kept while it waited for the owner's approval: it must wait for him.
@Test func workThatWaitsForTheOwnerIsNotMergedNow() throws {
    #expect(try merging("Waiting for the Owner") == "wait\n")
}

/// A pull request just brought up to date, before GitHub has worked out where it stands.
@Test func workGitHubHasNotWorkedOutIsNotMergedNow() throws {
    #expect(try merging("Not Yet Worked Out") == "wait\n")
}
