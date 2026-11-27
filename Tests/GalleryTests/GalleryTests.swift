import Look
import Pictures
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
