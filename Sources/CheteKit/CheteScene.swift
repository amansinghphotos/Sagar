import Shell
import SwiftUI

/// Chete's one window, which its Main.swift opens. What you copy will appear here.
public struct CheteScene: Scene {
    /// The scene, ready for the app to open.
    public init() {}

    /// One window, with Check for Updates… in the app's menu.
    public var body: some Scene {
        Window("Chete", id: "chete") {
            ContentUnavailableView("What You Copy Appears Here", systemImage: "list.clipboard")
        }
        .commands { UpdateCommands() }
    }
}
