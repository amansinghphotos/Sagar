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

/// A scroll fades at its foot while more lies below, less as the end comes up, and not at all once it is in view,
/// over 24 points, as Search's does.
@Test func aScrollFadesAsMoreLiesBeyond() {
    #expect(FadingScroll<EmptyView>.strength(over: 0) == 1)
    #expect(FadingScroll<EmptyView>.strength(over: 12) == 0.5)
    #expect(FadingScroll<EmptyView>.strength(over: 48) == 0)
    #expect(FadingScroll<EmptyView>.strength(over: -10) == 1)
}

/// Search's fading scroll over a list longer than it, on Search's ground. Search's, from its code at commit
/// c92ea7c, was pictured by a scratch copy that uses this repository's picture harness into
/// `Fixtures/Search Fading Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func aLongListFadesAsSearchsDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Fading \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let fading = FadingScroll {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(1...12, id: \.self) {
                Text(verbatim: "Line \($0)").font(.system(size: 13)).frame(height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12).frame(width: 220, height: 160).background(Role.ground)
    #expect(differingPixels(try picture(of: fading, width: 220, height: 160, dark: dark), search) <= tolerance)
}
