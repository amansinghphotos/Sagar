import AppKit
import ApplicationServices

/// Puts a clip back on the pasteboard, and pastes it for you once you have let Chete.
package enum Pasting {
    /// What became of a clip you picked.
    package enum Outcome: Equatable {
        /// It was pasted into the app in front.
        case pasted
        /// It was copied, and Chete says to press Command-V, because you have not let it paste.
        case copied
    }

    /// Puts a clip on the pasteboard and, if you have let Chete, presses Command-V in the app in front.
    package static func paste(
        _ clip: Clip, plainText: Bool, on pasteboard: NSPasteboard = .general, mayPaste: Bool = AXIsProcessTrusted()
    ) -> Outcome {
        put(clip, plainText: plainText, on: pasteboard)
        guard mayPaste else { return .copied }
        pressCommandV()
        return .pasted
    }

    /// Puts a clip on the pasteboard as it was copied, or as its words alone. A picture has no words,
    /// so it is always put back as the picture. Chete marks it, so the watcher does not take it in again.
    package static func put(_ clip: Clip, plainText: Bool, on pasteboard: NSPasteboard) {
        let words = plainText ? clip.words : nil
        let items = words.map { [item(.string, $0)] } ?? items(for: clip.kinds)
        items.first?.setData(Data(), forType: .chetePasted)
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
    }

    /// The items an app writes for these kinds: one for each file, as Finder does, or one holding the rest.
    private static func items(for kinds: [Clip.Kind]) -> [NSPasteboardItem] {
        let files = kinds.compactMap { if case .file(let file) = $0 { file } else { nil } }
        if !files.isEmpty { return files.map { item(.fileURL, $0.absoluteString) } }
        let item = NSPasteboardItem()
        for kind in kinds {
            switch kind {
            case .text(let text): item.setString(text, forType: .string)
            case .richText(let rtf): item.setData(rtf, forType: .rtf)
            case .link(let link):
                item.setString(link.absoluteString, forType: .URL)
                if item.string(forType: .string) == nil { item.setString(link.absoluteString, forType: .string) }
            case .picture(let data, let type): item.setData(data, forType: .init(type))
            case .file: break
            }
        }
        return [item]
    }

    private static func item(_ type: NSPasteboard.PasteboardType, _ string: String) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        item.setString(string, forType: type)
        return item
    }

    /// Presses Command-V, as you would, in whichever app is in front.
    private static func pressCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: down)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }
}

extension Clip {
    /// The clip as plain words: its text, its link, or where its files are, one to a line. A picture has none.
    fileprivate var words: String? {
        for kind in kinds { if case .text(let text) = kind { return text } }
        for kind in kinds { if case .link(let link) = kind { return link.absoluteString } }
        let files = kinds.compactMap { if case .file(let file) = $0 { file.path(percentEncoded: false) } else { nil } }
        return files.isEmpty ? nil : files.joined(separator: "\n")
    }
}

extension NSPasteboard.PasteboardType {
    /// The mark on what Chete puts back to paste.
    static let chetePasted = Self("com.amansingh.chete.pasted")
}
