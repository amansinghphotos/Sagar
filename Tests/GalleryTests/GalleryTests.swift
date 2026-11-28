import Look
import Pictures
import SwiftUI
import Testing

@testable import Gallery

/// Each page alone, without the Gallery's bar above it: the bar holds macOS's own page choice, which draws a
/// little wider on GitHub's Mac and moves with every page added.
private func alone(_ page: some View, dark: Bool) -> some View {
    page
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Role.ink)
        .background(Role.ground)
        .environment(\.theme, .modern)
        .environment(\.colorScheme, dark ? .dark : .light)
}

/// Each page as the Gallery shows it.
@ViewBuilder private func shown(_ page: Page) -> some View {
    switch page {
    case .tokens: Tokens()
    case .controls: Controls()
    case .choices: Choices()
    case .lists: Lists()
    case .overlays: Overlays()
    case .states: States()
    case .keyboard: KeyboardPage()
    }
}

/// Each page, light and dark, matches its picture: `gallery-light.png` for the tokens, the first page, and
/// `gallery-<page>-light.png` for the rest.
@Test(arguments: Page.allCases, [false, true])
func eachPageMatchesItsPicture(page: Page, dark: Bool) throws {
    let size = WindowSize.standard
    let name = page == .tokens ? "gallery" : "gallery-\(page.rawValue.lowercased())"
    try expectPicture(
        of: alone(shown(page), dark: dark), width: size.width, height: size.height,
        named: "\(name)-\(dark ? "dark" : "light")", dark: dark)
}

/// Search's column keeps its width beside its page as a card, and the page takes the rest of a narrow, a default
/// and a wide window.
@Test(arguments: WindowSize.allCases)
func theSplitFollowsTheWindow(size: WindowSize) throws {
    let split = SideSplit {
        SideItem(title: "Meeting notes", letter: "M", live: true)
        SideItem(title: "Quarterly report", letter: "Q")
    } page: {
        Text(verbatim: "The page")
    }
    try expectPicture(of: split, width: size.width, height: size.height, named: "split-\(size.rawValue.lowercased())")
}
