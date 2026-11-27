// Finding typed words in a line of text, just as typed or forgiven: as a word's short form, or with one
// letter wrong.

/// Matches what was typed against a line of text, byte by byte over UTF-8, forgiving a short form and one slip
/// of the fingers. Both sides are expected in lower case.
nonisolated package enum Fuzzy {
    /// Whether every typed word is in `text`: 1 when each is there just as typed, 0 when one is there only as a
    /// word's short form or with a letter wrong, and nil when one is not there at all. A list shows the first
    /// kind before the second.
    package static func match(_ typed: [[UInt8]], in text: String) -> Int? {
        var text = text
        return text.withUTF8 { bytes in
            var exact = 1
            for word in typed where !contains(bytes, word) {
                guard shortens(word, bytes) || nearly(word, in: bytes) else { return nil }
                exact = 0
            }
            return exact
        }
    }

    /// Whether a word of `text` starts with `typed` but for one letter wrong, missing, added, or swapped with
    /// the next. Words shorter than four letters are never forgiven, since one slip in so few letters could be
    /// almost anything.
    package static func nearly(_ typed: [UInt8], in text: String) -> Bool {
        var text = text
        return text.withUTF8 { nearly(typed, in: $0) }
    }

    /// Whether `typed` is a short form of `word`: it starts with the word's first letter, and the rest of its
    /// letters come in the word in the same order, as "cmd" stands for "command".
    package static func abbreviates(_ typed: some StringProtocol, _ word: some StringProtocol) -> Bool {
        let typed = Array(typed.lowercased())
        let word = Array(word.lowercased())
        guard let first = typed.first, first == word.first, typed.count <= word.count else { return false }
        var next = 0
        for letter in word where next < typed.count && letter == typed[next] {
            next += 1
        }
        return next == typed.count
    }

    /// Whether `word` lies anywhere in `text`. An empty word lies everywhere.
    package static func contains(_ text: UnsafeBufferPointer<UInt8>, _ word: [UInt8]) -> Bool {
        guard !word.isEmpty else { return true }
        guard word.count <= text.count else { return false }
        return (0...(text.count - word.count)).contains { at in holds(text, word, at: at) }
    }

    /// Whether `word` lies in `text` at the start of one of its words.
    package static func startsWord(_ word: [UInt8], in text: UnsafeBufferPointer<UInt8>) -> Bool {
        guard !word.isEmpty else { return true }
        guard word.count <= text.count else { return false }
        return (0...(text.count - word.count)).contains { at in
            (at == 0 || !inWord(text[at - 1])) && holds(text, word, at: at)
        }
    }

    /// Whether `word` lies in `text` from `at` on.
    private static func holds(_ text: UnsafeBufferPointer<UInt8>, _ word: [UInt8], at: Int) -> Bool {
        word.indices.allSatisfy { text[at + $0] == word[$0] }
    }

    /// Whether a byte belongs to a word: a letter or a figure, or any part of a letter beyond plain ASCII.
    private static func inWord(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "A")...UInt8(ascii: "Z"),
            UInt8(ascii: "0")...UInt8(ascii: "9"), 0x80...:
            true
        default: false
        }
    }

    /// The same, over the text's bytes.
    private static func nearly(_ typed: [UInt8], in text: UnsafeBufferPointer<UInt8>) -> Bool {
        guard typed.count >= 4 else { return false }
        return words(of: text).contains { word in slips(typed, Array(word)) <= 1 }
    }

    /// Whether `typed` is a short form of a word of `text`.
    private static func shortens(_ typed: [UInt8], _ text: UnsafeBufferPointer<UInt8>) -> Bool {
        guard typed.count >= 2 else { return false }
        let short = String(decoding: typed, as: UTF8.self)
        return words(of: text).contains { word in abbreviates(short, String(decoding: word, as: UTF8.self)) }
    }

    /// The words of `text`, as runs of the bytes that belong to words.
    private static func words(of text: UnsafeBufferPointer<UInt8>) -> [Slice<UnsafeBufferPointer<UInt8>>] {
        text.split(whereSeparator: { !inWord($0) })
    }

    /// The fewest slips that turn `typed` into the start of `word`: a letter wrong, missing, added, or two
    /// neighbours swapped each count one. The table's rows are the letters typed, its columns the word's.
    private static func slips(_ typed: [UInt8], _ word: [UInt8]) -> Int {
        let width = word.count + 1
        var table = [[Int]](repeating: [Int](repeating: 0, count: width), count: typed.count + 1)
        for row in 0...typed.count { table[row][0] = row }
        for column in 0..<width { table[0][column] = column }
        for row in stride(from: 1, through: typed.count, by: 1) {
            for column in stride(from: 1, to: width, by: 1) {
                let same = typed[row - 1] == word[column - 1]
                var best = min(
                    table[row - 1][column] + 1, table[row][column - 1] + 1,
                    table[row - 1][column - 1] + (same ? 0 : 1))
                if row > 1, column > 1, typed[row - 1] == word[column - 2], typed[row - 2] == word[column - 1] {
                    best = min(best, table[row - 2][column - 2] + 1)
                }
                table[row][column] = best
            }
        }
        // Typing may stop short of the word's end, so any start of the word will do.
        return table[typed.count].min() ?? typed.count
    }
}
