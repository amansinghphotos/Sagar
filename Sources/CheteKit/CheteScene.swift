import Shell
import SwiftUI

/// Chete's one window, which its Main.swift opens. What you copy will appear here.
public struct CheteScene: Scene {
    /// The scene, ready for the app to open.
    public init() {}

    /// One window, with Check for Updates… in the app's menu.
    public var body: some Scene {
        Window("Chete", id: "chete") {
            // The window's outer group needs a name of its own, or VoiceOver says only "group".
            Text("What You Copy Appears Here")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Your Clips")
        }
        .commands { UpdateCommands() }
    }
}
