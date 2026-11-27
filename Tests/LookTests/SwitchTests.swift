import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's switch off and on and its segmented choice, on Search's ground. (Its check boxes are Apple's own,
/// which draw differently outside a test, so they are not compared.) The same showcase
/// was pictured from Search's own code at commit c92ea7c, by a scratch copy of it that uses this repository's
/// picture harness, into `Fixtures/Search Switches Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var off = false
    @State var on = true
    @State var pick = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Switch(on: $off)
                Switch(on: $on)
            }
            Segmented(options: [(0, "Light"), (1, "Dark"), (2, "System")], selection: $pick)
        }
        .padding(16)
        .frame(width: 340, height: 220)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theSwitchesLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Switches \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: Showcase(), width: 340, height: 220, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}
