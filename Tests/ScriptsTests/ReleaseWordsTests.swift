import Foundation
import Testing

/// What the real release script writes to the owner when it asks him to try a build, with an app and a
/// version put in. The Why line is left out: it is that release's own New line, written afresh each time.
private func answersForTheOwner() throws -> [String] {
    let script = URL(filePath: #filePath).appending(path: "../../../Scripts/release").standardizedFileURL
    let lines = try String(contentsOf: script, encoding: .utf8).components(separatedBy: "\n")
    let opening = try #require(lines.firstIndex { $0.hasSuffix("## For the Owner") })
    let closing = try #require(lines[opening...].firstIndex { $0.hasPrefix("<details>") })
    return lines[(opening + 1)..<closing].filter { $0.hasPrefix("**") && !$0.hasPrefix("**Why:**") }.map {
        $0.replacingOccurrences(of: "$app", with: "Chete").replacingOccurrences(of: "$version", with: "1.1")
    }
}

/// SPEC.md, section 8: words are short, warm and plain, and no sentence runs past 12 words.
@Test func aReleaseAsksTheOwnerInShortSentences() throws {
    let answers = try answersForTheOwner()
    #expect(answers.count == 3)
    for answer in answers {
        let said = answer.replacing(/\*\*[^*]+\*\*/, with: "")
        for sentence in said.components(separatedBy: ". ") {
            #expect(sentence.split(separator: " ").count <= 12, "Too long to read at a glance: \(sentence)")
        }
    }
}
