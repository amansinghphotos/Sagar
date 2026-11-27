import Foundation
import Keep

/// What you chose in Chete's settings, kept as a plain file in Chete's folder.
/// A choice you never made is the one Chete starts with.
nonisolated package struct Settings: Codable, Equatable, Sendable {
    /// Whether what you copy on your iPhone or another Mac, which macOS hands over by itself, is kept.
    package var keepsCopiesFromOtherDevices = true

    /// The settings kept in a folder, or the first ones if none were ever kept there.
    package static func read(in folder: URL) throws -> Settings {
        try Store(folder: folder).read(Settings.self, named: "Settings") ?? Settings()
    }

    /// Keeps the settings in a folder.
    package func write(in folder: URL) throws {
        try Store(folder: folder).write(self, named: "Settings")
    }
}
