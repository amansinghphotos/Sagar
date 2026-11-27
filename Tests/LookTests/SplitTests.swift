import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

private var split: some View {
    SideSplit {
        SideItem(title: "Meeting notes", letter: "M", live: true)
        SideItem(title: "Quarterly report", letter: "Q")
        SideItem(title: "Recipes", letter: "R")
    } page: {
        Text(verbatim: "The page").font(.system(size: 13)).foregroundStyle(Role.ink)
    }
}

/// Search's column beside its page as a card. The same was built from Search's code for its row and card at
/// commit c92ea7c, in Search's measures, by a scratch copy that uses this repository's picture harness, and
/// pictured into `Fixtures/Search Split Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func theSplitLooksAsSearchsDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Split \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    #expect(differingPixels(try picture(of: split, width: 640, height: 420, dark: dark), search) <= tolerance)
}
