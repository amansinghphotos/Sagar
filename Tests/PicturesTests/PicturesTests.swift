import Foundation
import SwiftUI
import Testing

@testable import Pictures

/// Fifteen of Apple's controls on one screen: the ones that draw properly only inside a real window.
private struct Controls: View {
    @State private var isOn = true
    @State private var choice = 1
    @State private var amount = 0.6
    @State private var count = 3
    @State private var text = "Typed text"
    @State private var secret = "secret"
    @State private var note = "A longer note\nover two lines"
    @State private var date = Date(timeIntervalSince1970: 1_800_000_000)

    var body: some View {
        Form {
            Button("1 Button") {}
            Button("2 Prominent") {}.buttonStyle(.borderedProminent)
            Toggle("3 Switch", isOn: $isOn).toggleStyle(.switch)
            Toggle("4 Checkbox", isOn: $isOn).toggleStyle(.checkbox)
            Picker("5 Menu picker", selection: $choice) { options }
            Picker("6 Segmented", selection: $choice) { options }.pickerStyle(.segmented)
            Picker("7 Radio", selection: $choice) { options }.pickerStyle(.radioGroup)
            Slider(value: $amount) { Text("8 Slider") }
            Stepper("9 Stepper \(count)", value: $count)
            TextField("10 Field", text: $text)
            SecureField("11 Secure", text: $secret)
            LabeledContent("12 Editor") { TextEditor(text: $note).frame(height: 40) }
            DatePicker("13 Date", selection: $date, displayedComponents: .date)
                .environment(\.timeZone, .gmt)
                .environment(\.locale, Locale(identifier: "en_GB"))
            ProgressView("14 Progress", value: 0.4)
            Menu("15 Menu") { Button("A") {} }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var options: some View {
        Text("One").tag(1)
        Text("Two").tag(2)
    }
}

@Test func fifteenControlsMatchTheirApprovedPicture() throws {
    try expectPicture(of: Controls(), width: 420, height: 720, named: "controls")
}

@Test func theSameScreenPicturedTwiceIsTheSame() throws {
    let first = try picture(of: Controls(), width: 420, height: 720)
    let second = try picture(of: Controls(), width: 420, height: 720)
    #expect(differingPixels(first, second) == 0)
}

@Test func oneChangedWordOnAWideScreenIsSeenAsDifferent() throws {
    let before = try picture(of: Text("The window is open"), width: 900, height: 600)
    let after = try picture(of: Text("The window is shut"), width: 900, height: 600)
    #expect(differingPixels(before, after) > tolerance)
}

@Test func aPictureIsTwiceTheSizeInPixels() throws {
    let image = try picture(of: Text("Size"), width: 200, height: 80)
    #expect(image.width == 400 && image.height == 160)
}

@Test func aScreenWithNoApprovedPictureFailsAndLeavesOneToApprove() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let made = folder.appending(path: "made")
    defer { try? FileManager.default.removeItem(at: folder) }
    let verdict = try compare(Text("New"), width: 120, height: 40, named: "new", approved: folder, made: made)
    #expect(verdict == .noApprovedPicture)
    #expect(FileManager.default.fileExists(atPath: made.appending(path: "new.png").path))
}

@Test func anEmptyScreenShowsTheWindowBehindIt() throws {
    let empty = try picture(of: Color.clear, width: 60, height: 40)
    let window = try picture(of: Color(nsColor: .windowBackgroundColor), width: 60, height: 40)
    #expect(differingPixels(empty, window) == 0)
}

@Test func everyApprovedPictureIsSolidFromEdgeToEdge() throws {
    let tests = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    let pictures = try FileManager.default.subpathsOfDirectory(atPath: tests.path)
        .filter { $0.contains("/Pictures/") && $0.hasSuffix(".png") }
    #expect(!pictures.isEmpty)
    for path in pictures {
        let image = try #require(approvedPicture(at: tests.appending(path: path)), "\(path)")
        #expect(seeThroughPixels(image) == 0, "\(path)")
    }
}
