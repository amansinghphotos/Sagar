import Foundation
import Keep

/// One thing you copied: what it holds, when you copied it, and the app it came from.
nonisolated package struct Clip: Codable, Equatable, Identifiable, Sendable {
    /// One kind of data a copy can hold. A copy may hold several, as a link is also text.
    package enum Kind: Codable, Equatable, Sendable {
        case text(String)
        /// Formatted text, as RTF, beside the same words as text.
        case richText(Data)
        case link(URL)
        /// A picture's bytes, and the kind of picture they are, such as public.png.
        case picture(Data, type: String)
        /// Where a file copied in Finder is. The file itself is never copied.
        case file(URL)
    }

    package let id: UUID
    package let kinds: [Kind]
    package let copied: Date
    /// The bundle identifier of the app it was copied in, when macOS says.
    package let app: String?

    package init(id: UUID = UUID(), kinds: [Kind], copied: Date, app: String?) {
        self.id = id
        self.kinds = kinds
        self.copied = copied
        self.app = app
    }
}

/// Your history: every clip, each sealed in a file of its own in Chete's folder.
nonisolated package struct Clips: Sendable {
    /// The name of Chete's key in the login keychain. Tests use names of their own.
    package static let keyName = "Chete · Clip Key"

    let store: Store
    let seal: Seal

    /// The history in a folder, sealed by the key kept under a name.
    package init(folder: URL, keyName: String) throws {
        store = Store(folder: folder)
        seal = try Seal(named: keyName)
    }

    /// Keeps a clip.
    package func keep(_ clip: Clip) throws {
        try store.write(clip, named: clip.id.uuidString, sealedBy: seal)
    }

    /// Every clip, newest first.
    package func all() throws -> [Clip] {
        try store.sealedNames()
            .compactMap { try store.read(Clip.self, named: $0, sealedBy: seal) }
            .sorted { $0.copied > $1.copied }
    }
}
