import AppKit
import SwiftUI

extension View {
    /// Names the group that holds a window's content, which SwiftUI leaves unnamed, so that VoiceOver
    /// says what the window holds instead of only "group".
    package func windowName(_ name: String) -> some View {
        background(WindowNamer(name: name))
    }
}

/// An empty view that, once it is in a window, names the view holding that window's content.
private struct WindowNamer: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> Namer { Namer(name: name) }

    func updateNSView(_ namer: Namer, context: Context) {
        namer.name = name
        namer.window?.contentView?.setAccessibilityLabel(name)
    }

    final class Namer: NSView {
        var name: String

        init(name: String) {
            self.name = name
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.contentView?.setAccessibilityLabel(name)
        }
    }
}
