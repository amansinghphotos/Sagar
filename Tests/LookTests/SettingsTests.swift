import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// A group of two of Search's setting rows, the second lit, and its stepper, on Search's ground. The same
/// showcase was pictured from Search's own code at commit c92ea7c, by a scratch copy of it that uses this
/// repository's picture harness, into `Fixtures/Search Settings Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var on = true
    @State var size = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBlock(title: "Privacy", icon: "hand.raised") {
                row(lit: false)
                row(lit: true)
            }
            Steps(stops: [0.75, 0.9, 1.0, 1.1, 1.25], value: $size, home: 1.0) { "\(Int($0 * 100))%" }
        }
        .padding(16)
        .frame(width: 460, height: 300)
        .background(Role.ground)
    }

    private func row(lit: Bool) -> some View {
        SettingRow(icon: "bell", title: "Notifications", detail: "Let sites ask to send them.", lit: lit) {
            Switch(on: $on)
        }
    }
}

@Test(arguments: [false, true])
func theSettingRowsLookAsSearchsDo(dark: Bool) throws {
    try expectSearchPicture(of: Showcase(), width: 460, height: 300, named: "Settings", dark: dark)
}

/// The stepper moves to the nearest stop either way, even from a value between stops, and none past the ends.
@Test func theStepperMovesStopByStop() {
    let stops = [0.75, 0.9, 1.0, 1.1, 1.25]
    #expect(Steps.neighbours(of: 1.0, in: stops) == (0.9, 1.1))
    #expect(Steps.neighbours(of: 0.95, in: stops) == (0.9, 1.0))
    #expect(Steps.neighbours(of: 0.75, in: stops) == (nil, 0.9))
    #expect(Steps.neighbours(of: 1.25, in: stops) == (1.1, nil))
}
