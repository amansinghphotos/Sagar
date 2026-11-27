import Look
import SwiftUI

/// The Controls page: every button, as Search has them.
struct Controls: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.page.rawValue) {
            HStack(spacing: Space.near.rawValue) {
                Pill("Plain") {}
                Pill("Main", filled: true) {}
                Pill("Delete", tint: .unsafe) {}
                Quick("Show") {}
            }
            HStack(spacing: Space.near.rawValue) {
                Door(icon: "sidebar.left", help: "Show Sidebar") {}
                Door(icon: "sidebar.left", on: true, help: "Hide Sidebar") {}
                Text(verbatim: "Pressed").modifier(Give(pressed: true))
            }
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
