import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's search field, empty and with words in it, then its Passwords panel's two fields and its password
/// field, on Search's ground. The same showcase was pictured from Search's own code at commit c92ea7c, through
/// this repository's picture harness, into `Fixtures/Search Fields Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var empty = ""
    @State var typed = "notes"
    @State var site = ""
    @State var user = "someone"
    @State var password = "secret"
    @FocusState private var focus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                Hunt(text: $empty, focus: $focus)
                Hunt(text: $typed, focus: $focus)
            }
            VStack(alignment: .leading, spacing: 8) {
                Field("Site", text: $site)
                Field("Username", text: $user)
                Secret("Password", text: $password)
            }
        }
        .padding(12)
        .frame(width: 300)
        .background(Role.ground)
    }
}

@Test(arguments: [false, true])
func theFieldsLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: Showcase(), width: 300, height: 200, named: "Fields", dark: dark, shadeForShade: true)
}
