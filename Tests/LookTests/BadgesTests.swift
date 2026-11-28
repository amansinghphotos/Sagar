import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's unread count hung from icons, bare and ringed, on Search's ground.
private struct Showcase: View {
    var body: some View {
        HStack(spacing: 28) {
            ForEach([("3", false), ("12+", false), ("99+", true)], id: \.0) { count, ringed in
                Image(systemName: "tray").font(.system(size: 16)).foregroundStyle(Role.ink)
                    .frame(width: 16, height: 16)
                    .unreadBadge(count, icon: 16, ring: ringed ? Role.ground : nil)
                    .padding(8).background(Role.wash, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(20)
        .frame(width: 220, height: 80)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theCountLooksAsSearchsDoes(dark: Bool) throws {
    try expectSearchPicture(of: Showcase(), width: 220, height: 80, named: "Count", dark: dark, shadeForShade: true)
}

/// Search's reading fill, two fifths of the way, over its row's wash.
private struct Reading: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Role.wash)
            GeometryReader { geo in ReadingFill(value: 0.4, width: geo.size.width) }
        }
        .frame(width: 200, height: 32)
        .padding(20)
        .frame(width: 240, height: 72)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theReadingFillLooksAsSearchsDoes(dark: Bool) throws {
    let ours = try expectSearchPicture(of: Reading(), width: 240, height: 72, named: "Reading", dark: dark)
    // The fill is faint: read its edge, two fifths along, rather than trust the count of pixels.
    let filled = colour(at: 60, 36, in: ours)
    let open = colour(at: 140, 36, in: ours)
    #expect(filled != open)
    let theirs = try colour(at: 60, 36, in: searchPicture("Reading", dark: dark))
    #expect(zip(theirs, filled).allSatisfy { abs($0 - $1) <= 2 })
}
