import Foundation
import Testing

/// Asks the real release script about a release's notes: nothing if they are not allowed, else the reason it
/// gives the owner, which comes from the first line that is there.
private func reason(for notes: String) throws -> String? {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    let process = Process()
    let question = Pipe()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["why"]
    process.standardInput = question
    process.standardOutput = answer
    process.standardError = Pipe()
    try process.run()
    question.fileHandleForWriting.write(Data(notes.utf8))
    try question.fileHandleForWriting.close()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
}

@Test(arguments: [
    (
        "New: find a clip by typing.\nBetter: the list opens faster.\nFixed: pasting no longer stalls.\n",
        "Find a clip by typing.\n"
    ),
    ("Better: the list opens faster.\nFixed: pasting no longer stalls.\n", "The list opens faster.\n"),
    ("New: find a clip by typing.\nFixed: pasting no longer stalls.\n", "Find a clip by typing.\n"),
    ("Fixed: pasting no longer stalls.\n", "Pasting no longer stalls.\n"),
    ("Better: the list opens faster.\n", "The list opens faster.\n"),
])
func aLineWithNothingToSayCanBeLeftOut(notes: String, why: String) throws {
    #expect(try reason(for: notes) == why)
}

@Test(arguments: [
    "", "\n", "New: \n", "Better:\nFixed: pasting no longer stalls.\n", "Fixed: it works.\nNew: and more.\n",
    "New:   \n", "Fixed: it works.\nBetter: \t\n", "New: one.\nNew: two.\n", "Fixed: it works.\nBetter: and faster.\n",
    "Added: a thing.\n", "New: fixes #12.\n",
    "New: the `list` is faster.\n", "New: one.\n\nFixed: two.\n",
])
func notesOutOfOrderEmptyOrWithCodeAreRefused(notes: String) throws {
    #expect(try reason(for: notes) == nil)
}
