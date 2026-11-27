import Foundation

/// A folder of the person's own things, each a small plain file they can read, move and bring back.
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

    /// The file for a name. A name is one plain word, so it can never reach outside the folder.
    private func file(named name: String) throws -> URL {
        guard !name.isEmpty, !name.contains("/"), !name.contains("..") else { throw StoreError.badName(name) }
        return folder.appending(path: "\(name).json")
    }
}

/// Why the store refused.
package enum StoreError: Error, Equatable {
    case badName(String)
}
