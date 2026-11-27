import Foundation

/// What you choose in Chete's settings, kept as you choose it, and the things you can do to your history
/// there: delete it all, export it, and bring it back.
@Observable
package final class Choices {
    private let folder: URL
    private let keyName: String
    private let now: () -> Date

    /// Kept the moment it changes. A shorter time to keep things deletes what is older at once.
    package var settings: Settings {
        didSet { attempt { try keep() } }
    }
    /// What went wrong the last time, in words, until something works.
    package var failure: String?

    /// The choices kept in Chete's folder, whose clips are sealed by the key under a name.
    package init(folder: URL, keyName: String, now: @escaping () -> Date = { .now }) {
        self.folder = folder
        self.keyName = keyName
        self.now = now
        do {
            settings = try Settings.read(in: folder)
        } catch {
            settings = Settings()
            failure = "Your settings could not be read, so Chete uses its first ones."
        }
    }

    /// The choices in Chete's own folder on this Mac.
    package static func onThisMac() -> Choices {
        Choices(folder: .applicationSupportDirectory.appending(path: "Chete"), keyName: Clips.keyName)
    }

    /// Does something, and says so if it did not work.
    package func attempt(_ work: () throws -> Void) {
        do {
            try work()
            failure = nil
        } catch {
            failure = "That did not work: \(error.localizedDescription)"
        }
    }

    /// Deletes every clip. The settings stay.
    package func deleteAll() throws {
        try clips().deleteAll()
    }

    /// Every clip and setting as the plain file an export saves.
    package func exported() throws -> Data {
        try History.read(in: folder, keyName: keyName).encoded()
    }

    /// Puts an exported file's clips and settings in place of what is here.
    package func bringBack(from file: URL) throws {
        let history = try History.bringBack(from: file)
        try history.replace(in: folder, keyName: keyName)
        settings = history.settings
    }

    private func keep() throws {
        try settings.write(in: folder)
        try clips().trim(settings.keeping, now: now())
    }

    private func clips() throws -> Clips {
        try Clips(cheteFolder: folder, keyName: keyName)
    }
}
