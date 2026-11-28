import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// A scroll fades at its foot while more lies below, less as the end comes up, and not at all once it is in view,
/// over 24 points, as Search's does.
@Test func aScrollFadesAsMoreLiesBeyond() {
    #expect(FadingScroll<EmptyView>.strength(over: 0) == 1)
    #expect(FadingScroll<EmptyView>.strength(over: 12) == 0.5)
    #expect(FadingScroll<EmptyView>.strength(over: 48) == 0)
    #expect(FadingScroll<EmptyView>.strength(over: -10) == 1)
}

/// Twelve lines, longer than the scroll they are shown in.
private var lines: some View {
    VStack(alignment: .leading, spacing: 0) {
        ForEach(1...12, id: \.self) {
            Text(verbatim: "Line \($0)").font(.system(size: 13)).frame(height: 24)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

/// Search's fading scroll over a list longer than it, on Search's ground.
@Test(arguments: [false, true])
func aLongListFadesAsSearchsDoes(dark: Bool) throws {
    let fading = FadingScroll { lines }
        .padding(12).frame(width: 220, height: 160).background(Role.ground)
    try expectSearchPicture(of: fading, width: 220, height: 160, named: "Fading", dark: dark, shadeForShade: true)
}

/// Scrolled to its end, the same list no longer fades at its foot, but its head does, as Search's does once
/// scrolled: the line cut by the top edge is drawn far fainter than a whole line below it.
@Test(arguments: [false, true])
func aScrolledListFadesAtItsHead(dark: Bool) throws {
    let scrolled = FadingScroll { lines }
        .defaultScrollAnchor(.bottom)
        .padding(12).frame(width: 220, height: 160).background(Role.ground)
    let image = try picture(of: scrolled, width: 220, height: 160, dark: dark)
    /// How far the strongest ink in a band of rows stands from the ground, in levels.
    func ink(rows: Range<Int>) -> Int {
        let ground = colour(at: 200, 80, in: image)[0]
        return rows.flatMap { y in (12..<80).map { x in abs(colour(at: x, y, in: image)[0] - ground) } }.max() ?? 0
    }
    let head = ink(rows: 12..<20)
    let whole = ink(rows: 60..<100)
    #expect(whole > 150)
    #expect(head * 2 < whole, "the head's ink \(head), a whole line's \(whole)")
}
