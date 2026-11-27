import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's unread count hung from icons, bare and ringed, on Search's ground. The same showcase was pictured from
/// Search's own code at commit c92ea7c, by a scratch copy of it that uses this repository's picture harness, into
/// `Fixtures/Search Count Light.png` and `Dark.png`.
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
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Count \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: Showcase(), width: 220, height: 80, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}
