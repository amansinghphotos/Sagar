// A shortcut that works in any app. macOS holds the keys for the app and asks no permission for it.
import Carbon.HIToolbox

/// Keys an app holds while it runs. Whatever app is in front, macOS calls this one when they are pressed.
package final class HotKey {
    /// A key and what is held with it. The key is named by its place on the keyboard, as macOS numbers keys.
    nonisolated package struct Keys: Hashable, Sendable {
        package var key: Int
        package var command: Bool
        package var shift: Bool
        package var option: Bool
        package var control: Bool

        package init(key: Int, command: Bool = false, shift: Bool = false, option: Bool = false, control: Bool = false)
        {
            self.key = key
            self.command = command
            self.shift = shift
            self.option = option
            self.control = control
        }

        /// What is held with the key, as macOS counts it.
        fileprivate var with: Int {
            (command ? cmdKey : 0) | (shift ? shiftKey : 0) | (option ? optionKey : 0) | (control ? controlKey : 0)
        }
    }

    /// Why a set of keys cannot be a shortcut.
    nonisolated package enum Refusal: Error, Equatable, Sendable {
        /// Without Command or Control the keys would get in the way of typing, and macOS may refuse them.
        case needsCommandOrControl
        /// A shortcut of macOS itself that is turned on. macOS would hand the keys over all the same,
        /// so its own list is the only way to know.
        case macOSHasIt
        case heldAlready
        /// macOS would not hand them over, with the number it gave.
        case macOSRefused(Int32)
    }

    /// Marks a press as one of this module's.
    static let signature: OSType = 0x5347_5248
    private static var held: [UInt32: HotKey] = [:]
    private static var last: UInt32 = 0
    private static var listening = false

    /// The number macOS gives back with each press of these keys.
    let number: UInt32
    package let keys: Keys
    private let pressed: () -> Void
    private var hold: EventHotKeyRef?

    /// Holds the keys until `letGo`, calling `pressed` each time they are pressed in any app.
    package init(_ keys: Keys, pressed: @escaping () -> Void) throws(Refusal) {
        if let refusal = Self.refusal(of: keys) { throw refusal }
        Self.listen()
        Self.last += 1
        number = Self.last
        self.keys = keys
        self.pressed = pressed
        let name = EventHotKeyID(signature: Self.signature, id: number)
        let answer = RegisterEventHotKey(
            UInt32(keys.key), UInt32(keys.with), name, GetEventDispatcherTarget(), 0, &hold)
        guard answer == noErr else { throw .macOSRefused(answer) }
        Self.held[number] = self
    }

    /// Gives the keys back to whatever app is in front.
    package func letGo() {
        if let hold { UnregisterEventHotKey(hold) }
        hold = nil
        Self.held[number] = nil
    }

    /// Why these keys cannot be a shortcut, or nothing if they can. It holds nothing.
    /// It cannot know of another app's shortcut: Apple documents no way to see those.
    package static func refusal(of keys: Keys) -> Refusal? {
        guard keys.command || keys.control else { return .needsCommandOrControl }
        if held.values.contains(where: { $0.keys == keys }) { return .heldAlready }
        return ofMacOS().contains(keys) ? .macOSHasIt : nil
    }

    /// The shortcuts of macOS itself that are turned on, such as the ones for screenshots.
    package static func ofMacOS() -> Set<Keys> {
        var list: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&list) == noErr, let all = list?.takeRetainedValue() as? [[String: Any]]
        else { return [] }
        return Set(
            all.compactMap { one in
                guard one[kHISymbolicHotKeyEnabled as String] as? Bool == true,
                    let key = one[kHISymbolicHotKeyCode as String] as? Int,
                    let with = one[kHISymbolicHotKeyModifiers as String] as? Int
                else { return nil }
                return Keys(
                    key: key, command: with & cmdKey != 0, shift: with & shiftKey != 0,
                    option: with & optionKey != 0, control: with & controlKey != 0)
            })
    }

    /// Asks macOS, once, to tell this app of each press of keys it holds.
    private static func listen() {
        guard !listening else { return }
        listening = true
        let press = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))]
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ in
                var name = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &name)
                let number = name.id
                guard name.signature == HotKey.signature else { return OSStatus(eventNotHandledErr) }
                // macOS delivers presses on the main thread, where the app's own work is done.
                MainActor.assumeIsolated { HotKey.held[number]?.pressed() }
                return noErr
            }, 1, press, nil, nil)
    }
}
