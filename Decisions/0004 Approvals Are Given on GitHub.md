# 4. Approvals Are Given on GitHub

Decided by the owner on 26 November 2026.

**Context.** An approval is worth something only if it cannot be given by mistake and leaves a
record. A word in a chat does neither.

**Decision.** His yes is an approval of a pull request from his own GitHub account. `CODEOWNERS` and a
ruleset on `main` require it for his decisions: specs, `NOW`, approved pictures and the look, releases
and all that is served to people, signing, keys, dependencies and permissions. Agents work as a GitHub App that can push branches and open pull requests, and has no admin
rights. His own sign-in is kept out of any terminal an agent can reach.

**Consequences.** His pending approvals are the one list of what waits on him. A release is a pull
request that changes a feed. A change to the working rules is checked without him and carries the label `rules`. Changing GitHub's
own settings needs him, in his browser.
