import CryptoKit
import Foundation
import Keep
import Testing

@testable import CheteKit

/// A history in the earlier Chete's format, as `EarlierChete` describes it, made up here and sealed by a key made
/// for the test; and a new Chete's folder, with a key of its own. Each clip is written from plain dictionaries, not
/// from the import's own types, so a wrong name in the import fails here. Each test removes all of it when it ends.
private struct Macs {
    let earlier = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let key = SymmetricKey(size: .bits256)
    let new = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"

    var earlierClips: URL { earlier.appending(path: "Clips") }

    /// One earlier clip: its record, and the bytes of each form it was copied in, when it has any.
    @discardableResult
    func keep(_ record: [String: Any], bytes: [(type: String, data: Data)]? = nil) throws -> UUID {
        let id = UUID()
        let defaults: [String: Any] = ["id": id.uuidString, "digest": "made up", "text": "", "files": [String]()]
        try write(defaults.merging(record) { $1 }, id: id, as: "clip")
        if let bytes { try write(bytes.map { ["type": $0.type, "data": $0.data] }, id: id, as: "data") }
        return id
    }

    /// An earlier clip of words, copied as plain text.
    @discardableResult
    func keep(words: String, copied: Date) throws -> UUID {
        try keep(
            ["kind": "text", "text": words, "copied": copied], bytes: [("public.utf8-plain-text", Data(words.utf8))])
    }

    func write(_ value: Any, id: UUID, as kind: String) throws {
        try FileManager.default.createDirectory(at: earlierClips, withIntermediateDirectories: true)
        let plain = try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0)
        let sealed = try AES.GCM.seal(plain, using: key, authenticating: Data(id.uuidString.utf8))
        try sealed.combined!.write(to: earlierClips.appending(path: "\(id.uuidString).\(kind)"))
    }

    func earlierSettings(_ json: String) throws {
        let yours = earlier.appending(path: "Yours")
        try FileManager.default.createDirectory(at: yours, withIntermediateDirectories: true)
        try Data(json.utf8).write(to: yours.appending(path: "Settings.json"))
    }

    /// Every earlier file and its bytes, to show nothing was changed.
    func earlierFiles() throws -> [String: Data] {
        var found: [String: Data] = [:]
        let all = try #require(FileManager.default.enumerator(at: earlier, includingPropertiesForKeys: nil))
        for case let file as URL in all where !file.hasDirectoryPath { found[file.path] = try Data(contentsOf: file) }
        return found
    }

    @discardableResult
    func bringIn(from folder: URL? = nil, key: SymmetricKey? = nil) throws -> Takeover {
        try EarlierChete(folder: folder ?? earlier, key: key ?? self.key).bringIn(to: new, keyName: keyName)
    }

    func clips() throws -> Clips { try Clips(cheteFolder: new, keyName: keyName) }
    func settings() throws -> Settings { try Settings.read(in: new) }

    func removed() {
        try? FileManager.default.removeItem(at: earlier)
        try? FileManager.default.removeItem(at: new)
        try? Seal.forget(named: keyName)
    }
}

