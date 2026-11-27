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
        clips = try Clips(folder: folder.appending(path: "Clips"), keyName: keyName)
    }

    /// Copies kept in Chete's own folder on this Mac, sealed by its own key.
    package static func onThisMac() throws -> Copies {
        try Copies(folder: .applicationSupportDirectory.appending(path: "Chete"), keyName: Clips.keyName)
    }

    /// Keeps one copy, unless it holds nothing Chete keeps, or it came from another device and the
    /// settings say to leave those out.
    package func take(_ kinds: [Clip.Kind], fromOtherDevice: Bool, copied: Date, app: String?) throws {
        guard !kinds.isEmpty else { return }
        if fromOtherDevice, try !Settings.read(in: folder).keepsCopiesFromOtherDevices { return }
        var known =
            try known ?? Dictionary(clips.all().map { (try fingerprint($0.kinds), $0.id) }) { newer, _ in newer }
        let print = try fingerprint(kinds)
        let clip = Clip(id: known[print] ?? UUID(), kinds: kinds, copied: copied, app: app)
        try clips.keep(clip)
        known[print] = clip.id
        self.known = known
    }

    private func fingerprint(_ kinds: [Clip.Kind]) throws -> SHA256Digest {
        SHA256.hash(data: try PropertyListEncoder().encode(kinds))
    }
}
