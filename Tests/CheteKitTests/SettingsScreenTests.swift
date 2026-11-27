import AppKit
import Foundation
import Keep
import Look
import Pictures
import SwiftUI
import Testing

@testable import CheteKit

private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

/// Chete's folder made fresh for a test, its clips sealed by a key the real Chete never uses.
/// Each test removes both when it ends.
private struct Mac {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let keyName = "Sagar Tests · \(UUID().uuidString)"

    func clips() throws -> Clips {
        try Clips(cheteFolder: folder, keyName: keyName)
    }

    func choices() -> Choices {
        Choices(folder: folder, keyName: keyName, now: { now })
    }

    func removed() {
        try? Seal.forget(named: keyName)
        try? FileManager.default.removeItem(at: folder)
    }
}

private let recent = Clip(kinds: [.text("this morning")], copied: now - 3600, app: nil)
private let old = Clip(kinds: [.text("two months ago")], copied: now - 60 * 86400, app: nil)

@Test func choosingAShorterTimeDeletesWhatIsOlderAtOnce() throws {
    let mac = Mac()
    defer { mac.removed() }
    try mac.clips().keep(recent)
    try mac.clips().keep(old)
    let choices = mac.choices()
    #expect(choices.settings.keeping == .year)
    choices.settings.keeping = .month
    #expect(try mac.clips().all() == [recent])
    #expect(try Settings.read(in: mac.folder).keeping == .month)
}

@Test func turningOffCopiesFromOtherDevicesIsKept() throws {
    let mac = Mac()
    defer { mac.removed() }
    mac.choices().settings.keepsCopiesFromOtherDevices = false
    #expect(try Settings.read(in: mac.folder).keepsCopiesFromOtherDevices == false)
    #expect(mac.choices().settings.keepsCopiesFromOtherDevices == false)
}

@Test func deletingEverythingLeavesNoClipAndKeepsTheSettings() throws {
    let mac = Mac()
    defer { mac.removed() }
    try mac.clips().keep(recent)
    let choices = mac.choices()
    choices.settings.keeping = .forever
    try choices.deleteAll()
    #expect(try mac.clips().all() == [])
    #expect(try Settings.read(in: mac.folder).keeping == .forever)
}

@Test func anExportBroughtBackOnAnotherMacIsTheSame() throws {
    let here = Mac()
    let there = Mac()
    let file = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
    defer {
        here.removed()
        there.removed()
        try? FileManager.default.removeItem(at: file)
    }
    try here.clips().keep(recent)
    try here.clips().keep(old)
    here.choices().settings.keeping = .forever
    try here.choices().exported().write(to: file)
    try there.clips().keep(Clip(kinds: [.text("already there")], copied: now, app: nil))
    let choices = there.choices()
    try choices.bringBack(from: file)
    #expect(try there.clips().all() == [recent, old])
    #expect(choices.settings.keeping == .forever)
}

// The screen, pictured as tall as what is in it, as its window is: open at login is shown off, as on a Mac
// where it was never turned on.

@Test(arguments: [false, true])
func theSettingsMatchTheirPicture(dark: Bool) throws {
    let mac = Mac()
    defer { mac.removed() }
    let screen = SettingsScreen(choices: mac.choices(), opensAtLogin: .constant(false))
        .environment(\.colorScheme, dark ? .dark : .light)
    let height = NSHostingView(rootView: screen.frame(width: SettingsScreen.width)).fittingSize.height
    try expectPicture(
        of: screen, width: SettingsScreen.width, height: height,
        named: "settings-\(dark ? "dark" : "light")", dark: dark)
}

// The list keeps up with what Settings does.

@Test func theListKeepsUpWhenSettingsDeleteOrBringBack() async throws {
    let mac = Mac()
    let other = Mac()
    defer {
        mac.removed()
        other.removed()
    }
    // A history exported on another Mac, holding what this one also copied.
    try await Copies(folder: other.folder, keyName: other.keyName)
        .take([.text("Lunch menu")], fromOtherDevice: false, copied: now - 60, app: nil)
    let file = other.folder.appending(path: "Chete Clips.json")
    try other.choices().exported().write(to: file)

    let copies = try Copies(folder: mac.folder, keyName: mac.keyName)
    try await copies.take([.text("Lunch menu")], fromOtherDevice: false, copied: now, app: nil)
    try await copies.take([.text("Trip notes")], fromOtherDevice: false, copied: now, app: nil)
    let shelf = Shelf(try await copies.all())
    var told = 0
    let choices = Choices(folder: mac.folder, keyName: mac.keyName, now: { now }, changed: { told += 1 })

    try choices.deleteAll()
    #expect(told == 1)
    shelf.clips = try await copies.reread()
    #expect(shelf.clips.isEmpty)

    try choices.bringBack(from: file)
    #expect(told > 1)
    shelf.clips = try await copies.reread()
    #expect(shelf.clips.map(\.kinds) == [[.text("Lunch menu")]])

    // Copied again, what was brought back stays one clip.
    try await copies.take([.text("Lunch menu")], fromOtherDevice: false, copied: now, app: nil)
    #expect(try await copies.all().count == 1)
}

@Test func choosingAShorterTimeTellsTheList() throws {
    let mac = Mac()
    defer { mac.removed() }
    var told = 0
    let choices = Choices(folder: mac.folder, keyName: mac.keyName, now: { now }, changed: { told += 1 })
    choices.settings.keeping = .week
    #expect(told == 1)
}

@Test func aShortcutThatWontDoIsShownOnTheKeyboard() throws {
    let mac = Mac()
    defer { mac.removed() }
    let general = General(
        choices: mac.choices(), opensAtLogin: .constant(false), shortcut: Shortcut(),
        refused: (KeyCombo("3", shift: true), "Your Mac already uses these keys.")
    )
    .padding(Space.page.rawValue)
    .background(Role.ground)
    let height = NSHostingView(rootView: general.frame(width: SettingsScreen.width)).fittingSize.height
    try expectPicture(of: general, width: SettingsScreen.width, height: height, named: "settings-shortcut-warning")
}
