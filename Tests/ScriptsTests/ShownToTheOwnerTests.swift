import Foundation
import Testing

/// A spec with three must-haves, in a temporary folder.
private func spec() throws -> URL {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appending(path: "specimen.md")
    try """
    # Specimen

    ## What It Is For

    1. Not a must-have: it is in another part.

    ## Must-Haves

    1. **It opens.** Quickly.
    2. **It keeps things,** for as long as you choose.
       *Asks for:* nothing.
    3. **It updates itself.**

    ## Out of Scope

    - Everything else.
    """.write(to: file, atomically: true, encoding: .utf8)
    return file
}

/// A picture of a screen, in a temporary folder: what it shows does not matter here, only that it changed.
private func picture() throws -> URL {
    let file = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: file)
    return file
}

/// Asks the real rules script whether a description shows the owner, in his part, every must-have of the spec
/// and every picture that the pull request changes.
private func showsTheOwner(_ description: String, _ files: [URL]) throws -> Bool {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    let process = Process()
    let question = Pipe()
    let answer = Pipe()
    process.executableURL = script
    process.arguments = ["shown"] + files.map(\.path)
    process.standardInput = question
    process.standardOutput = answer
    try process.run()
    question.fileHandleForWriting.write(Data(description.utf8))
    try question.fileHandleForWriting.close()
    process.waitUntilExit()
    return String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n"
}

private nonisolated func description(owner list: String, agents: String = "") -> String {
    """
    ## For the Owner

    **What This Does:** Says what the specimen must do.

    **Why:** Nothing is built until you approve it.

    **Does It Change Your Apps?** No.

    **What to Do:** Read the list below, then approve.

    \(list)

    <details><summary>Checklist for the Agents</summary>

    Closes #3

    \(agents)

    </details>
    """
}

private nonisolated let three = "1. **It opens.**\n2. **It keeps things.**\n3. **It updates itself.**"

private nonisolated let shown =
    "### The Window\n\n![The window](https://raw.githubusercontent.com/someone/Sagar/1-a/Tests/AKitTests/Pictures/a.png)"

@Test func everyMustHaveListedForTheOwnerPasses() throws {
    #expect(try showsTheOwner(description(owner: "### What It Must Do\n\n" + three), [spec()]))
}

@Test(arguments: [
    description(owner: ""),
    description(owner: "1. **It opens.**\n2. **It keeps things.**"),
    description(owner: "", agents: three),
])
func aSpecWhoseMustHavesTheOwnerCannotSeeFails(description: String) throws {
    #expect(try !showsTheOwner(description, [spec()]))
}

@Test func aChangedPictureShownInTheOwnersPartPasses() throws {
    #expect(try showsTheOwner(description(owner: shown), [picture()]))
}

@Test func aChangedPictureShownOnlyToTheAgentsFails() throws {
    #expect(try !showsTheOwner(description(owner: "", agents: shown), [picture()]))
}

/// Where a picture is kept is not a word he reads, so showing it does not break the plain-words rule.
@Test func aPictureInTheOwnersPartIsStillPlainWords() throws {
    let process = Process()
    let question = Pipe()
    let answer = Pipe()
    process.executableURL = URL(filePath: #filePath).appending(path: "../../../Scripts/check").standardizedFileURL
    process.arguments = ["plain"]
    process.standardInput = question
    process.standardOutput = answer
    try process.run()
    question.fileHandleForWriting.write(Data(description(owner: shown).utf8))
    try question.fileHandleForWriting.close()
    process.waitUntilExit()
    #expect(String(decoding: answer.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == "yes\n")
}
