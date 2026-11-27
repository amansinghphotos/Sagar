import AppKit
import Shell
import SwiftUI

/// Chete's card in the menu bar, kept up with what you copy. A clip clicked is copied, and the card closes; so it does
/// when Chete's window or its settings are opened, which would otherwise open behind it and leave it the keys.
struct CheteMenuCard: View {
    let shelf: Shelf
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        TimelineView(.everyMinute) { time in
            MenuCard(
                clips: shelf.clips, now: time.date,
                act: MenuCardActs(
                    copy: { clip in
                        _ = Pasting.paste(clip, plainText: false, mayPaste: false)
                        NSApplication.shared.keyWindow?.close()
                    },
                    open: {
                        NSApplication.shared.keyWindow?.close()
                        openWindow(id: "chete")
                        NSApplication.shared.activate()
                    },
                    settings: {
                        NSApplication.shared.keyWindow?.close()
                        openSettings()
                        NSApplication.shared.activate()
                    },
                    checkForUpdates: Updates.shared.map { updates in { updates.check() } },
                    quit: { NSApplication.shared.terminate(nil) }))
        }
    }
}
