import Look
import SwiftUI

/// The Lists page: lines, quiet rows, marks, badges, unread counts, key caps, how far a page is read, setting rows, a stepper, a fading list, a banner
/// and a toast, as Search has them, the toast in Search's capsule for a link's address.
struct Lists: View {
    @State private var toast = {
        var queue = ToastQueue()
        queue.show("Copied. Press ⌘V to paste.")
        return queue
    }()
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
                Image(systemName: "tray").frame(width: 16, height: 16)
                    .unreadBadge("12+", icon: 16, ring: .ground)
            }
            Key("⌘ K", "Find anything")
            ZStack(alignment: .leading) {
                Rectangle().fill(Role.wash)
                GeometryReader { geo in ReadingFill(value: 0.4, width: geo.size.width) }
                Text(verbatim: "Read two fifths of the way").padding(.leading, Space.near.rawValue)
            }
            .frame(width: 240, height: 32)
            GroupBlock(title: "General", icon: "gearshape") {
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
        .overlay(alignment: .topTrailing) {
            FadingScroll {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(1...12, id: \.self) { Text(verbatim: "Line \($0)").frame(height: 24) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 220, height: 160)
            .padding(Space.page.rawValue)
        }
        .overlay(alignment: .bottomTrailing) {
            Banner(
                icon: "bell", question: "Chete wants to paste for you", yes: ("Allow once", {}),
                maybe: ("Always allow", {}), no: ("Don't allow", {})
            )
            .padding(Space.page.rawValue)
        }
        .toasts($toast)
    }
}
