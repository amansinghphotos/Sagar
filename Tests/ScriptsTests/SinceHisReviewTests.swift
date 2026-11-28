import Foundation
import Testing

private nonisolated let owner = "amansinghphotos"
private nonisolated let section = "**What Changed Since Your Review:**"

/// Gives the real rules script GitHub's state of a pull request, its description and each person's newest review,
/// and returns whether the owner's part tells him what changed since his review, if he has given one.
private func saysWhatChanged(_ state: URL) throws -> String {
    try Script.run(Script.check, ["since", owner], input: Data(contentsOf: state)).words
}

private func recorded(_ record: String) -> URL {
    Script.repository.appending(path: "Tests/ScriptsTests/Fixtures/\(record).json")
}

/// A recorded state in a temporary file, with its description changed, or with the newest review set to what one
/// person answered.
private func changed(
    _ record: String, description change: (String) -> String = { $0 }, review: (who: String, answer: String)? = nil
) throws -> URL {
    let data = try Data(contentsOf: recorded(record))
    var state = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    state["body"] = change(try #require(state["body"] as? String))
    if let review {
        state["latestReviews"] = [["author": ["login": review.who], "state": review.answer]]
    }
    let file = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
    try JSONSerialization.data(withJSONObject: state).write(to: file)
    return file
}

/// Recorded from GitHub for Chete's menu-bar item, after the owner asked for changes and before he was answered.
@Test func aRequestHeAskedToChangeThatDoesNotSayWhatChangedFails() throws {
    #expect(try saysWhatChanged(recorded("Asked to Change and Not Yet Answered")) == "no\n")
}

/// The description of Chete's settings as the owner approved it, recorded from GitHub. His review is set back to
/// what it was when that description was given back to him: a request for changes.
@Test func theDescriptionHeApprovedPassesWhenGivenBack() throws {
    let givenBack = try changed("Given Back With What Changed", review: (owner, "CHANGES_REQUESTED"))
    #expect(try saysWhatChanged(givenBack) == "yes\n")
}

/// Recorded from GitHub for a pull request the owner has never reviewed: it has nothing to tell him yet.
@Test func aRequestHeNeverReviewedNeedsNoSuchSection() throws {
    #expect(try saysWhatChanged(recorded("Never Reviewed")) == "yes\n")
}

/// The same approved description with the section's line rewritten: left unanswered, or moved out of his part to
/// the end of the agents', where he does not read.
@Test(arguments: [true, false])
func anUnansweredSectionOrOneOutsideHisPartFails(unanswered: Bool) throws {
    let state = try changed(
        "Given Back With What Changed",
        description: { whole in
            let lines = whole.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let rewritten = lines.map { $0.hasPrefix(section) ? (unanswered ? section : "") : $0 }
            return rewritten.joined(separator: "\n") + (unanswered ? "" : "\n\(section) All of it.\n")
        }, review: (owner, "CHANGES_REQUESTED"))
    #expect(try saysWhatChanged(state) == "no\n")
}

/// Made up: his approval was undone by a later push, or he only commented. Either way it is given back to him changed.
@Test(arguments: ["DISMISSED", "COMMENTED"])
func aReviewThatIsNotAStandingApprovalAsksForTheSection(answer: String) throws {
    #expect(try saysWhatChanged(changed("Never Reviewed", review: (owner, answer))) == "no\n")
}

/// Made up: he approved, or the only request for changes is someone else's. The section is his, about his review.
@Test(arguments: [(owner, "APPROVED"), ("someone-else", "CHANGES_REQUESTED")])
func hisApprovalOrAnotherPersonsReviewAsksForNothing(who: String, answer: String) throws {
    #expect(try saysWhatChanged(changed("Never Reviewed", review: (who, answer))) == "yes\n")
}
