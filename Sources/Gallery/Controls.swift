import Look
import SwiftUI

/// The Controls page: every button, field, switch and choice, and what shows when there is nothing, trouble or
/// work under way, sidebar rows, a drag handle and a folder's arrow,
/// as Search has them.
struct Controls: View {
    @State private var search = ""
    @State private var typed = "notes"
    @State private var name = ""
    @State private var password = "secret"
    @FocusState private var focus: Bool
    @State private var off = false
    @State private var on = true
    @State private var shown = true
    @State private var closes = false
    @State private var look = 1

    var body: some View {
        HStack(alignment: .top, spacing: Space.page.rawValue) {
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
                HStack(spacing: Space.page.rawValue) {
                    Switch(on: $off)
                    Switch(on: $on)
                }
                Ticks(items: [("Show the page's colour", $shown), ("Close tabs after a day", $closes)])
                Segmented(options: [(0, "Light"), (1, "Dark"), (2, "System")], selection: $look)
            }
            VStack(alignment: .leading, spacing: 0) {
                Nothing("No clips yet.")
                Trouble(message: "This could not be read.\nTry again in a moment.") {}.frame(height: 110)
                ProgressCard(
                    filename: "Clips from the old Chete", message: "Bringing them in", completed: 1200, total: 3400,
                    cancel: {})
                VStack(spacing: 2) {
                    SideItem(title: "Meeting notes", letter: "M", live: true)
                    SideItem(title: "Quarterly report", letter: "Q", selected: true)
                    SideItem(title: "Recipes", letter: "R", close: {})
                }
                .frame(width: 240)
                HStack(spacing: Space.page.rawValue) {
                    EdgeGrip(lit: false, resting: true)
                    EdgeGrip(lit: true)
                    DisclosureArrow(open: false)
                    DisclosureArrow(open: true)
                }
                .padding(Space.page.rawValue)
            }
            .frame(width: 380)
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
