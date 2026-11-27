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

@Test(arguments: [false, true])
func theTokensPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(Tokens(), dark: dark), width: size.width, height: size.height,
        named: dark ? "gallery-dark" : "gallery-light", dark: dark)
}

@Test(arguments: [false, true])
func theControlsPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(Controls(), dark: dark), width: size.width, height: size.height,
        named: "gallery-controls-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theChoicesPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(Choices(), dark: dark), width: size.width, height: size.height,
        named: "gallery-choices-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theListsPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(Lists(), dark: dark), width: size.width, height: size.height,
        named: "gallery-lists-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theOverlaysPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(Overlays(), dark: dark), width: size.width, height: size.height,
        named: "gallery-overlays-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theStatesPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(States(), dark: dark), width: size.width, height: size.height,
        named: "gallery-states-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theKeyboardPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: alone(KeyboardPage(), dark: dark), width: size.width, height: size.height,
        named: "gallery-keyboard-\(dark ? "dark" : "light")", dark: dark)
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
