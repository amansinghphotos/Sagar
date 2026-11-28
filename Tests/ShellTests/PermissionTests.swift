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

/// Keeping what is copied counts as given unless the person set Paste from Other Apps to Ask or Deny: macOS 27
/// lets an app read what is copied without asking, and lists none in that pane.
@Test func keepingIsGivenUnlessThePersonSaidAskOrDeny() {
    #expect(Permission.keepingGiven(by: .default))
    #expect(Permission.keepingGiven(by: .alwaysAllow))
    #expect(!Permission.keepingGiven(by: .ask))
    #expect(!Permission.keepingGiven(by: .alwaysDeny))
}
