import Foundation

/// A folder of the person's own things, each a small file they can move and bring back: plain, so they
/// can read it, or sealed, so that only this Mac's keychain opens it.
package struct Store: Sendable {
    /// Where the files live.
    package let folder: URL

    /// A store in the given folder, which is made when something is first written.
    package init(folder: URL) {
        self.folder = folder
    }

    /// Reads the value saved under a name, or nil if nothing was ever saved there.
    /// A file that cannot be understood is an error, never a silent fresh start.
    package func read<Value: Decodable>(_ type: Value.Type, named name: String) throws -> Value? {
        let file = try file(named: name)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try JSONDecoder().decode(type, from: Data(contentsOf: file))
    }

    /// Saves a value under a name, whole or not at all.
    package func write(_ value: some Encodable, named name: String) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(value).write(to: try file(named: name), options: .atomic)
    }

    /// Reads the value sealed under a name, or nil if nothing was ever sealed there.
    package func read<Value: Decodable>(_ type: Value.Type, named name: String, sealedBy seal: Seal) throws -> Value? {
        let file = try file(named: name, sealed: true)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try PropertyListDecoder().decode(type, from: seal.open(Data(contentsOf: file)))
    }

    /// Seals a value and saves it under a name, whole or not at all. Nobody can read the file without the key.
    package func write(_ value: some Encodable, named name: String, sealedBy seal: Seal) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try seal.seal(encoder.encode(value)).write(to: try file(named: name, sealed: true), options: .atomic)
    }

    /// The name of every sealed value in the folder.
    package func sealedNames() throws -> [String] {
        guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "sealed" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    /// The file for a name. A name is one plain word, so it can never reach outside the folder.
    private func file(named name: String, sealed: Bool = false) throws -> URL {
        guard !name.isEmpty, !name.contains("/"), !name.contains("..") else { throw StoreError.badName(name) }
        return folder.appending(path: sealed ? "\(name).sealed" : "\(name).json")
    }
}

/// Why the store refused.
package enum StoreError: Error, Equatable {
    case badName(String)
}
