import Look
import SwiftUI

/// The Overlays page: captions, cards and panels, as Search has them.
struct Overlays: View {
    var body: some View {
        HStack(alignment: .top, spacing: Space.page.rawValue * 2) {
            VStack(alignment: .leading, spacing: Space.wide.rawValue) {
                Caption("Recently closed")
                Card {
                    Line("report.pdf", "2.4 MB") { Quick("Show") {} }
                    Rule()
                    Line("photo.jpg") { Quick("Show") {} }
                }
            }
            .frame(width: 340)
            Plate("Downloads", width: 340, close: {}) {
                Line("report.pdf", "2.4 MB") { Quick("Show") {} }
            } foot: {
                Pill("Clear", filled: true) {}
            }
        }
        .padding(Space.page.rawValue * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
