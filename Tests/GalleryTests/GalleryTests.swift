import Look
import Pictures
import SwiftUI
import Testing

@testable import Gallery

@Test func theEmptyGalleryMatchesItsApprovedPictureInTheLightLook() throws {
    let size = WindowSize.standard
    try expectPicture(of: Gallery(), width: size.width, height: size.height, named: "gallery-light")
}

@Test func theEmptyGalleryMatchesItsApprovedPictureInTheDarkLook() throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(appearance: .dark), width: size.width, height: size.height, named: "gallery-dark", dark: true)
}

@Test(arguments: [false, true])
func theControlsPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(page: .controls, appearance: dark ? .dark : .light), width: size.width, height: size.height,
        named: "gallery-controls-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theChoicesPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(page: .choices, appearance: dark ? .dark : .light), width: size.width, height: size.height,
        named: "gallery-choices-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theListsPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(page: .lists, appearance: dark ? .dark : .light), width: size.width, height: size.height,
        named: "gallery-lists-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theOverlaysPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(page: .overlays, appearance: dark ? .dark : .light), width: size.width, height: size.height,
        named: "gallery-overlays-\(dark ? "dark" : "light")", dark: dark)
}

@Test(arguments: [false, true])
func theStatesPageMatchesItsPicture(dark: Bool) throws {
    let size = WindowSize.standard
    try expectPicture(
        of: Gallery(page: .states, appearance: dark ? .dark : .light), width: size.width, height: size.height,
        named: "gallery-states-\(dark ? "dark" : "light")", dark: dark)
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
