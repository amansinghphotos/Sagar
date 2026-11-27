import Foundation
import Testing

@testable import Keep

/// A key of its own for one test, kept in the login keychain under a name no app uses.
/// Each test forgets it when it ends.
private func testKeyName() -> String {
    "Sagar Tests · \(UUID().uuidString)"
}

@Test func whatIsSealedOpensWithTheSameKey() throws {
    let name = testKeyName()
    defer { try? Seal.forget(named: name) }
    let seal = try Seal(named: name)
    let sealed = try seal.seal(Data("ਸਾਗਰ".utf8))
    #expect(try seal.open(sealed) == Data("ਸਾਗਰ".utf8))
}

@Test func theKeyIsKeptSoItStillOpensLater() throws {
    let name = testKeyName()
    defer { try? Seal.forget(named: name) }
    let sealed = try Seal(named: name).seal(Data("kept".utf8))
    #expect(try Seal(named: name).open(sealed) == Data("kept".utf8))
}

@Test func anotherKeyCannotOpenIt() throws {
    let name = testKeyName()
    let other = testKeyName()
    defer {
        try? Seal.forget(named: name)
        try? Seal.forget(named: other)
    }
    let sealed = try Seal(named: name).seal(Data("private".utf8))
    #expect(throws: (any Error).self) { try Seal(named: other).open(sealed) }
}

@Test func aForgottenKeyIsGoneFromTheKeychain() throws {
    let name = testKeyName()
    defer { try? Seal.forget(named: name) }
    let sealed = try Seal(named: name).seal(Data("gone".utf8))
    try Seal.forget(named: name)
    #expect(throws: (any Error).self) { try Seal(named: name).open(sealed) }
}

@Test func aSealedValueIsWrittenAndReadBackWithNoPlainTextInTheFile() throws {
    let name = testKeyName()
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer {
        try? Seal.forget(named: name)
        try? FileManager.default.removeItem(at: folder)
    }
    let store = Store(folder: folder)
    let seal = try Seal(named: name)
    try store.write(["secret words"], named: "Note", sealedBy: seal)
    let file = try Data(contentsOf: folder.appending(path: "Note.sealed"))
    #expect(file.firstRange(of: Data("secret words".utf8)) == nil)
    #expect(try store.read([String].self, named: "Note", sealedBy: seal) == ["secret words"])
    #expect(try store.sealedNames() == ["Note"])
}

@Test func nothingSealedReadsAsNothing() throws {
    let name = testKeyName()
    defer { try? Seal.forget(named: name) }
    let store = Store(folder: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    #expect(try store.read([String].self, named: "Note", sealedBy: Seal(named: name)) == nil)
    #expect(try store.sealedNames() == [])
}
