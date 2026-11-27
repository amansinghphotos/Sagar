import Foundation
import Testing

private let root = URL(filePath: #filePath).appending(path: "../../..").standardizedFileURL

/// Asks the real build script which settings a release's notes become: one line each, always all three.
private func settings(for notes: String) throws -> [String] {
    let process = Process()
    let question = Pipe()
    let answer = Pipe()
    process.executableURL = root.appending(path: "Scripts/build")
    process.arguments = ["settings"]
    process.standardInput = question
    process.standardOutput = answer
    process.standardError = Pipe()
    try process.run()
    question.fileHandleForWriting.write(Data(notes.utf8))
    try question.fileHandleForWriting.close()
    process.waitUntilExit()
    #expect(process.terminationStatus == 0)
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        .split(separator: "\n", omittingEmptySubsequences: false).dropLast().map(String.init)
}

@Test func aBuildCarriesEachLineOfItsNotes() throws {
    let notes = "New: find a clip by typing.\nBetter: the list opens faster.\nFixed: pasting no longer stalls.\n"
    #expect(
        try settings(for: notes) == [
            "SAGAR_NEW=Find a clip by typing.", "SAGAR_BETTER=The list opens faster.",
            "SAGAR_FIXED=Pasting no longer stalls.",
        ])
}

@Test func aLineLeftOutStaysLeftOut() throws {
    #expect(
        try settings(for: "Fixed: pasting no longer stalls.\n") == [
            "SAGAR_NEW=", "SAGAR_BETTER=", "SAGAR_FIXED=Pasting no longer stalls.",
        ])
}

@Test func aBuildWithNoNotesCarriesNone() throws {
    #expect(try settings(for: "") == ["SAGAR_NEW=", "SAGAR_BETTER=", "SAGAR_FIXED="])
}

/// Each line reaches the app: its Info.plist names a key for each setting.
@Test func everyAppsInfoNamesEachLine() throws {
    let information = try #require(
        PropertyListSerialization.propertyList(
            from: Data(contentsOf: root.appending(path: "Config/Info.plist")), format: nil) as? [String: Any])
    #expect(information["SagarNew"] as? String == "$(SAGAR_NEW)")
    #expect(information["SagarBetter"] as? String == "$(SAGAR_BETTER)")
    #expect(information["SagarFixed"] as? String == "$(SAGAR_FIXED)")
}
