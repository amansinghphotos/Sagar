import ServiceManagement

/// Whether Chete opens when you log in, as macOS keeps it in Login Items. The first time it is turned on,
/// macOS tells you it was added there, as the spec says.
package enum LoginItem {
    package static var isOn: Bool {
        SMAppService.mainApp.status == .enabled
    }

    package static func set(_ on: Bool) throws {
        if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}
