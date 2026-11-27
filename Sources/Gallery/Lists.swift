import Look
import SwiftUI

/// The Lists page: lines, quiet rows, marks, badges, key caps, setting rows and a stepper, as Search has them.
struct Lists: View {
    @State private var notify = true
    @State private var size = 1.0

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
            GroupBlock(title: "Privacy", icon: "hand.raised") {
                SettingRow(icon: "bell", title: "Notifications", detail: "Let sites ask to send them.") {
                    Switch(on: $notify)
                }
                SettingRow(icon: "textformat.size", title: "Page size", detail: "How large pages are drawn.", lit: true)
                {
                    Steps(stops: [0.75, 0.9, 1.0, 1.1, 1.25], value: $size, home: 1.0) { "\(Int($0 * 100))%" }
                }
            }
            .frame(width: 460)
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
