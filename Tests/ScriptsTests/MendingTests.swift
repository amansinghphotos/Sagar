import Foundation
import Testing

/// Asks the real rules script one question about a branch, with Chete in work: its issue's state, as GitHub gives
/// it, the release tags, and the open branches. Returns its answer.
private func ask(
    _ question: String, _ issue: String, tags: [String] = ["bolo-1.0"], waiting: [String] = [],
    branch: String = "7-a-slice"
) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let input = Pipe()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = [question, "Chete"]
    process.standardInput = input
    process.standardOutput = answer
    try process.run()
    let list = { (names: [String]) in names.map { "\"\($0)\"" }.joined(separator: ",") }
    let state = #"{"issue":\#(issue),"tags":[\#(list(tags))],"waiting":[\#(list(waiting))],"branch":"\#(branch)"}"#
    input.fileHandleForWriting.write(Data(state.utf8))
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

/// The shipped app that the issue's branch may mend beside the app in work, or nothing.
private func mends(_ issue: String, tags: [String] = ["bolo-1.0"]) throws -> String {
    try ask("mending", issue, tags: tags)
}

/// The waiting release that locks the branch, or nothing.
private func locked(_ issue: String, waiting: [String], branch: String = "7-a-slice") throws -> String {
    try ask("locked", issue, waiting: waiting, branch: branch)
}

nonisolated private func record(state: String = "OPEN", label: String = "fault", milestone: String = "Bolo 1.1")
    -> String
{
    #"{"labels":[{"name":"\#(label)"}],"milestone":{"number":3,"title":"\#(milestone)"},"state":"\#(state)"}"#
}

@Test func aFaultInAShippedAppNamesThatApp() throws {
    #expect(try mends(record()) == "Bolo\n")
}

@Test(arguments: [
    record(label: "enhancement"),  // a wish waits until NOW names the app again
    record(state: "CLOSED"),
    record(milestone: "Chete 1.1"),  // the app in work needs no mend
    #"{"labels":[{"name":"fault"}],"milestone":null,"state":"OPEN"}"#,
    "null",  // GitHub could not say
])
func anythingElseNamesNoApp(issue: String) throws {
    #expect(try mends(issue) == "")
}

@Test func anAppThatHasNotShippedHasNothingToMend() throws {
    #expect(try mends(record(), tags: ["chete-1.0", "bolos-1.0"]) == "")
}

@Test func theAppInWorksReleaseLocksItsOwnBranches() throws {
    #expect(try locked("null", waiting: ["62-first-open", "release/chete-1.0"]) == "release/chete-1.0\n")
}

@Test func theAppInWorksReleaseLeavesAMendFree() throws {
    #expect(try locked(record(), waiting: ["release/chete-1.0"]) == "")
}

@Test func aMendsReleaseLocksOnlyTheMend() throws {
    #expect(try locked(record(), waiting: ["release/bolo-1.1"]) == "release/bolo-1.1\n")
    #expect(try locked("null", waiting: ["release/bolo-1.1"]) == "")
}

@Test func aReleaseIsNotLockedByItself() throws {
    #expect(try locked("null", waiting: ["release/chete-1.0"], branch: "release/chete-1.0") == "")
}
