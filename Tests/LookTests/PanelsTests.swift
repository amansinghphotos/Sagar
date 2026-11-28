import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's caption, card and panel, on Search's ground. The same showcase was pictured from Search's own code
/// at commit c92ea7c, by a scratch copy of it that uses this repository's picture harness, into
/// `Fixtures/Search Panels Light.png` and `Dark.png`.
private var panels: some View {
    VStack(alignment: .leading, spacing: 14) {
        Caption("Recently closed")
        Card {
            Line("report.pdf", "2.4 MB") { Quick("Show") {} }
            Rule()
            Line("photo.jpg") { Quick("Show") {} }
        }
        Plate("Downloads", width: 340, close: {}) {
            Line("report.pdf", "2.4 MB") { Quick("Show") {} }
        } foot: {
            Pill("Clear", filled: true) {}
        }
    }
    .padding(16)
    .frame(width: 400, height: 460)
    .background(Role.ground)
}

@Test(arguments: [false, true])
func thePanelsLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: panels, width: 400, height: 460, named: "Panels", dark: dark)
}
