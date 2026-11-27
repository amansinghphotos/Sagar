import Foundation
import Keep
import Testing

@testable import CheteKit

/// A Chete folder of its own, with a key made for it, as on one Mac. Each test removes both when it ends.
private struct Mac {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"

    func clips() throws -> Clips {
        try Clips(cheteFolder: folder, keyName: keyName)
    }

    func history() throws -> History {
        try History.read(in: folder, keyName: keyName)
    }

    func removed() {
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
}

private let copied = Date(timeIntervalSinceReferenceDate: 815_000_000.25)

/// One clip of every kind, and both settings changed from their first values.
private func filled(_ mac: Mac) throws {
    let clips = try mac.clips()
    try clips.keep(Clip(kinds: [.text("Meet at the ਸਾਗਰ café at 7")], copied: copied, app: "com.apple.Notes"))
    try clips.keep(
        Clip(
            kinds: [.link(URL(string: "https://example.com/a?b=c")!), .text("https://example.com/a?b=c")],
            copied: copied + 60, app: "com.apple.Safari"))
    try clips.keep(
        Clip(kinds: [.picture(Data([0x89, 0x50, 0x4E, 0x47]), type: "public.png")], copied: copied + 120, app: nil))
    try clips.keep(
        Clip(
            kinds: [.file(URL(filePath: "/Library/Desktop Pictures/Sky.heic"))], copied: copied + 180,
            app: "com.apple.finder"))
    try Settings(keepsCopiesFromOtherDevices: false, keeping: .month).write(in: mac.folder)
}

private func exportFile() -> URL {
    FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
}

@Test func aHistoryBroughtBackOnANewMacIsTheSame() throws {
    let old = Mac()
    let new = Mac()
    let file = exportFile()
    defer {
        old.removed()
        new.removed()
        try? FileManager.default.removeItem(at: file)
    }
    try filled(old)
    try old.history().export(to: file)
    try History.bringBack(from: file).replace(in: new.folder, keyName: new.keyName)
    #expect(try new.history() == old.history())
    #expect(try new.history().clips.count == 4)
    #expect(try new.history().settings == Settings(keepsCopiesFromOtherDevices: false, keeping: .month))
}

@Test func bringingBackReplacesWhatIsThere() throws {
    let old = Mac()
    let new = Mac()
    let file = exportFile()
    defer {
        old.removed()
        new.removed()
        try? FileManager.default.removeItem(at: file)
    }
    try filled(old)
    try new.clips().keep(Clip(kinds: [.text("already here")], copied: copied, app: nil))
    try old.history().export(to: file)
    try History.bringBack(from: file).replace(in: new.folder, keyName: new.keyName)
    #expect(try new.history() == old.history())
}

@Test func theExportIsAPlainFileThatNeedsNoKey() throws {
    let old = Mac()
    let file = exportFile()
    defer {
        old.removed()
        try? FileManager.default.removeItem(at: file)
    }
    try filled(old)
    try old.history().export(to: file)
    let text = try String(contentsOf: file, encoding: .utf8)
    #expect(text.contains("Meet at the ਸਾਗਰ café at 7"))
    #expect(text.contains("com.apple.Safari"))
}

@Test func aDamagedFileChangesNothing() throws {
    let new = Mac()
    let file = exportFile()
    defer {
        new.removed()
        try? FileManager.default.removeItem(at: file)
    }
    try new.clips().keep(Clip(kinds: [.text("already here")], copied: copied, app: nil))
    let before = try new.history()
    try Data("not a history".utf8).write(to: file)
    #expect(throws: DecodingError.self) { try History.bringBack(from: file) }
    #expect(try new.history() == before)
}
