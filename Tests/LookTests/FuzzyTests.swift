import Testing

@testable import Look

/// What Search's own matcher at c92ea7c answers for each, recorded by running its code: 1 found as typed,
/// 0 found with a slip forgiven, nil not found.
@Test(
    arguments: [
        ("pst", "paste as plain text", nil), ("xlipboard", "clipboard", nil), ("lcipboard", "clipboard", 0),
        ("notifcaton", "notifications", 0), ("ntfcaton", "notifications", nil), ("rpeort", "report", 0),
        ("repxrt", "report", 0), ("rxpxrt", "report", nil), ("cmd", "command", nil), ("repo", "report", 1),
        ("rep", "rxp", nil),
    ] as [(String, String, Int?)])
func findsAsSearchDoes(typed: String, text: String, found: Int?) {
    #expect(Fuzzy.match([Array(typed.utf8)], in: text) == found)
}
