import AppKit
import Shell
import os

/// Watches a pasteboard and hands each new copy to Copies.
///
/// macOS sends no word when something is copied. So the watcher asks the pasteboard for its change count,
/// a single number, twice a second, letting macOS move each wake by up to a quarter second to group it
/// with others. It reads what was copied only when that number moves.
package final class Watcher {
    /// How often the watcher looks.
    package static let looksPerSecond = 2

    private let pasteboard: NSPasteboard
    private let copies: Copies
    /// The change count last seen. What was on the pasteboard before Chete opened is not a new copy.
    private var seen: Int
    private var watching: Task<Void, Never>?
    /// Whether Paste from Other Apps is allowed. Until it is, nothing copied is read, so macOS never asks.
    private let allowed: @MainActor () -> Bool
    /// Told of each clip kept, so the list can show it.
    package var kept: (Clip) -> Void = { _ in }

    /// A watcher for a pasteboard: the one everything is copied to, unless a test brings its own.
    package init(
        pasteboard: NSPasteboard = .general, copies: Copies,
        allowed: @escaping @MainActor () -> Bool = { Permission.pasteFromOtherApps.isGiven }
    ) {
        self.pasteboard = pasteboard
        self.copies = copies
        self.allowed = allowed
        seen = pasteboard.changeCount
    }

    isolated deinit {
        watching?.cancel()
    }

    /// Looks for new copies until the watcher is gone.
    package func start() {
        watching = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1) / Self.looksPerSecond, tolerance: .milliseconds(250))
                await self?.look()
            }
        }
    }

    /// Takes in what was copied since the last look, if anything was.
    package func look() async {
        let count = pasteboard.changeCount
        guard count != seen else { return }
        seen = count
        guard allowed() else { return }
        guard pasteboard.types?.contains(.chetePasted) != true else { return }
        let fromOtherDevice = pasteboard.types?.contains(.fromOtherDevice) == true
        let app = fromOtherDevice ? nil : NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        do {
            if let clip = try await copies.take(kinds(), fromOtherDevice: fromOtherDevice, copied: .now, app: app) {
                kept(clip)
            }
        } catch {
            Logger(subsystem: "com.amansingh.chete", category: "Copies").error("A copy was not kept: \(error)")
        }
    }

    /// What the pasteboard holds that Chete keeps. Files copied in Finder are kept alone, as where they
    /// are, leaving out the names and icons Finder adds; a link leaves out the same words as text.
    private func kinds() -> [Clip.Kind] {
        let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        if let files = files as? [URL], !files.isEmpty { return files.map(Clip.Kind.file) }
        let link = pasteboard.string(forType: .URL).flatMap(URL.init(string:))
        var kinds: [Clip.Kind] = []
        if let text = pasteboard.string(forType: .string), text != link?.absoluteString { kinds.append(.text(text)) }
        if let rtf = pasteboard.data(forType: .rtf) { kinds.append(.richText(rtf)) }
        if let link { kinds.append(.link(link)) }
        if let type = pasteboard.availableType(from: [.png, .tiff]), let data = pasteboard.data(forType: type) {
            kinds.append(.picture(data, type: type.rawValue))
        }
        return kinds
    }
}

extension NSPasteboard.PasteboardType {
    /// The mark macOS puts on a copy it brings from your iPhone or another of your Macs.
    fileprivate static let fromOtherDevice = Self("com.apple.is-remote-clipboard")
}
