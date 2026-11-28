import Foundation
import Testing

/// Asks the real rules script whether a pull request's description opens with the four answers for the owner.
private func opensForTheOwner(_ description: String) throws -> Bool {
    try Script.run(Script.check, ["plain"], input: Data(description.utf8)).words == "yes\n"
}

private nonisolated func description(does: String, why: String = "You asked for it.", apps: String = "No.") -> String {
    """
    Closes #3

    ## For the Owner

    **What This Does:** \(does)

    **Why:** \(why)

    **Does It Change Your Apps?** \(apps)

    **What to Do:** Approve if you want this.

    <details><summary>Checklist for the Agents</summary>

    - [x] `Scripts/check` is green on my machine.

    </details>
    """
}

@Test func fourShortAnswersPass() throws {
    #expect(try opensForTheOwner(description(does: "The window now remembers its size.")))
}

@Test(arguments: [
    "Closes #3\n\nNo part for the owner at all.",
    description(does: ""),
    description(does: "It works.", why: ""),
    description(does: "This changes `the check` to skip the tour."),
    description(does: "The file Sources/Shell/Updates.swift now starts the updater."),
    description(does: "The feed is appcast.xml now."),
    "Closes #3\n\n## For the Owner\n\n**What This Does:** It works.\n\n**Why:** Asked.\n",
])
func aMissingUnansweredOrTechnicalOpeningFails(description: String) throws {
    #expect(try !opensForTheOwner(description))
}

/// A request is public, so its words are held to the same rule as the files: nothing that gives a person away.
/// The address and the path are put together here so that this file itself holds neither.
@Test(arguments: ["Write to someone" + "@" + "mail.test about it.", "It is kept in /" + "Users/" + "someone/Desktop."])
func aDescriptionThatHoldsAnAddressOrAHomeFolderFails(telling: String) throws {
    #expect(try !opensForTheOwner(description(does: "The window now remembers its size.") + "\n\n" + telling))
}
