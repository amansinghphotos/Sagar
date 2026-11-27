import Foundation
import Keep
import Testing

@testable import CheteKit

/// Clips kept in a fresh folder, sealed by a key under a name the real Chete never uses.
/// Each test removes both when it ends.
struct Kept {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"

    func clips() throws -> Clips {
        try Clips(folder: folder, keyName: keyName)
    }

    func removed() {
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
}

private let copied = Date(timeIntervalSinceReferenceDate: 815_000_000)

@Test func theTestKeyIsNotChetesOwn() {
    #expect(Kept().keyName != Clips.keyName)
}

@Test func aClipIsReadBackWhole() throws {
    let kept = Kept()
    defer { kept.removed() }
    let clip = Clip(kinds: [.text("Meet at the ਸਾਗਰ café at 7")], copied: copied, app: "com.apple.Notes")
    try kept.clips().keep(clip)
    #expect(try kept.clips().all() == [clip])
}

@Test func theFilesHoldNoPlainText() throws {
    let kept = Kept()
    defer { kept.removed() }
    try kept.clips().keep(Clip(kinds: [.text("my bank PIN is 4071")], copied: copied, app: "com.apple.Notes"))
    let files = try FileManager.default.contentsOfDirectory(at: kept.folder, includingPropertiesForKeys: nil)
    #expect(files.count == 1)
    for file in files {
        let bytes = try Data(contentsOf: file)
        for plain in ["my bank PIN is 4071", "com.apple.Notes"] {
            #expect(bytes.firstRange(of: Data(plain.utf8)) == nil)
            #expect(bytes.firstRange(of: Data(plain.utf8).base64EncodedData()) == nil)
        }
    }
}

@Test func clipsComeBackNewestFirst() throws {
    let kept = Kept()
    defer { kept.removed() }
    let clips = try kept.clips()
    let older = Clip(kinds: [.text("first")], copied: copied, app: nil)
    let newer = Clip(kinds: [.text("second")], copied: copied.addingTimeInterval(60), app: "com.apple.Safari")
    try clips.keep(older)
    try clips.keep(newer)
    #expect(try clips.all() == [newer, older])
}

@Test func nothingKeptIsAnEmptyHistory() throws {
    let kept = Kept()
    defer { kept.removed() }
    #expect(try kept.clips().all() == [])
}
