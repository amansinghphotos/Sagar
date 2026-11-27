import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's launcher, the field and list that open over any app, plain and refused, on Search's ground. The
/// same showcase was pictured from Search's own code at commit c92ea7c (its field's words drawn by SwiftUI, as
/// here), by a scratch copy of it that uses this repository's picture harness, into
/// `Fixtures/Search Launcher Light.png` and `Dark.png`.
private struct Showcase: View {
    var refused = false
    @State private var text = ""

    var body: some View {
        VStack(spacing: 8) {
            LaunchField(text: $text, prompt: "Paste anything", refusals: 0, refused: refused)
            LaunchList {
                Text(verbatim: "A row").frame(maxWidth: .infinity, alignment: .leading).padding(8)
                Text(verbatim: "Another row").frame(maxWidth: .infinity, alignment: .leading).padding(8)
            }
        }
        .frame(width: 340)
    }
}

@Test(arguments: [false, true])
func theLauncherLooksAsSearchsDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Launcher \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let shown = VStack(spacing: 24) {
        Showcase()
        Showcase(refused: true)
    }
    .padding(32).frame(width: 420, height: 520).background(Role.ground)
    let ours = try picture(of: shown, width: 420, height: 520, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}

/// The shiver Search gives a refused field: three there-and-backs, tapering to nothing, and none under Reduce
/// Motion.
@Test func aRefusalShivers() {
    #expect(Shake(travel: 0).offset == 0)
    #expect(abs(Shake(travel: 1.0 / 12).offset - 7 * (11.0 / 12)) < 0.0001)
    #expect(Shake(travel: 1).offset == 0)
    #expect(Shake(travel: 1.0 / 12, reduced: true).offset == 0)
}
