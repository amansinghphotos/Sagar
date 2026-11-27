import Foundation
import Testing

@testable import CheteKit

private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

/// A made-up history, newest first, as Clips hands it over.
private let history: [Clip] = [
    Clip(kinds: [.text("Meet at the Café Sagar at 7")], copied: now, app: "com.apple.Notes"),
    Clip(kinds: [.link(URL(string: "https://example.com/menu")!)], copied: now - 60, app: "com.apple.Safari"),
    Clip(kinds: [.file(URL(filePath: "/Volumes/Desktop Backup/Trip Report.pdf"))], copied: now - 120, app: nil),
    Clip(kinds: [.picture(Data([1, 2, 3]), type: "public.png")], copied: now - 180, app: nil),
    Clip(kinds: [.text("Lunch menu for Friday")], copied: now - 240, app: "com.apple.Mail"),
    Clip(kinds: [.text("ਸਾਗਰ ਦੀ ਲਹਿਰ")], copied: now - 300, app: nil),
]

private func found(_ typed: String) -> [Int] {
    history.found(by: typed).map { clip in history.firstIndex(of: clip)! }
}

@Test func nothingTypedShowsEverythingNewestFirst() {
    #expect(found("") == [0, 1, 2, 3, 4, 5])
    #expect(found("   ") == [0, 1, 2, 3, 4, 5])
}

@Test func eachLetterNarrowsTheList() {
    #expect(found("e") == [0, 1, 2, 4])
    #expect(found("me") == [0, 1, 4])
    #expect(found("men") == [1, 4])
    #expect(found("menu f") == [4])
    #expect(found("menuz") == [])
}

@Test func capitalsAndAccentsDoNotMatter() {
    #expect(found("CAFE") == [0])
    #expect(found("café") == [0])
}

@Test func everyWordMustBeFoundInAnyOrder() {
    #expect(found("friday lunch") == [4])
    #expect(found("menu sagar") == [])
}

@Test func aLinkIsFoundByWhereItGoesAndAFileByItsName() {
    #expect(found("example.com") == [1])
    #expect(found("trip report") == [2])
    #expect(found("desktop") == [])
}

@Test func otherScriptsAreFoundToo() {
    #expect(found("ਸਾਗਰ") == [5])
}
