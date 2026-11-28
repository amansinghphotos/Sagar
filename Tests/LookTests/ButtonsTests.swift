import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's buttons at rest, as one showcase on Search's ground, so no Mac's own window colour shows through.
private var buttons: some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
            Pill("Plain") {}
            Pill("Main", filled: true) {}
            Pill("Delete", tint: .unsafe) {}
            Quick("Show") {}
        }
        HStack(spacing: 8) {
            Door(icon: "sidebar.left") {}
            Door(icon: "sidebar.left", on: true) {}
        }
    }
    .padding(12)
    .frame(width: 320, height: 90)
    .background(Role.ground)
}

@Test(arguments: [false, true])
func theButtonsLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: buttons, width: 320, height: 90, named: "Buttons", dark: dark)
}

/// A pressed thing gives to Search's 97 per cent, and not at all under Reduce Motion.
@Test func aPressGivesAsSearchsDoes() {
    #expect(Give.scale(pressed: true, motion: Motion(reduceMotion: false)) == 0.97)
    #expect(Give.scale(pressed: false, motion: Motion(reduceMotion: false)) == 1)
    #expect(Give.scale(pressed: true, motion: Motion(reduceMotion: true)) == 1)
}
