import Foundation
import Testing

/// Gives the real rules script an issue's state, as GitHub gives it, and the release tags, with Chete in work.
/// Returns the shipped app that the issue's branch may mend beside it, or nothing.
private func mends(_ issue: String, tags: [String] = ["bolo-1.0"]) throws -> String {
    let here = URL(filePath: #filePath).deletingLastPathComponent()
    let process = Process()
    let question = Pipe()
    let answer = Pipe()
    process.executableURL = here.appending(path: "../../Scripts/check").standardizedFileURL
    process.arguments = ["mending", "Chete"]
    process.standardInput = question
    process.standardOutput = answer
    try process.run()
    let tagList = tags.map { "\"\($0)\"" }.joined(separator: ",")
    question.fileHandleForWriting.write(Data(#"{"issue":\#(issue),"tags":[\#(tagList)]}"#.utf8))
    try question.fileHandleForWriting.close()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
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
