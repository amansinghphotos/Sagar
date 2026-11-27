import AppKit
import Foundation
import Keep
import Testing

@testable import CheteKit

/// A pasteboard of the test's own, never the one you copy to, read back as the app you paste into reads it.
@MainActor
private struct Board {
    let pasteboard = NSPasteboard(name: .init("Sagar Tests · \(UUID().uuidString)"))

    func put(_ kinds: [Clip.Kind], plainText: Bool = false) {
        Pasting.put(Clip(kinds: kinds, copied: .now, app: nil), plainText: plainText, on: pasteboard)
    }

    /// Whether an app finds words alone: no formatting, link, file or picture.
    var holdsOnlyWords: Bool {
        pasteboard.string(forType: .string) != nil
            && pasteboard.availableType(from: [.rtf, .URL, .fileURL, .png, .tiff]) == nil
    }

    var files: [URL] {
        pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }
}

private let link = URL(string: "https://example.com/menu")!
private let rtf = Data(#"{\rtf1\ansi {\b Lunch} at noon}"#.utf8)
private let report = URL(filePath: "/Volumes/Work/Report.pdf")
private let photo = URL(filePath: "/Volumes/Work/Photo.jpg")

@Test func textIsPutBackAsText() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    board.put([.text("Meet at the ਸਾਗਰ café at 7")])
    #expect(board.pasteboard.string(forType: .string) == "Meet at the ਸਾਗਰ café at 7")
}

@Test func formattedTextKeepsItsFormattingUnlessPlain() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    board.put([.text("Lunch at noon"), .richText(rtf)])
    #expect(board.pasteboard.data(forType: .rtf) == rtf)
    #expect(board.pasteboard.string(forType: .string) == "Lunch at noon")
    board.put([.text("Lunch at noon"), .richText(rtf)], plainText: true)
    #expect(board.holdsOnlyWords)
    #expect(board.pasteboard.string(forType: .string) == "Lunch at noon")
}

@Test func aLinkIsPutBackAsALinkOrPlainWords() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    board.put([.link(link)])
    #expect(board.pasteboard.string(forType: .URL) == link.absoluteString)
    #expect(board.pasteboard.string(forType: .string) == link.absoluteString)
    board.put([.link(link)], plainText: true)
    #expect(board.holdsOnlyWords)
    #expect(board.pasteboard.string(forType: .string) == link.absoluteString)
}

@Test func aPictureIsPutBackAsTheSamePicture() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    let png = Data([0x89, 0x50, 0x4E, 0x47])
    board.put([.picture(png, type: "public.png")])
    #expect(board.pasteboard.data(forType: .png) == png)
    // A picture has no words, so as plain text it is still the picture.
    board.put([.picture(png, type: "public.png")], plainText: true)
    #expect(board.pasteboard.data(forType: .png) == png)
}

@Test func filesArePutBackAsFinderPutThemOrAsTheirPlaces() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    board.put([.file(report), .file(photo)])
    #expect(board.files == [report, photo])
    board.put([.file(report), .file(photo)], plainText: true)
    #expect(board.holdsOnlyWords)
    #expect(board.pasteboard.string(forType: .string) == "/Volumes/Work/Report.pdf\n/Volumes/Work/Photo.jpg")
}

@Test func withoutLeaveToPasteItCopiesAndSaysSo() {
    let board = Board()
    defer { board.pasteboard.releaseGlobally() }
    let clip = Clip(kinds: [.text("correct-horse-battery")], copied: .now, app: nil)
    #expect(Pasting.paste(clip, plainText: false, on: board.pasteboard, mayPaste: false) == .copied)
    #expect(board.pasteboard.string(forType: .string) == "correct-horse-battery")
}

/// Formatted text you copy is kept with its formatting, so that it can be pasted the same way.
@Test func formattedTextIsKeptWithItsFormatting() async throws {
    let board = Board()
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"
    defer {
        board.pasteboard.releaseGlobally()
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
    let watcher = Watcher(pasteboard: board.pasteboard, copies: try Copies(folder: folder, keyName: keyName))
    board.pasteboard.clearContents()
    board.pasteboard.setString("Lunch at noon", forType: .string)
    board.pasteboard.setData(rtf, forType: .rtf)
    await watcher.look()
    let clips = try Clips(folder: folder.appending(path: "Clips"), keyName: keyName).all()
    #expect(clips.map(\.kinds) == [[.text("Lunch at noon"), .richText(rtf)]])
}

/// What Chete puts back to paste is already a clip, so it is not taken in again as a new copy.
@Test func whatChetePutsBackIsNotANewCopy() async throws {
    let board = Board()
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"
    defer {
        board.pasteboard.releaseGlobally()
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
    let watcher = Watcher(pasteboard: board.pasteboard, copies: try Copies(folder: folder, keyName: keyName))
    board.put([.link(link)], plainText: true)
    await watcher.look()
    #expect(try Clips(folder: folder.appending(path: "Clips"), keyName: keyName).all() == [])
}
