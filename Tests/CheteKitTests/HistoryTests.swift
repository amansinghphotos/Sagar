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

// What a tour opens Chete on.

@Test func aTourOpensCheteOnAnExportedHistoryInAFolderOfItsOwn() async throws {
    let tour = Mac()
    let file = exportFile()
    defer {
        tour.removed()
        try? FileManager.default.removeItem(at: file)
    }
    // A plain file written by hand, as a tour writes it: no app, and no settings chosen.
    let madeUp = """
        {"settings": {}, "clips": [
            {"id": "00000000-0000-4000-8000-000000000001", "copied": 815000300,
             "kinds": [{"text": {"_0": "Dinner at eight on Friday"}}]},
            {"id": "00000000-0000-4000-8000-000000000002", "copied": 815000200,
             "kinds": [{"link": {"_0": "https://example.com/tickets"}}]}
        ]}
        """
    try Data(madeUp.utf8).write(to: file)
    let copies = try Copies.atOpen(
        environment: [Copies.tourHistory: file.path], temporary: tour.folder, keyName: tour.keyName)
    let link = try #require(URL(string: "https://example.com/tickets"))
    #expect(try await copies.all().map(\.kinds) == [[.text("Dinner at eight on Friday")], [.link(link)]])
    #expect(try tour.history().settings == Settings())
    // From there it is Chete as ever: a new copy is kept in that folder, on top.
    try await copies.take([.text("copied on the tour")], fromOtherDevice: false, copied: .now, app: nil)
    #expect(try tour.history().clips.map(\.kinds).first == [.text("copied on the tour")])
    #expect(try tour.history().clips.count == 3)
}
