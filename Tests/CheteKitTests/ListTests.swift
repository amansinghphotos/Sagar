import AppKit
import Foundation
import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

/// A picture as an app copies it: 1200 by 800 pixels, of nothing.
private let picture = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: 1200, pixelsHigh: 800, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!.representation(using: .png, properties: [:])!

/// A made-up history, newest first, as Clips hands it over.
private let history: [Clip] = [
    Clip(kinds: [.text("Meet at the café at 7, by the window")], copied: now - 40, app: "com.apple.Notes"),
    Clip(kinds: [.link(URL(string: "https://example.com/menu")!)], copied: now - 5 * 60, app: "com.apple.Safari"),
    Clip(kinds: [.file(URL(filePath: "/Volumes/Example/Trip Report.pdf"))], copied: now - 50 * 60, app: nil),
    Clip(kinds: [.picture(picture, type: "public.png")], copied: now - 3 * 3600, app: nil),
    Clip(
        kinds: [.text("Lunch menu for Friday\nSoup, bread, and the good cheese")], copied: now - 26 * 3600,
        app: "com.apple.mail"),
    Clip(kinds: [.text("ਸਾਗਰ ਦੀ ਲਹਿਰ")], copied: now - 4 * 86400, app: nil),
]

// What the arrow keys choose.

@Test func theNewestIsChosenAtFirst() {
    #expect(Choice(nil).id(in: history) == history[0].id)
}

@Test func theArrowsMoveOneAtATimeAndStopAtTheEnds() {
    var choice = Choice(nil)
    choice.move(-1, in: history)
    #expect(choice.id(in: history) == history[0].id)
    choice.move(1, in: history)
    choice.move(1, in: history)
    #expect(choice.id(in: history) == history[2].id)
    for _ in 0..<10 { choice.move(1, in: history) }
    #expect(choice.id(in: history) == history[5].id)
}

@Test func whenTypingHidesTheChosenClipTheNewestFoundIsChosen() {
    let choice = Choice(history[2].id)
    let found = history.found(by: "menu")
    #expect(choice.id(in: found) == history[1].id)
    #expect(Choice(history[4].id).id(in: found) == history[4].id)
    #expect(Choice(nil).id(in: []) == nil)
}

// How a clip reads in its row.

@Test func eachClipReadsAsItsFirstLineAndWhatItIs() {
    let rows = history.map { Row($0, now: now) }
    #expect(
        rows.map(\.title) == [
            "Meet at the café at 7, by the window", "https://example.com/menu", "Trip Report.pdf", "1200 × 800",
            "Lunch menu for Friday", "ਸਾਗਰ ਦੀ ਲਹਿਰ",
        ])
    #expect(
        rows.map(\.detail) == [
            "Text · 40 seconds ago", "Link · 5 minutes ago", "File · 50 minutes ago", "Picture · 3 hours ago",
            "Text · yesterday", "Text · 4 days ago",
        ])
}

// What the list keeps up with.

@Test func aNewCopyGoesOnTopAndARepeatMovesThere() {
    let shelf = Shelf(history)
    let again = Clip(id: history[3].id, kinds: history[3].kinds, copied: now, app: nil)
    shelf.add(again)
    #expect(shelf.clips.map(\.id) == [history[3].id] + history.map(\.id).filter { $0 != history[3].id })
}

// The screen, pictured.

@Test(arguments: WindowSize.allCases)
func theListMatchesItsPicture(size: WindowSize) throws {
    try expectPicture(
        of: ClipList(clips: history, now: now) { _, _ in }, width: size.width, height: size.height,
        named: "list-\(size.rawValue.lowercased())")
}

@Test func theListWithAWordTypedMatchesItsPictureInTheDark() throws {
    let size = WindowSize.standard
    try expectPicture(
        of: ClipList(clips: history, now: now, typed: "menu") { _, _ in }.environment(\.colorScheme, .dark),
        width: size.width, height: size.height, named: "list-menu-dark", dark: true)
}

@Test func anEmptyHistorySaysSo() throws {
    let size = WindowSize.narrow
    try expectPicture(
        of: ClipList(clips: [], now: now) { _, _ in }, width: size.width, height: size.height, named: "list-empty")
}
