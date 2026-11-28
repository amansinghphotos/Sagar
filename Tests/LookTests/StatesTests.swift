import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's nothing-here-yet, its error with Try Again, and its progress card, on Search's ground, with made-up
/// words. The same was built from Search's own code for them at commit c92ea7c, by a scratch copy that uses this
/// repository's picture harness, and pictured into `Fixtures/Search States Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func theStatesLookAsSearchsDo(dark: Bool) throws {
    let states = VStack(alignment: .leading, spacing: 0) {
        Nothing("No clips yet.")
        Trouble(message: "This could not be read.\nTry again in a moment.") {}.frame(height: 110)
        ProgressCard(
            filename: "Clips from the old Chete", message: "Bringing them in", completed: 1200, total: 3400, cancel: {})
    }
    .frame(width: 420, height: 380).background(Role.ground)
    try expectSearchPicture(of: states, width: 420, height: 380, named: "States", dark: dark)
}
