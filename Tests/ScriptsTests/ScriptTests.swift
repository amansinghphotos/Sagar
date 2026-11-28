import Foundation
import Testing

/// The one way these tests run a script hands it its input, and brings back what it printed and how it ended.
@Test func aToolIsGivenItsInputAndItsAnswerComesBack() throws {
    let said = try Script.run(URL(filePath: "/bin/cat"), input: Data("one\ntwo\n".utf8))
    #expect(said.words == "one\ntwo\n" && said.trimmed == "one\ntwo" && said.passed)
}

/// A failure is told apart from a pass, and a tool's errors are kept out of its answer unless they are asked for.
@Test func aToolsFailureAndItsErrorsAreToldApart() throws {
    let shell = URL(filePath: "/bin/sh")
    let quiet = try Script.run(shell, ["-c", "echo said; echo wrong >&2; exit 3"], errors: .hidden)
    #expect(quiet.words == "said\n" && quiet.status == 3 && !quiet.passed)
    #expect(try Script.run(shell, ["-c", "echo wrong >&2"], errors: .joined).words == "wrong\n")
}

/// A tool runs in the folder named, with only the settings it is given.
@Test func aToolRunsWhereItIsToldWithWhatItIsGiven() throws {
    let folder = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
    let shell = URL(filePath: "/bin/sh")
    let said = try Script.run(shell, ["-c", "pwd; echo $WORD"], in: folder, environment: ["WORD": "kept"]).trimmed
    let lines = said.split(separator: "\n").map(String.init)
    #expect(lines.count == 2 && URL(filePath: lines[0]).resolvingSymlinksInPath().path == folder.path)
    #expect(lines.last == "kept")
    #expect(!Script.withoutGit.keys.contains { $0.hasPrefix("GIT_") })
}
