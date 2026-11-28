import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's colours as Search's own code draws them: its `Palette` at commit c92ea7c, pictured through this
/// repository's picture harness, light and dark, and the middle of each swatch read as red, green and blue.
private func searchColours() throws -> [String: [String: [Int]]] {
    try searchRecord("Colours")
}

@Test(arguments: Role.allCases)
func modernDrawsEachColourAsSearchDoes(role: Role) throws {
    let search = try #require(try searchColours()[role.rawValue])
    for dark in [false, true] {
        let swatch = Rectangle().fill(role).environment(\.theme, .modern)
        let drawn = try colour(at: 5, 5, in: picture(of: swatch, width: 10, height: 10, dark: dark))
        let expected = try #require(search[dark ? "dark" : "light"])
        #expect(zip(drawn, expected).allSatisfy { abs($0 - $1) <= 1 }, "\(role) \(dark ? "dark" : "light"): \(drawn)")
    }
}

@Test func blackOnWhiteIsTwentyOneToOne() {
    #expect(RGB(white: 0).contrast(with: RGB(white: 1)) == 21)
    #expect(RGB(white: 1).contrast(with: RGB(white: 0)) == 21)
}

@Test func aColourOnItselfIsOneToOne() {
    #expect(RGB(white: 0.5).contrast(with: RGB(white: 0.5)) == 1)
}

/// The grey the Web's own guidelines give as the faintest that passes 4.5 to 1 on white.
@Test func theFaintestPassingGreyOnWhiteIsJustOverFourAndAHalf() {
    let grey = RGB(red: 118.0 / 255, green: 118.0 / 255, blue: 118.0 / 255)
    #expect(abs(grey.contrast(with: RGB(white: 1)) - 4.54) < 0.01)
}
