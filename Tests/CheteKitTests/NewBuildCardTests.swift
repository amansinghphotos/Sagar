import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

/// Made-up lines, as a release's notes give them.
private let lines = [
    ("New", "Find a clip by typing a word from it."),
    ("Better", "The list opens faster."),
    ("Fixed", "Pasting no longer stalls after a restart."),
]

/// The card Chete shows the first time a new build opens: its version and the build's lines, with no switches.
@Test(arguments: [false, true])
func theCardForANewBuildShowsItsLinesAsApproved(dark: Bool) throws {
    try expectPicture(
        of: NewBuildCard(version: "1.0", lines: lines, close: {})
            .padding(20).frame(width: 500, height: 330).background(Role.ground)
            .environment(\.colorScheme, dark ? .dark : .light),
        width: 500, height: 330, named: "new-build-\(dark ? "dark" : "light")", dark: dark)
}
