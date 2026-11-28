import Foundation
import Testing

/// Gives the real release script what Apple's notary said about one submission, and returns what the release reads
/// from it: accepted, refused, or waiting, which means ask again about the same submission.
private func reading(_ said: Data) throws -> String {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let record = folder.appending(path: "answer")
    try said.write(to: record)
    let process = Process()
    let answer = Pipe()
    process.executableURL = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    process.arguments = ["answered"]
    process.standardInput = try FileHandle(forReadingFrom: record)
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

private func recorded(_ name: String) throws -> Data {
    let fixtures = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures")
    return try Data(contentsOf: fixtures.appending(path: name))
}

/// Recorded on 27 November 2026, from the rehearsal of Chete 1.0, with the submission's number made up: Apple still
/// checking, a wait that ran out of its own time while Apple went on checking, and the line notarytool printed when
/// the connection timed out after 23 minutes, as far as it was kept. None of them is an answer, so the release asks
/// again about the same submission instead of stopping.
@Test(arguments: ["Apple Still Checking.json", "A Wait That Ran Out.json", "A Dropped Line.txt"])
func anythingButApplesVerdictMeansAskAgain(record: String) throws {
    #expect(try reading(recorded(record)) == "waiting\n")
}

/// Apple's verdict has the same shape as the recorded answer while it checks, with only the status word changed.
/// No real accepted or refused answer for Chete has been recorded yet, so these two are made that way.
@Test(arguments: [("Accepted", "accepted\n"), ("Invalid", "refused\n"), ("Rejected", "refused\n")])
func applesVerdictEndsTheWait(status: String, reading expected: String) throws {
    let checking = String(decoding: try recorded("Apple Still Checking.json"), as: UTF8.self)
    let verdict = checking.replacingOccurrences(of: "\"status\":\"In Progress\"", with: "\"status\":\"\(status)\"")
    #expect(verdict != checking)
    #expect(try reading(Data(verdict.utf8)) == expected)
}
