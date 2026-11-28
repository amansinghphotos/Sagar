import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's sidebar rows, the one in front, a chosen one and a plain one, on Search's ground.
@Test(arguments: [false, true])
func theSidebarRowsLookAsSearchsDo(dark: Bool) throws {
    let column = VStack(spacing: 2) {
        SideItem(title: "Meeting notes", letter: "M", live: true)
        SideItem(title: "Quarterly report", letter: "Q", selected: true)
        SideItem(title: "Recipes", letter: "R")
    }
    .padding(10).frame(width: 240, height: 150).background(Role.ground)
    try expectSearchPicture(of: column, width: 240, height: 150, named: "Sidebar", dark: dark)
}
