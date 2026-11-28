import Foundation
import Testing

/// Gives the real rules script a tour's recorded launch times and a limit, and returns what it says.
private func judged(_ record: String, limit: String) throws -> String {
    try Script.run(Script.check, ["launch", limit], input: Script.recorded("\(record).json")).words
}

/// The record is a real one from GitHub's Mac, with the app's name changed: 2.08, 2.95 and 1.23 seconds for an app that, checked
/// again unchanged, launched in about 1 second every time.
@Test func oneBusyMomentDoesNotFailAnAppThatLaunchesFast() throws {
    #expect(try judged("A Busy Moment", limit: "2") == "yes 1.234094292\n")
}

@Test func anAppWhoseFastestLaunchIsTooSlowStillFails() throws {
    #expect(try judged("A Busy Moment", limit: "1") == "no 1.234094292\n")
}
