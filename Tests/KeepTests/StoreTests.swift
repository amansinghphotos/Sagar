import Foundation
import Testing

@testable import Keep

private struct Note: Codable, Equatable {
    var text: String
    var pinned: Bool
}

/// A fresh folder for one test. Each test removes it when it ends.
private func freshFolder() -> URL {
    FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
}

@Test func whatIsWrittenIsReadBack() throws {
    let folder = freshFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = Store(folder: folder)
    try store.write(Note(text: "ਸਾਗਰ", pinned: true), named: "Note")
    #expect(try store.read(Note.self, named: "Note") == Note(text: "ਸਾਗਰ", pinned: true))
}

@Test func nothingWrittenReadsAsNothing() throws {
    let folder = freshFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    #expect(try Store(folder: folder).read(Note.self, named: "Note") == nil)
}

@Test func theFileIsPlainTextAPersonCanRead() throws {
    let folder = freshFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    try Store(folder: folder).write(Note(text: "Hello", pinned: false), named: "Note")
    let file = try String(contentsOf: folder.appending(path: "Note.json"), encoding: .utf8)
    #expect(file == "{\n  \"pinned\" : false,\n  \"text\" : \"Hello\"\n}")
}

@Test func aFileFromANewerVersionWithMoreInItStillReads() throws {
    let folder = freshFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try Data(#"{"text": "Old", "pinned": true, "colour": "new in a later version"}"#.utf8)
        .write(to: folder.appending(path: "Note.json"))
    #expect(try Store(folder: folder).read(Note.self, named: "Note") == Note(text: "Old", pinned: true))
}

@Test func aDamagedFileIsAnErrorNotAnEmptyStart() throws {
    let folder = freshFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: folder.appending(path: "Note.json"))
    #expect(throws: DecodingError.self) { try Store(folder: folder).read(Note.self, named: "Note") }
}

@Test(arguments: ["../Outside", "Inner/Note", "..", ""])
func aNameCannotReachOutsideTheFolder(name: String) {
    let store = Store(folder: freshFolder())
    #expect(throws: StoreError.badName(name)) { try store.write(Note(text: "x", pinned: false), named: name) }
    #expect(throws: StoreError.badName(name)) { try store.read(Note.self, named: name) }
}
