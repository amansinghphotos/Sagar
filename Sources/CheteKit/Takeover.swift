import CryptoKit
import Foundation
import Keep

/// The history the Chete before this one kept, which comes in once, the first time this Chete opens. It is only
/// read: not a byte of it is changed, moved or deleted.
///
/// How the earlier Chete kept it, learned by reading its code, of which nothing is copied here:
///
/// - Its folder holds `Clips`, the settings in `Yours/Settings.json`, and a log, `Events.jsonl`, which is not
///   part of the history and stays behind.
/// - Each clip is up to three files in `Clips`, named by the clip's id: `<id>.clip`, its record; `<id>.data`, the
///   bytes of each form it was copied in; and `<id>.look`, a small picture for its row, which this Chete does
///   not need. A copied file has no bytes, only where it was.
/// - Each file is sealed with AES-GCM by a 256-bit key kept in the login keychain: the nonce, the sealed bytes
///   and the tag, one after the other, with the id's text bound in, so a file under another clip's name does
///   not open. Inside is a binary property list.
/// - A record says what kind of copy it was (text, link, code, image or file), its words or a link's address,
///   the files' paths, the app's bundle identifier, and when it was last copied. A form is a type, such as
///   public.png, and its bytes.
/// - The settings are JSON: `keepFor`, one of "7 Days", "30 Days", "3 Months", "1 Year" or "Forever", a year
///   when missing; and `copiesFromOtherDevices`, true when missing. A file holding `null` was taken back.
nonisolated package struct EarlierChete: Sendable {
    /// The folder he chose: the earlier Chete's own, or the `Clips` folder inside it.
    package let folder: URL
    /// The earlier Chete's key, handed in from the keychain.
    package let key: SymmetricKey

    package init(folder: URL, key: SymmetricKey) {
        self.folder = folder
        self.key = key
    }

    /// Brings every clip that opens and both settings into Chete's folder, sealed by the key kept under a
    /// name, and says how many came in. A clip already there stays as it is, so bringing in twice adds
    /// nothing. If anything fails before the end, every clip this brought in is taken back out.
    package func bringIn(to cheteFolder: URL, keyName: String) throws -> Takeover {
        let clipsFolder = folder.appending(path: "Clips")
        let found = FileManager.default.fileExists(atPath: clipsFolder.path) ? clipsFolder : folder
        let records = try FileManager.default.contentsOfDirectory(at: found, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "clip" }
        let settingsFile = [folder, folder.deletingLastPathComponent()]
            .map { $0.appending(path: "Yours/Settings.json") }
            .first { FileManager.default.fileExists(atPath: $0.path) }
        guard !records.isEmpty || settingsFile != nil else { throw TakeoverError.noHistory }

        let clips = try Clips(cheteFolder: cheteFolder, keyName: keyName)
        let there = Set(try clips.store.sealedNames())
        var added: [Clip] = []
        var leftOut = 0
        do {
            for record in records {
                // A file that is not named by an id or does not open is left out, and so is a clip with nothing in it.
                guard let id = UUID(uuidString: record.deletingPathExtension().lastPathComponent),
                    let clip = try? clip(id, in: found)
                else {
                    leftOut += 1
                    continue
                }
                guard !there.contains(id.uuidString) else { continue }
                try clips.keep(clip)
                added.append(clip)
            }
            guard leftOut < records.count || records.isEmpty else { throw TakeoverError.wrongKey }
            try settings(in: settingsFile).write(in: cheteFolder)
        } catch {
            for clip in added { try? clips.delete(clip) }
            throw error
        }
        return Takeover(broughtIn: added.count, leftOut: leftOut)
    }

    /// The clip kept under an id, as this Chete keeps it, or nil if it holds nothing this Chete keeps.
    /// A file that does not open is an error.
    private func clip(_ id: UUID, in folder: URL) throws -> Clip? {
        let record = try open(Record.self, folder.appending(path: "\(id.uuidString).clip"), id)
        let formsFile = folder.appending(path: "\(id.uuidString).data")
        let forms =
            FileManager.default.fileExists(atPath: formsFile.path) ? try open([Form].self, formsFile, id) : []
        let kinds = record.kinds(forms)
        return kinds.isEmpty ? nil : Clip(id: id, kinds: kinds, copied: record.copied, app: record.appID)
    }

    private func open<Value: Decodable>(_ type: Value.Type, _ file: URL, _ id: UUID) throws -> Value {
        let box = try AES.GCM.SealedBox(combined: Data(contentsOf: file))
        let plain = try AES.GCM.open(box, using: key, authenticating: Data(id.uuidString.utf8))
        return try PropertyListDecoder().decode(type, from: plain)
    }

    /// The two settings, or the first ones if he never changed them, took them back, or the file is damaged:
    /// as the earlier Chete itself would have read them. This Chete has no three months: the next longer keeps
    /// every clip the earlier one would have kept.
    private func settings(in file: URL?) -> Settings {
        let earlier = file.flatMap { try? JSONDecoder().decode(EarlierSettings?.self, from: Data(contentsOf: $0)) }
        let keeping: [String: Keeping] = [
            "7 Days": .week, "30 Days": .month, "3 Months": .year, "1 Year": .year, "Forever": .forever,
        ]
        var settings = Settings()
        settings.keepsCopiesFromOtherDevices = earlier?.copiesFromOtherDevices ?? settings.keepsCopiesFromOtherDevices
        settings.keeping = earlier?.keepFor.flatMap { keeping[$0] } ?? settings.keeping
        return settings
    }
}

