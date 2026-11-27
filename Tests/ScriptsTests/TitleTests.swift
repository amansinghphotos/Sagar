import Foundation
import Testing

/// Asks the real rules script whether a title is in Title Case.
private func isTitleCase(_ title: String) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["title", title]
    process.standardOutput = answer
    try process.run()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
}

@Test(arguments: [
    "Release Bolo 1.0", "The Owner Answers in One Place", "Chete Remembers the Last 50 Copies",
    "Fix the Copy Button on macOS", "Bolo's First-Open Window", "macOS Opens It Faster",
])
func titleCasePasses(title: String) throws {
    #expect(try isTitleCase(title))
}

@Test(arguments: [
    "The owner answers in one place", "release Bolo 1.0", "Fix the copy button", "", "bolo's first-open window",
    "The (copy) Button Works", "Fix the Copy-button",
])
func anyOtherCaseFails(title: String) throws {
    #expect(try !isTitleCase(title))
}
