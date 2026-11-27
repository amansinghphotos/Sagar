import Foundation
import Testing

/// Gives the real rules script a tour's recorded launch times and a limit, and returns what it says.
private func judged(_ record: String, limit: String) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["launch", limit]
    process.standardInput = try FileHandle(forReadingFrom: here.appending(path: "Fixtures/\(record).json"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// The record is a real one from GitHub's Mac, with the app's name changed: 2.08, 2.95 and 1.23 seconds for an app that, checked
/// again unchanged, launched in about 1 second every time.
@Test func oneBusyMomentDoesNotFailAnAppThatLaunchesFast() throws {
    #expect(try judged("A Busy Moment", limit: "2") == "yes 1.234094292\n")
}

@Test func anAppWhoseFastestLaunchIsTooSlowStillFails() throws {
    #expect(try judged("A Busy Moment", limit: "1") == "no 1.234094292\n")
}