/// What came in: the clips brought in, and those left out because they did not open or held nothing this
/// Chete keeps.
nonisolated package struct Takeover: Equatable, Sendable {
    package let broughtIn: Int
    package let leftOut: Int
}

/// Why nothing came in, and nothing was changed.
nonisolated package enum TakeoverError: Error, Equatable {
    /// The folder holds no earlier history.
    case noHistory
    /// Not one clip came in whole with the key: it is not the earlier Chete's.
    case wrongKey
}

/// What the earlier Chete recorded of each clip that this Chete needs.
nonisolated private struct Record: Decodable {
    let kind: String
    let text: String?
    let files: [String]?
    let appID: String?
    let copied: Date

    /// What it holds, as this Chete takes in a copy: a file alone, or else its words, its formatting, its link
    /// and its pictures. Words that are only the link's address are the link.
    func kinds(_ forms: [Form]) -> [Clip.Kind] {
        if kind == "file" { return (files ?? []).map { .file(URL(filePath: $0)) } }
        let bytes = { (type: String) in forms.first { $0.type == type }?.data }
        let words =
            bytes("public.utf8-plain-text").map { String(decoding: $0, as: UTF8.self) }
            ?? (["text", "code", "link"].contains(kind) ? text : nil)
        let address =
            bytes("public.url").map { String(decoding: $0, as: UTF8.self) }
            ?? (kind == "link" ? text : nil)
        let link = address.flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        var kinds: [Clip.Kind] = []
        if let words, !words.isEmpty, words.trimmingCharacters(in: .whitespacesAndNewlines) != link?.absoluteString {
            kinds.append(.text(words))
        }
        if let rtf = bytes("public.rtf") { kinds.append(.richText(rtf)) }
        if let link { kinds.append(.link(link)) }
        for form in forms where Self.pictures.contains(form.type) {
            kinds.append(.picture(form.data, type: form.type))
        }
        return kinds
    }

    static let pictures: Set = [
        "public.png", "public.jpeg", "public.heic", "com.compuserve.gif", "com.adobe.pdf", "public.tiff",
    ]
}

/// One form a clip was copied in.
nonisolated private struct Form: Decodable {
    let type: String
    let data: Data
}

nonisolated private struct EarlierSettings: Decodable {
    let keepFor: String?
    let copiesFromOtherDevices: Bool?
}
