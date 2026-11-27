import Look
import SwiftUI

/// The Lists page: lines, quiet rows, marks, badges and key caps, as Search has them.
struct Lists: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.page.rawValue) {
            VStack(spacing: 0) {
                Line("Open links in", "A new tab beside this one") { Always() }
                Line("Downloads") { Quick("Show") {} }
            }
            .frame(width: 420)
            Quiet(icon: "plus", title: "New Tab") {}
                .frame(width: 240)
            HStack(spacing: Space.apart.rawValue) {
                Mark(icon: nil, letter: "S")
                Mark(icon: nil, letter: "N", size: 26)
                Mark(icon: Image(systemName: "gearshape"), template: true, letter: "", size: 26)
            }
            Key("⌘ K", "Find anything")
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
