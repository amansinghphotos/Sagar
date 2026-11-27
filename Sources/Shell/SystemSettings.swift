import AppKit
import ServiceManagement

/// The panes of System Settings where a person allows an app something, opened at the right place.
package enum PrivacyPane: String, Sendable {
    /// Lets an app read what was copied in other apps without macOS asking each time.
    case pasteFromOtherApps = "Privacy_Pasteboard"

    /// Opens System Settings at this pane.
    package func open() {
        let address = "x-apple.systempreferences:com.apple.preference.security?\(rawValue)"
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
    }
}

/// Whether the app opens when the person logs in: the app itself, as Login Items lists it.
package enum LoginItem {
    /// True when the app is set to open at login.
    package static var isOn: Bool { SMAppService.mainApp.status == .enabled }

    /// Sets the app to open at login, or not. macOS may tell the person in a notification.
    package static func set(_ on: Bool) throws {
        if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}
