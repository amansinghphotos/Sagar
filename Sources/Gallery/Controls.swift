import Look
import SwiftUI

/// The Controls page: every button and field, as Search has them.
struct Controls: View {
    @State private var search = ""
    @State private var typed = "notes"
    @State private var name = ""
    @State private var password = "secret"
    @FocusState private var focus: Bool

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
            }
            VStack(alignment: .leading, spacing: Space.near.rawValue) {
                Hunt(text: $search, focus: $focus)
                Hunt(text: $typed, focus: $focus)
                Field("Name", text: $name)
                Secret("Password", text: $password)
            }
            .frame(width: 300)
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
