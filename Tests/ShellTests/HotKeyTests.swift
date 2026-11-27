import Carbon.HIToolbox
import Testing

@testable import Shell

/// Keys no person presses: every modifier, and F19. A test holds them for a moment and lets them go.
private let rare = HotKey.Keys(key: kVK_F19, command: true, shift: true, option: true, control: true)

/// A press, as macOS delivers one to the app that holds the keys. No key is pressed, so nothing reaches
/// the app in front.
@MainActor private func press(_ hotKey: HotKey) {
    var event: EventRef?
    CreateEvent(nil, OSType(kEventClassKeyboard), UInt32(kEventHotKeyPressed), 0, 0, &event)
    var name = EventHotKeyID(signature: HotKey.signature, id: hotKey.number)
    SetEventParameter(
        event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
        MemoryLayout<EventHotKeyID>.size, &name)
    SendEventToEventTarget(event, GetEventDispatcherTarget())
}

@MainActor @Test func heldKeysCallTheAppWhenPressed() throws {
    var presses = 0
    let hotKey = try HotKey(rare) { presses += 1 }
    defer { hotKey.letGo() }
    press(hotKey)
    press(hotKey)
    #expect(presses == 2)
}

@MainActor @Test func keysLetGoCallNoMore() throws {
    var presses = 0
    let hotKey = try HotKey(rare) { presses += 1 }
    hotKey.letGo()
    press(hotKey)
    #expect(presses == 0)
}

@MainActor @Test func theSameKeysCannotBeHeldTwice() throws {
    let hotKey = try HotKey(rare) {}
    defer { hotKey.letGo() }
    #expect(HotKey.refusal(of: rare) == .heldAlready)
    #expect(throws: HotKey.Refusal.heldAlready) { try HotKey(rare) {} }
}

@MainActor @Test func keysLetGoCanBeHeldAgain() throws {
    try HotKey(rare) {}.letGo()
    #expect(HotKey.refusal(of: rare) == nil)
    try HotKey(rare) {}.letGo()
}

@MainActor @Test func keysWithoutCommandOrControlAreRefused() {
    let typing = HotKey.Keys(key: kVK_ANSI_C, shift: true, option: true)
    #expect(HotKey.refusal(of: typing) == .needsCommandOrControl)
    #expect(throws: HotKey.Refusal.needsCommandOrControl) { try HotKey(typing) {} }
}

/// macOS's own list is read for real: every Mac has some shortcuts turned on, and each is refused.
@MainActor @Test func aShortcutOfMacOSItselfIsRefused() throws {
    let own = HotKey.ofMacOS()
    let one = try #require(own.first { $0.command || $0.control })
    #expect(HotKey.refusal(of: one) == .macOSHasIt)
    #expect(throws: HotKey.Refusal.macOSHasIt) { try HotKey(one) {} }
}
