import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's list parts: a line with a badge, a quiet row, two letter marks and a key cap, on Search's ground.
/// The same showcase was pictured from Search's own code at commit c92ea7c, by a scratch copy of it that uses
/// this repository's picture harness, into `Fixtures/Search Lists Light.png` and `Dark.png`.
private var lists: some View {
    VStack(alignment: .leading, spacing: 10) {
        Line("Open links in", "A new tab beside this one") { Always() }
        Quiet(icon: "plus", title: "New Tab") {}
        HStack(spacing: 12) {
            Mark(icon: nil, letter: "S")
            Mark(icon: nil, letter: "N", size: 26)
        }
        Key("⌘ K", "Find anything")
    }
    .padding(12)
    .frame(width: 320, height: 210)
    .background(Role.ground)
}

@Test(arguments: [false, true])
func theListPartsLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Lists \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: lists, width: 320, height: 210, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}
