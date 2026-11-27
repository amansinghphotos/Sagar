import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's picture choices, its row of colours and its writing box, on Search's ground. The same showcase
/// was pictured from Search's own code at commit c92ea7c, by a scratch copy of it that uses this repository's
/// picture harness, into `Fixtures/Search Choices Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var pick = 1
    @State var colour = Swatches.search[2].0
    @State var text = "body { margin: 0 }\na { color: teal }"

    static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PictureChoices(
                options: [
                    (0, "Light", AnyView(Self.rgb(243, 241, 236))),
                    (1, "Dark", AnyView(Self.rgb(43, 43, 46))),
                    (
                        2, "Auto",
                        AnyView(
                            HStack(spacing: 0) {
                                Self.rgb(243, 241, 236)
                                Self.rgb(43, 43, 46)
                            })
                    ),
                ], selection: $pick)
            Swatches(colours: Swatches.search, selection: $colour)
            VStack(alignment: .leading, spacing: 6) {
                Caption("CSS for every page of this site")
                Writing(text: $text, height: 80)
            }
        }
        .padding(16)
        .frame(width: 340, height: 300)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theChoicesLookAsSearchsDo(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Choices \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: Showcase(), width: 340, height: 300, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
    #expect(differingPixels(ours, search, levels: fine) <= tolerance)
}
