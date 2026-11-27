import CryptoKit
import Foundation

/// Takes each new copy in as a clip, away from the screen, so that a large history never slows it.
/// The same thing copied again stays one clip and moves to the top.
package actor Copies {
    private let folder: URL
    private let clips: Clips
    /// Each clip's id, found by a fingerprint of what it holds. It lives only in memory, and is
    /// made from the history the first time something is copied.
    private var known: [SHA256Digest: UUID]?

    /// Copies kept in Chete's folder: clips in Clips, sealed by the key under a name, and the settings beside them.
    package init(folder: URL, keyName: String) throws {
        self.folder = folder
        clips = try Clips(cheteFolder: folder, keyName: keyName)
    }

    /// Copies kept in Chete's own folder on this Mac, sealed by its own key.
    package static func onThisMac() throws -> Copies {
        try Copies(folder: .applicationSupportDirectory.appending(path: "Chete"), keyName: Clips.keyName)
    }

    /// Keeps one copy, unless it holds nothing Chete keeps, or it came from another device and the
    /// settings say to leave those out.
    @discardableResult
    package func take(_ kinds: [Clip.Kind], fromOtherDevice: Bool, copied: Date, app: String?) throws -> Clip? {
        guard !kinds.isEmpty else { return nil }
        if fromOtherDevice, try !Settings.read(in: folder).keepsCopiesFromOtherDevices { return nil }
        var known =
            try known ?? Dictionary(clips.all().map { (try fingerprint($0.kinds), $0.id) }) { newer, _ in newer }
        let print = try fingerprint(kinds)
        let clip = Clip(id: known[print] ?? UUID(), kinds: kinds, copied: copied, app: app)
        try clips.keep(clip)
        known[print] = clip.id
        self.known = known
        return clip
    }

    /// Every clip kept, newest first.
    package func all() throws -> [Clip] {
        try clips.all()
    }

    /// Every clip kept, read afresh after Settings deleted or brought back clips, newest first.
    package func reread() throws -> [Clip] {
        known = nil
        return try clips.all()
    }

    /// Deletes every clip copied longer ago than the settings say to keep things, and says which went.
    @discardableResult
    package func trim(now: Date = .now, calendar: Calendar = .current) throws -> [Clip] {
        try clips.trim(Settings.read(in: folder).keeping, now: now, calendar: calendar)
    }

    private func fingerprint(_ kinds: [Clip.Kind]) throws -> SHA256Digest {
        SHA256.hash(data: try PropertyListEncoder().encode(kinds))
    }
}

extension Copies {
    /// The name, in the environment Chete is opened with, of an exported history for a tour to open it on.
    package static let tourHistory = "CHETE_TOUR_HISTORY"

    /// The copies Chete opens on: those kept on this Mac. A tour names an exported history of made-up clips in
    /// the environment instead, and Chete then opens on a copy of it, kept in a temporary folder of its own.
    /// The history kept on this Mac is then neither read nor changed. The key's name is for that copy alone.
    package static func atOpen(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        temporary: URL = .temporaryDirectory.appending(path: "Chete Tour \(UUID().uuidString)"),
        keyName: String = Clips.keyName
    ) throws -> Copies {
        guard let file = environment[tourHistory] else { return try onThisMac() }
        try History.bringBack(from: URL(filePath: file)).replace(in: temporary, keyName: keyName)
        return try Copies(folder: temporary, keyName: keyName)
    }
}
