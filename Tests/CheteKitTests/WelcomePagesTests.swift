import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

/// What the switches and buttons do in a picture: nothing. Nothing here asks macOS for anything, opens
/// System Settings or a panel, or adds a login item.
private let nothing = WelcomeActs(allowKeeping: {}, allowPasting: {}, openAtLogin: { _ in }, bringBack: { nil })

private func pages(at page: WelcomePage, _ given: WelcomeGiven = WelcomeGiven()) -> some View {
    WelcomePages(startPage: page, given: given, act: nothing, finish: {})
}

@Test(arguments: WelcomePage.allCases, [false, true])
func eachPageLooksAsApproved(page: WelcomePage, dark: Bool) throws {
    try expectPicture(
        of: pages(at: page), width: WelcomePages.size.width, height: WelcomePages.size.height,
        named: "welcome-\(page.rawValue)-\(dark ? "dark" : "light")", dark: dark)
}

@Test func aPermissionGivenIsSaidInsteadOfAsked() throws {
    try expectPicture(
        of: pages(at: .pasting, WelcomeGiven(keeping: true, pasting: true)),
        width: WelcomePages.size.width, height: WelcomePages.size.height, named: "welcome-pasting-given")
}

@Test func keysHeldLightTheKeyboard() throws {
    try expectPicture(
        of: pages(at: .shortcut, WelcomeGiven(held: KeyCombo("v", control: true))),
        width: WelcomePages.size.width, height: WelcomePages.size.height, named: "welcome-shortcut-held")
}

@Test func keysThatWillNotDoAreWarnedOf() throws {
    try expectPicture(
        of: pages(
            at: .shortcut,
            WelcomeGiven(
                held: KeyCombo("3", shift: true),
                warning: "macOS already uses \(KeyCombo("3", shift: true).inWords). Try others.")),
        width: WelcomePages.size.width, height: WelcomePages.size.height, named: "welcome-shortcut-warning")
}

@Test(arguments: ["keeping", "pasting"], [false, true])
func eachCardLooksAsApproved(name: String, dark: Bool) throws {
    try expectPicture(
        of: name == "keeping" ? WelcomeCard.keeping : .pasting, width: WelcomeCard.size.width,
        height: WelcomeCard.size.height, named: "welcome-card-\(name)-\(dark ? "dark" : "light")", dark: dark)
}

@Test func theWelcomeOpensOnItsGreetingAndEndsOnItsLastPage() {
    #expect(WelcomePage.allCases.first == .greeting)
    #expect(WelcomePage.allCases.last == .last)
}

@Test func aShortcutIsSaidInWordsAsAppleWritesOne() {
    #expect(KeyCombo("c", shift: true).inWords == "Shift-Command-C")
    #expect(KeyCombo("v", control: true).inWords == "Control-Command-V")
    #expect(KeyCombo("space", command: false, option: true).inWords == "Option-Space")
}
