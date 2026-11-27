import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

private let made = [
    PaletteItem(id: "1", key: "notes.example", title: "Meeting notes", letter: "N"),
    PaletteItem(id: "2", key: "report.example", title: "Quarterly report", letter: "R"),
    PaletteItem(id: "3", key: "Paste as plain text", title: "", symbol: "command", keyLabel: "⇧↩"),
]

/// Search's palette rows, the first picked, on Search's ground. The same rows were built from Search's own code
/// at commit c92ea7c with the same made-up words, by a scratch copy that uses this repository's picture harness,
/// and pictured into `Fixtures/Search Palette Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func thePaletteRowsLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Palette \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let rows = VStack(spacing: 0) {
        ForEach(Array(made.enumerated()), id: \.offset) { index, item in PaletteRow(item: item, picked: index == 0) }
    }
    .padding(6).frame(width: 420, height: 150).background(Role.ground)
    #expect(differingPixels(try picture(of: rows, width: 420, height: 150, dark: dark), search) <= tolerance)
}

/// Each word typed narrows the list; nothing typed shows everything, in its own order.
@Test func typingNarrowsTheList() {
    #expect(Palette.rank(made, for: "").map(\.id) == ["1", "2", "3"])
    #expect(Palette.rank(made, for: "report").map(\.id) == ["2"])
    #expect(Palette.rank(made, for: "plain paste").map(\.id) == ["3"])
}

/// A word with a letter wrong still finds what it meant, but after what was typed exactly, as Search ranks it.
@Test func aTypoIsForgivenButRanksLast() {
    let items = [
        PaletteItem(id: "typo", key: "Quarterly reprot", title: ""),
        PaletteItem(id: "exact", key: "Quarterly report", title: ""),
    ]
    #expect(Palette.rank(items, for: "report").map(\.id) == ["exact", "typo"])
    #expect(Palette.rank(items, for: "xyzzy").isEmpty)
}
