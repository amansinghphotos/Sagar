import Foundation

/// Your whole history in one plain file: every clip and setting, which opens on any Mac with no key.
nonisolated package struct History: Codable, Equatable, Sendable {
    package var settings: Settings
    /// Newest first.
    package var clips: [Clip]

    /// The history kept in Chete's folder, opened with the key kept under a name.
    package static func read(in folder: URL, keyName: String) throws -> History {
        History(settings: try Settings.read(in: folder), clips: try Clips(cheteFolder: folder, keyName: keyName).all())
    }

    /// A history from an exported file. A file that cannot be read whole is an error, and changes nothing.
    package static func bringBack(from file: URL) throws -> History {
        try JSONDecoder().decode(History.self, from: Data(contentsOf: file))
    }

    /// Saves the history as a plain file, whole or not at all.
    package func export(to file: URL) throws {
        try encoded().write(to: file, options: .atomic)
    }

    /// The history as the plain file holds it.
    package func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    /// Puts this history in Chete's folder in place of what is there, sealed by the key kept under a name.
    package func replace(in folder: URL, keyName: String) throws {
        let kept = try Clips(cheteFolder: folder, keyName: keyName)
        try kept.deleteAll()
        for clip in clips { try kept.keep(clip) }
        try settings.write(in: folder)
    }
}
