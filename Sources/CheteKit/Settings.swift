import Foundation
import Keep
import Look

/// What you chose in Chete's settings, kept as a plain file in Chete's folder.
/// A choice you never made is the one Chete starts with.
nonisolated package struct Settings: Codable, Equatable, Sendable {
    /// Whether what you copy on your iPhone or another Mac, which macOS hands over by itself, is kept.
    package var keepsCopiesFromOtherDevices = true
    /// How long what you copy is kept: a year at first.
    package var keeping = Keeping.year
    /// The keys that open Chete from any app, or none: Shift-Command-C at first, as the earlier Chete had.
    package var shortcut: KeyCombo? = KeyCombo("c", shift: true)

    private enum CodingKeys: String, CodingKey {
        case keepsCopiesFromOtherDevices, keeping, shortcut
    }

    /// The settings kept in a folder, or the first ones if none were ever kept there.
    package static func read(in folder: URL) throws -> Settings {
        try Store(folder: folder).read(Settings.self, named: "Settings") ?? Settings()
    }

    /// Keeps the settings in a folder.
    package func write(in folder: URL) throws {
        try Store(folder: folder).write(self, named: "Settings")
    }
}

nonisolated extension Settings {
    /// A setting missing from the file, as one added in a later version, takes its first value.
    package init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let first = Settings()
        keepsCopiesFromOtherDevices =
            try values.decodeIfPresent(Bool.self, forKey: .keepsCopiesFromOtherDevices)
            ?? first.keepsCopiesFromOtherDevices
        keeping = try values.decodeIfPresent(Keeping.self, forKey: .keeping) ?? first.keeping
        shortcut = values.contains(.shortcut) ? try values.decode(KeyCombo?.self, forKey: .shortcut) : first.shortcut
    }

    /// No shortcut is written as such, so that it is kept rather than read back as the first one.
    package func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(keepsCopiesFromOtherDevices, forKey: .keepsCopiesFromOtherDevices)
        try values.encode(keeping, forKey: .keeping)
        try values.encode(shortcut, forKey: .shortcut)
    }
}
