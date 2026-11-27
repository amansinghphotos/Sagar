import Foundation
import Testing

/// Runs the real rules script's `owed` rule on the files named, or the whole repository: true when it held, false when
/// it refused, nil when the script failed some other way.
private func holds(_ files: [URL]) throws -> Bool? {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    process.executableURL = script
    process.currentDirectoryURL = script.deletingLastPathComponent().deletingLastPathComponent()
    process.arguments = ["owed"] + files.map(\.path)
    process.standardOutput = Pipe()
    try process.run()
    process.waitUntilExit()
    switch process.terminationStatus {
    case 0: return true
    case 1: return false
    default: return nil
    }
}

/// A file in a temporary folder holding these words.
private func file(_ words: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".swift")
    try words.write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// Search's copyright line or a header saying a file was taken from it is refused; anything else passes.
@Test func searchsNoticeIsRefused() throws {
    #expect(try holds([file("// Copyright (c) 2026 Office" + " Commun. MIT licence.\n")]) == false)
    #expect(try holds([file("// Taken from" + " Search at commit c92ea7c.\n")]) == false)
    #expect(try holds([file("// Drawn from Search's pictures.\n")]) == true)
}

/// A file that is not there fails rather than passing unread.
@Test func aMissingFileFails() throws {
    #expect(try holds([FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)]) == false)
}

/// The repository itself owes Search nothing.
@Test func theRepositoryOwesSearchNothing() throws {
    #expect(try holds([]) == true)
}
