import Look
import SwiftUI

/// The Overlays page: captions, cards, panels and the panel that stands over another app, as Search has them.
struct Overlays: View {
    @State private var typed = ""

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
            VStack(alignment: .leading, spacing: Space.page.rawValue * 2) {
                Plate("Downloads", width: 340, close: {}) {
                    Line("report.pdf", "2.4 MB") { Quick("Show") {} }
                } foot: {
                    Pill("Clear", filled: true) {}
                }
                VStack(spacing: Space.near.rawValue) {
                    LaunchField(text: $typed, prompt: "Paste anything", refusals: 0)
                    LaunchList {
                        Line("report.pdf", "2.4 MB") { Key("↩", "") }
                    }
                }
                .frame(width: 340)
            }
        }
        .padding(Space.page.rawValue * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
