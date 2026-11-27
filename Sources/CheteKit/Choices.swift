import Foundation

/// What you choose in Chete's settings, kept as you choose it, and the things you can do to your history
/// there: delete it all, export it, and bring it back.
@Observable
package final class Choices {
    private let folder: URL
    private let keyName: String
    private let now: () -> Date
    /// Told each time clips are deleted or brought back, so the list can show what is kept now.
    private let changed: () -> Void

    /// Kept the moment it changes. A shorter time to keep things deletes what is older at once.
    package var settings: Settings {
        didSet { attempt { try keep() } }
    }
    /// What went wrong the last time, in words, until something works.
    package var failure: String?

    /// The choices kept in Chete's folder, whose clips are sealed by the key under a name.
    package init(
        folder: URL, keyName: String, now: @escaping () -> Date = { .now }, changed: @escaping () -> Void = {}
    ) {
        self.folder = folder
        self.keyName = keyName
        self.now = now
        self.changed = changed
        do {
            settings = try Settings.read(in: folder)
        } catch {
            settings = Settings()
            failure = "Couldn’t read your settings, so Chete went back to the usual ones."
        }
    }

    /// The choices in Chete's own folder on this Mac.
    package static func onThisMac(changed: @escaping () -> Void) -> Choices {
        Choices(folder: .applicationSupportDirectory.appending(path: "Chete"), keyName: Clips.keyName, changed: changed)
    }

    /// Does something, and says so if it did not work.
    package func attempt(_ work: () throws -> Void) {
        do {
            try work()
            failure = nil
        } catch {
            failure = "That didn’t work. \(error.localizedDescription)"
        }
    }

    /// Deletes every clip. The settings stay.
    package func deleteAll() throws {
        try clips().deleteAll()
        changed()
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
        changed()
    }

    private func keep() throws {
        try settings.write(in: folder)
        try clips().trim(settings.keeping, now: now())
        changed()
    }

    private func clips() throws -> Clips {
        try Clips(cheteFolder: folder, keyName: keyName)
    }
}
