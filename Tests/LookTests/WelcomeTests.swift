import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's welcome frame, heading, foot, big button and choice rows, on a stand-in page: a heading and two
/// choices in a card, on the second of four pages. The same stand-in page, built from Search's own code for those
/// parts at commit c92ea7c by a scratch copy that uses this repository's picture harness, was pictured into
/// `Fixtures/Search Welcome Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var a = true
    @State var b = false

    var body: some View {
        Welcome(
            pages: 4, last: "Start browsing", startPage: 1, finish: {},
            page: { _ in
                VStack(alignment: .leading, spacing: 22) {
                    WelcomeHeading(
                        "Bring things over.",
                        "Passwords go into your keychain, bookmarks into the menu, and history means the address field already knows where you go."
                    )
                    VStack(alignment: .leading, spacing: 14) {
                        Choice("Passwords", "Into your keychain.", on: $a, plain: true)
                        Rule(inset: 0)
                        Choice("History", "So the address field knows where you go.", on: $b)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Role.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            })
    }
}

@Test(arguments: [false, true])
func theWelcomeLooksAsSearchsDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Welcome \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: Showcase(), width: 640, height: 480, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}
