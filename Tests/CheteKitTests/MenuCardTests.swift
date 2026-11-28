import Foundation
import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

/// A made-up history, newest first: more clips than the card shows.
private let history: [Clip] = [
    Clip(kinds: [.text("Meet at the café at 7, by the window")], copied: now - 40, app: "com.apple.Notes"),
    Clip(kinds: [.link(URL(string: "https://example.com/menu")!)], copied: now - 5 * 60, app: "com.apple.Safari"),
    Clip(kinds: [.file(URL(filePath: "/Volumes/Example/Trip Report.pdf"))], copied: now - 50 * 60, app: nil),
    Clip(kinds: [.text("Lunch menu for Friday\nSoup, bread, and the good cheese")], copied: now - 26 * 3600, app: nil),
    Clip(kinds: [.text("ਸਾਗਰ ਦੀ ਲਹਿਰ")], copied: now - 4 * 86400, app: nil),
    Clip(kinds: [.text("An older note the card leaves out")], copied: now - 9 * 86400, app: nil),
]

private let nothing = MenuCardActs(copy: { _ in }, open: {}, settings: {}, checkForUpdates: {}, quit: {})

@Test(arguments: [false, true])
func theMenuCardShowsTheFiveNewestAsApproved(dark: Bool) throws {
    try expectPicture(
        of: MenuCard(clips: history, now: now, lit: history[1].id, act: nothing)
            .environment(\.colorScheme, dark ? .dark : .light),
        width: MenuCard.width, height: 330, named: "menu-card-\(dark ? "dark" : "light")", dark: dark)
}

@Test func anEmptyMenuCardSaysHowToFillIt() throws {
    try expectPicture(
        of: MenuCard(clips: [], now: now, act: nothing), width: MenuCard.width, height: 174, named: "menu-card-empty")
}

/// Until macOS lets Chete keep what is copied, the card says it keeps nothing yet, with a way back to that step.
@Test func theCardSaysWhenNothingIsKeptYet() throws {
    try expectPicture(
        of: MenuCard(clips: [], now: now, keeping: false, act: nothing), width: MenuCard.width, height: 174,
        named: "menu-card-not-allowed")
}
