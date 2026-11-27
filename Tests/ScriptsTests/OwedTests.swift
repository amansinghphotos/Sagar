import Foundation
import Testing

/// Runs the real rules script's `owed` rule on the files named, or the whole repository, and says whether it held.
private func holds(_ files: [URL]) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    process.executableURL = script
    process.currentDirectoryURL = script.deletingLastPathComponent().deletingLastPathComponent()
    process.arguments = ["owed"] + files.map(\.path)
    process.standardOutput = Pipe()
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus == 0
}

/// A file in a temporary folder holding these words.
private func file(_ words: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".swift")
    try words.write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// Search's copyright line or a header saying a file was taken from it is refused; anything else passes.
@Test func searchsNoticeIsRefused() throws {
    #expect(try !holds([file("// Copyright (c) 2026 Office" + " Commun. MIT licence.\n")]))
    #expect(try !holds([file("// Taken from" + " Search at commit c92ea7c.\n")]))
    #expect(try holds([file("// Drawn from Search's pictures.\n")]))
}

/// The repository itself owes Search nothing.
@Test func theRepositoryOwesSearchNothing() throws {
    #expect(try holds([]))
}
