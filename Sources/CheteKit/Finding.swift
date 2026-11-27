import Foundation

extension [Clip] {
    /// The clips that hold every word typed, in any order, keeping their order, newest first.
    /// Capitals and accents do not matter, so each letter typed can only narrow the list.
    package func found(by typed: String) -> [Clip] {
        let words = typed.split(whereSeparator: \.isWhitespace)
        return filter { clip in
            let held = clip.kinds.map(\.words)
            return words.allSatisfy { word in held.contains { $0.localizedStandardContains(word) } }
        }
    }
}

extension Clip.Kind {
    /// The words a kind is found by: a link by where it goes, a file by its name. A picture has none.
    fileprivate var words: String {
        switch self {
        case .text(let text): text
        case .link(let link): link.absoluteString
        case .file(let file): file.lastPathComponent
        case .picture: ""
        }
    }
}
