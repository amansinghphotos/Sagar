import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's drag handle at rest and lit, and its folder arrow shut and open, on Search's ground. Search's, from its
/// code at commit c92ea7c, was pictured by a scratch copy that uses this repository's picture harness into
/// `Fixtures/Search Grip Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func theHandleAndArrowLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Grip \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let parts = HStack(spacing: 24) {
        EdgeGrip(lit: false, resting: true)
        EdgeGrip(lit: true)
        DisclosureArrow(open: false)
        DisclosureArrow(open: true)
    }
    .padding(20).frame(width: 200, height: 80).background(Role.ground)
    #expect(differingPixels(try picture(of: parts, width: 200, height: 80, dark: dark), search) <= tolerance)
}

/// The handle's measures, which a one-point change in its length would slip past in the picture: Search's
/// `Grip` in Design.swift, 4 wide, 28 long at rest and 40 lit.
@Test func theHandleHasSearchsMeasures() {
    #expect([Grip.width, Grip.rest, Grip.lit] == [4, 28, 40])
}
