# 5. No Betas

Decided by the owner on 26 November 2026.

**Context.** With betas and a channel switch, it is hard to say which build is the one being tried.

**Decision.** One channel. A finished milestone becomes one signed, notarised build with its own
number, installed on his Mac and held as a draft release. If he approves, that same file is published
by GitHub, which then installs the previous release on a clean Mac and watches it take the update.
If he reports a fault, the build is withdrawn, mended and offered again under the same number: a
number moves only when a release ships.

**Consequences.** "What do I need to test" has one answer or none. An app with a build waiting is
locked until he answers. iPhone apps, later, use TestFlight, which is Apple's only route.
