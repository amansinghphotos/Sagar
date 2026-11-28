import Foundation
import Testing

@testable import Shell

@Test func eachPermissionOpensSystemSettingsAtItsOwnPlace() {
    #expect(
        Permission.pasteFromOtherApps.place?.absoluteString
            == "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard")
    #expect(
        Permission.accessibility.place?.absoluteString
            == "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
}

/// Reading whether a permission is given asks nothing: no dialog comes up, and the test does not wait.
@Test @MainActor func readingWhetherAPermissionIsGivenAsksNothing() {
    for permission in Permission.allCases { _ = permission.isGiven }
}
