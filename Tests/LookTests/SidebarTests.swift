import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's sidebar rows, the one in front, a chosen one and a plain one, on Search's ground. The same rows were
/// built from Search's code for them at commit c92ea7c, by a scratch copy that uses this repository's picture
/// harness, and pictured into `Fixtures/Search Sidebar Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func theSidebarRowsLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Sidebar \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let column = VStack(spacing: 2) {
        SideItem(title: "Meeting notes", letter: "M", live: true)
        SideItem(title: "Quarterly report", letter: "Q", selected: true)
        SideItem(title: "Recipes", letter: "R")
    }
    .padding(10).frame(width: 240, height: 150).background(Role.ground)
    #expect(differingPixels(try picture(of: column, width: 240, height: 150, dark: dark), search) <= tolerance)
}
