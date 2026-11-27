// Finding typed words in a line of text, just as typed or with a slip of the fingers forgiven.

/// Matches what was typed against a line of text, byte by byte over UTF-8, forgiving a slip of the fingers.
/// Both sides are expected in lower case.
nonisolated package enum Fuzzy {
    /// Whether every typed word is in `text`: 1 when each is there just as typed, 0 when one is there only with a
    /// slip, and nil when one is not there at all. A list shows the first
    /// kind before the second.
    package static func match(_ typed: [[UInt8]], in text: String) -> Int? {
        var text = text
        return text.withUTF8 { bytes in
            var exact = 1
            for word in typed where !contains(bytes, word) {
                guard nearly(word, in: bytes) else { return nil }
                exact = 0
            }
            return exact
        }
    }

    /// Whether `word` lies anywhere in `text`. An empty word lies everywhere.
    package static func contains(_ text: UnsafeBufferPointer<UInt8>, _ word: [UInt8]) -> Bool {
        guard !word.isEmpty else { return true }
        guard word.count <= text.count else { return false }
        return (0...(text.count - word.count)).contains { at in holds(text, word, at: at) }
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
        let forgiven = typed.count < 4 ? 0 : typed.count < 8 ? 1 : 2
        guard forgiven > 0 else { return false }
        return words(of: text).contains { slice in
            let word = Array(slice)
            guard word.count >= 2, word.count >= typed.count - forgiven else { return false }
            let firstRight = word[0] == typed[0] || (word[0] == typed[1] && word[1] == typed[0])
            return firstRight && slips(typed, word) <= forgiven
        }
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