private let copied = Date(timeIntervalSinceReferenceDate: 815_000_000.25)
private let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
private let tiff = Data([0x4D, 0x4D, 0x00, 0x2A])
private let rtf = Data(#"{\rtf1\ansi {\b Bold} words}"#.utf8)
private let sky = URL(filePath: "/Library/Desktop Pictures/Sky.heic")
private let sea = URL(filePath: "/Library/Desktop Pictures/Sea.heic")

@Test func everyClipAndBothSettingsComeInAndTheEarlierFilesAreUnchanged() throws {
    let macs = Macs()
    defer { macs.removed() }
    let words = try macs.keep(words: "Meet at the ਸਾਗਰ café at 7", copied: copied)
    let formatted = try macs.keep(
        ["kind": "text", "text": "Bold words", "appID": "com.apple.TextEdit", "copied": copied + 1],
        bytes: [("public.utf8-plain-text", Data("Bold words".utf8)), ("public.rtf", rtf), ("public.html", Data())])
    let code = try macs.keep(
        ["kind": "code", "text": "swift test", "app": "Terminal", "appID": "com.apple.Terminal", "copied": copied + 2])
    let address = Data("https://example.com/a?b=c".utf8)
    let link = try macs.keep(
        ["kind": "link", "text": "https://example.com/a?b=c", "appID": "com.apple.Safari", "copied": copied + 3],
        bytes: [("public.utf8-plain-text", address), ("public.url", address)])
    let picture = try macs.keep(
        ["kind": "image", "copied": copied + 4, "pixels": ["width": 2, "height": 1], "photo": true],
        bytes: [("public.png", png)])
    try macs.write([png], id: picture, as: "look")
    let files = try macs.keep(
        ["kind": "file", "text": "Sky.heic\nSea.heic", "files": [sky.path, sea.path], "copied": copied + 5])
    // A record kept by the first version holds its picture's preview inside it.
    let first = try macs.keep(
        ["kind": "image", "copied": copied + 6, "thumbnail": png], bytes: [("public.tiff", tiff)])
    try macs.earlierSettings(#"{"copiesFromOtherDevices": false, "ignoredApps": ["a.b"], "keepFor": "30 Days"}"#)
    try Data(#"{"event": "launched"}"#.utf8).write(to: macs.earlier.appending(path: "Events.jsonl"))
    let before = try macs.earlierFiles()

    #expect(try macs.bringIn() == Takeover(broughtIn: 7, leftOut: 0))
    #expect(
        try macs.clips().all() == [
            Clip(id: first, kinds: [.picture(tiff, type: "public.tiff")], copied: copied + 6, app: nil),
            Clip(id: files, kinds: [.file(sky), .file(sea)], copied: copied + 5, app: nil),
            Clip(id: picture, kinds: [.picture(png, type: "public.png")], copied: copied + 4, app: nil),
            Clip(
                id: link, kinds: [.link(URL(string: "https://example.com/a?b=c")!)], copied: copied + 3,
                app: "com.apple.Safari"),
            Clip(id: code, kinds: [.text("swift test")], copied: copied + 2, app: "com.apple.Terminal"),
            Clip(
                id: formatted, kinds: [.text("Bold words"), .richText(rtf)], copied: copied + 1,
                app: "com.apple.TextEdit"),
            Clip(id: words, kinds: [.text("Meet at the ਸਾਗਰ café at 7")], copied: copied, app: nil),
        ])
    #expect(try macs.settings() == Settings(keepsCopiesFromOtherDevices: false, keeping: .month))
    #expect(try macs.earlierFiles() == before)
}

/// This Chete has no three months: the next longer keeps every clip the earlier one would have kept. Settings
/// never changed, taken back or damaged come in as the first ones, as the earlier Chete itself read them.
@Test(arguments: [
    (#"{"keepFor": "7 Days"}"#, Settings(keeping: .week)), (#"{"keepFor": "30 Days"}"#, Settings(keeping: .month)),
    (#"{"keepFor": "3 Months"}"#, Settings(keeping: .year)), (#"{"keepFor": "1 Year"}"#, Settings(keeping: .year)),
    (#"{"keepFor": "Forever"}"#, Settings(keeping: .forever)), ("{}", Settings()), ("null", Settings()),
    ("{", Settings()),
])
func theSettingsComeIn(earlier json: String, now settings: Settings) throws {
    let macs = Macs()
    defer { macs.removed() }
    try macs.earlierSettings(json)
    try Settings(keepsCopiesFromOtherDevices: false, keeping: .week).write(in: macs.new)
    try macs.bringIn()
    #expect(try macs.settings() == settings)
}

/// He may choose the earlier Chete's folder, or the Clips folder inside it. A clip of formatting this Chete does
/// not keep, with no words, opened with the right key: it is left out, and the settings still come in.
@Test(arguments: [false, true])
func aHistoryWithNoClipToKeepBringsInOnlyItsSettings(holdsFormatting: Bool) throws {
    let macs = Macs()
    defer { macs.removed() }
    try FileManager.default.createDirectory(at: macs.earlierClips, withIntermediateDirectories: true)
    if holdsFormatting { try macs.keep(["kind": "text", "copied": copied], bytes: [("public.html", Data())]) }
    try macs.earlierSettings(#"{"keepFor": "7 Days"}"#)
    #expect(try macs.bringIn(from: macs.earlierClips) == Takeover(broughtIn: 0, leftOut: holdsFormatting ? 1 : 0))
    #expect(try macs.clips().all().isEmpty)
    #expect(try macs.settings().keeping == .week)
}

@Test func aFolderWithNoHistoryInItChangesNothing() throws {
    let macs = Macs()
    defer { macs.removed() }
    try FileManager.default.createDirectory(at: macs.earlier, withIntermediateDirectories: true)
    try Data("a letter".utf8).write(to: macs.earlier.appending(path: "Letter.txt"))
    #expect(throws: TakeoverError.noHistory) { try macs.bringIn() }
    #expect(!FileManager.default.fileExists(atPath: macs.new.path))
}

@Test func aClipThatCannotComeInWholeIsLeftOutAndTheRestComeIn() throws {
    let macs = Macs()
    defer { macs.removed() }
    // A clip with no bytes comes in from its record, as a link copied as words.
    let kept = try macs.keep(["kind": "link", "text": " https://example.com\n", "copied": copied])
    let torn = macs.earlierClips.appending(path: "\(try macs.keep(words: "torn", copied: copied).uuidString).clip")
    var bytes = try Data(contentsOf: torn)
    bytes[bytes.count / 2] ^= 0xFF
    try bytes.write(to: torn)
    // A picture whose bytes are damaged would come in empty.
    let picture = try macs.keep(["kind": "image", "copied": copied], bytes: [("public.png", png)])
    try Data("damaged".utf8).write(to: macs.earlierClips.appending(path: "\(picture.uuidString).data"))
    // A record under another clip's name does not open as that clip.
    try FileManager.default.copyItem(
        at: macs.earlierClips.appending(path: "\(kept.uuidString).clip"),
        to: macs.earlierClips.appending(path: "\(UUID().uuidString).clip"))
    try Data("not a clip".utf8).write(to: macs.earlierClips.appending(path: "Notes.clip"))
    // Formatting this Chete does not keep, with no words, leaves nothing to bring in.
    try macs.keep(["kind": "text", "copied": copied], bytes: [("public.html", Data("<table>".utf8))])

    #expect(try macs.bringIn() == Takeover(broughtIn: 1, leftOut: 5))
    #expect(
        try macs.clips().all() == [
            Clip(id: kept, kinds: [.link(URL(string: "https://example.com")!)], copied: copied, app: nil)
        ])
}

@Test func theWrongKeyChangesNothing() throws {
    let macs = Macs()
    defer { macs.removed() }
    try macs.keep(words: "secret", copied: copied)
    try macs.earlierSettings(#"{"keepFor": "Forever"}"#)
    let mine = Clip(kinds: [.text("already here")], copied: copied, app: nil)
    try macs.clips().keep(mine)
    try Settings(keeping: .week).write(in: macs.new)

    #expect(throws: TakeoverError.wrongKey) { try macs.bringIn(key: SymmetricKey(size: .bits256)) }
    #expect(try macs.clips().all() == [mine])
    #expect(try macs.settings() == Settings(keeping: .week))
}

@Test func whatIsAlreadyThereStaysAndBringingInTwiceAddsNothing() throws {
    let macs = Macs()
    defer { macs.removed() }
    let old = try macs.keep(words: "old", copied: copied)
    let mine = Clip(kinds: [.text("mine")], copied: copied + 60, app: nil)
    try macs.clips().keep(mine)
    #expect(try macs.bringIn() == Takeover(broughtIn: 1, leftOut: 0))
    #expect(try macs.bringIn() == Takeover(broughtIn: 0, leftOut: 0))
    #expect(try macs.clips().all().map(\.id) == [mine.id, old])
}

@Test func aFailureBeforeTheEndTakesBackEveryClipItBroughtIn() throws {
    let macs = Macs()
    defer { macs.removed() }
    for words in ["one", "two", "three"] { try macs.keep(words: words, copied: copied) }
    try macs.earlierSettings(#"{"keepFor": "Forever"}"#)
    let mine = Clip(kinds: [.text("mine")], copied: copied, app: nil)
    try macs.clips().keep(mine)
    // The settings, written last, cannot be written where a folder stands in the file's place.
    try FileManager.default.createDirectory(
        at: macs.new.appending(path: "Settings.json"), withIntermediateDirectories: true)

    #expect(throws: (any Error).self) { try macs.bringIn() }
    #expect(try macs.clips().all() == [mine])
}
