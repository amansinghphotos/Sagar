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
