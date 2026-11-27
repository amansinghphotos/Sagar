import Foundation
import Testing

/// Asks the real release script whether a release of an app may start, with Chete in work, from the open branches
/// and the open issues in the release's milestone, as GitHub gives them. Returns why not, or nothing.
private func whyNot(_ app: String, open: [String], milestone: [String] = []) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let input = Pipe()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/release").standardizedFileURL
    process.arguments = ["may", app, "Chete"]
    process.standardInput = input
    process.standardOutput = answer
    try process.run()
    let branches = open.map { "\"\($0)\"" }.joined(separator: ",")
    let state = #"{"open":[\#(branches)],"milestone":[\#(milestone.joined(separator: ","))]}"#
    input.fileHandleForWriting.write(Data(state.utf8))
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

nonisolated private func issue(_ number: Int, _ label: String) -> String {
    #"{"number":\#(number),"labels":[{"name":"\#(label)"}]}"#
}

@Test func aReleaseStartsBesideOpenWork() throws {
    #expect(try whyNot("Chete", open: ["62-first-open", "174-a-fault"]) == "")
    #expect(try whyNot("Bolo", open: ["62-first-open"], milestone: [issue(174, "fault"), issue(175, "release")]) == "")
}

@Test func aReleaseWaitsWhileAnotherBuildWaits() throws {
    #expect(try whyNot("Bolo", open: ["62-first-open", "release/chete-1.0"]) != "")
    #expect(try whyNot("Chete", open: ["release/bolo-1.1"]) != "")
}

@Test func aMendedAppShipsFaultsOnly() throws {
    #expect(try whyNot("Bolo", open: [], milestone: [issue(174, "fault"), issue(176, "enhancement")]).contains("#176"))
    #expect(try whyNot("Chete", open: [], milestone: [issue(60, "enhancement")]) == "")
}
