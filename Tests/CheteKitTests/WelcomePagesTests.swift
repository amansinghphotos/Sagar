import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

/// What the switches and buttons do in a picture: nothing. Nothing here asks macOS for anything, opens
/// System Settings or a panel, or adds a login item.
private let nothing = WelcomeActs(
    allowKeeping: {}, allowPasting: {}, bringInOldClips: { nil }, openAtLogin: { _ in }, bringBack: { nil })

/// The welcome opened at a page. The page for old clips is there only on a Mac that has some.
private func pages(at page: WelcomePage, _ given: WelcomeGiven = WelcomeGiven()) -> some View {
    var given = given
    if page == .oldClips { given.hasOldClips = true }
    return WelcomePages(startPage: page, given: .constant(given), act: nothing, finish: {})
}

@Test(arguments: WelcomePage.allCases, [false, true])
func eachPageLooksAsApproved(page: WelcomePage, dark: Bool) throws {
    try expectPicture(
        of: pages(at: page), width: WelcomeSize.window.width, height: WelcomeSize.window.height,
        named: "welcome-\(page.rawValue)-\(dark ? "dark" : "light")", dark: dark)
}

@Test func aPermissionGivenIsSaidInsteadOfAsked() throws {
    try expectPicture(
        of: pages(at: .pasting, WelcomeGiven(keeping: true, pasting: true)),
        width: WelcomeSize.window.width, height: WelcomeSize.window.height, named: "welcome-pasting-given")
}

@Test func aPresetMacOSAlreadyUsesIsShownAsTaken() throws {
    var given = WelcomeGiven()
    given.taken = [WelcomeGiven.suggestions[0]]
    given.choose(WelcomeGiven.suggestions[1])
    try expectPicture(
        of: pages(at: .shortcut, given), width: WelcomeSize.window.width, height: WelcomeSize.window.height,
        named: "welcome-shortcut-taken")
}

@Test func aTakenPresetCannotBeChosen() {
    var given = WelcomeGiven()
    given.taken = [WelcomeGiven.suggestions[1]]
    given.choose(WelcomeGiven.suggestions[1])
    #expect(given.shortcut == WelcomeGiven.suggestions[0])
    given.choose(WelcomeGiven.suggestions[2])
    #expect(given.shortcut == WelcomeGiven.suggestions[2])
}

@Test(arguments: ["keeping", "pasting"], [false, true])
func eachCardLooksAsApproved(name: String, dark: Bool) throws {
    try expectPicture(
        of: name == "keeping" ? WelcomeCard.keeping : .pasting, width: WelcomeSize.card.width,
        height: WelcomeSize.card.height, named: "welcome-card-\(name)-\(dark ? "dark" : "light")", dark: dark)
}

@Test func thePageForOldClipsIsShownOnlyWhereThereAreSome() {
    #expect(WelcomePages.pages(for: WelcomeGiven()) == [.greeting, .shortcut, .keeping, .pasting, .last])
    var given = WelcomeGiven()
    given.hasOldClips = true
    #expect(WelcomePages.pages(for: given) == [.greeting, .shortcut, .keeping, .pasting, .oldClips, .last])
}

@Test func oldClipsBroughtInAreSaidInsteadOfAsked() throws {
    var given = WelcomeGiven()
    given.broughtIn = "312 clips are here."
    try expectPicture(
        of: pages(at: .oldClips, given), width: WelcomeSize.window.width, height: WelcomeSize.window.height,
        named: "welcome-oldClips-given")
}

/// The page for keeping what you copy is there only where macOS asks about it: on macOS 27, which lets Chete read
/// what is copied, the welcome is one page shorter.
@Test func thePageForKeepingIsShownOnlyWhereMacOSAsks() throws {
    var given = WelcomeGiven()
    given.asksKeeping = false
    #expect(WelcomePages.pages(for: given) == [.greeting, .shortcut, .pasting, .last])
    try expectPicture(
        of: pages(at: .greeting, given), width: WelcomeSize.window.width, height: WelcomeSize.window.height,
        named: "welcome-greeting-one-permission")
}

/// The welcome starts on the shortcut kept, unless macOS uses it; then on the first preset free, and a preset macOS
/// uses is marked taken.
@Test func theWelcomeStartsOnTheShortcutKeptOrTheFirstFree() {
    let (first, second, third) = (WelcomeGiven.suggestions[0], WelcomeGiven.suggestions[1], WelcomeGiven.suggestions[2])
    var given = WelcomeGiven()
    given.start(kept: third, taken: [])
    #expect(given.shortcut == third && given.taken.isEmpty)
    given.start(kept: third, taken: [third, first])
    #expect(given.shortcut == second && given.taken == [third, first])
    given.start(kept: nil, taken: [first])
    #expect(given.shortcut == second)
}
