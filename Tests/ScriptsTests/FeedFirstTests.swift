import Foundation
import Testing

/// Gives the real rules script an app's lines from a tour's system log, and returns what it says.
private func judged(_ log: String) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["feed"]
    process.standardInput = try FileHandle(forReadingFrom: here.appending(path: "Fixtures/A Tour's Log, \(log).txt"))
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// GitHub's log of a real tour (run 46097693413): Chete asked for its update feed only once its menu-bar card was
/// first opened, so it would never have checked for updates had nobody opened the card (#316).
@Test func anAppThatAsksForItsFeedOnlyOnceItsCardIsOpenedFails() throws {
    #expect(try judged("Before, the Card Asks First") == "no\n")
}

/// The hidden Mac's log of a real tour of the mend: Chete asked for its feed as it opened, before any card.
@Test func anAppThatAsksForItsFeedAsItOpensPasses() throws {
    #expect(try judged("After, the Feed Comes First") == "yes\n")
}
