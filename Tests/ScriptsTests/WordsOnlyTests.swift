import Foundation
import Testing

/// Asks the real rules script whether a change to these files is words only, and so skips build, tests and tour.
private func wordsOnly(_ files: [String]) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["words"] + files
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
}

@Test(arguments: [
    ["docs/bolo/appcast.xml", "docs/index.html"], ["spec/chete.md"], ["README.md", "SPEC.md"],
    [".github/CODEOWNERS"], [".github/pull_request_template.md"], ["Checklists/Start.md"],
])
func aChangeToWordsSkipsBuildingAndTouring(files: [String]) throws {
    #expect(try wordsOnly(files))
}

@Test(arguments: [
    ["CONSTRAINTS.md"], ["README.md", "CONSTRAINTS.md"], ["Sources/Shell/Notes.md"], ["Tests/Fixtures/note.md"],
    ["Apps/Bolo/Main.swift"], ["Scripts/check"], [".github/workflows/check.yml"], ["NOW"], ["Package.swift"],
    ["docs/index.html", "Sources/Shell/Updates.swift"], ["Config/Info.plist"], [".claude/hooks/start"],
])
func anyOtherChangeRunsEverything(files: [String]) throws {
    #expect(try !wordsOnly(files))
}
