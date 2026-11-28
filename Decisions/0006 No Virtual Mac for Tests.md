# 6. No Virtual Mac for Tests

Decided by the owner on 26 November 2026. Decision 10 overrules it for trying a tour, which may be done in a
hidden Mac; GitHub's runner still judges.

**Context.** Driving apps inside a virtual Mac keeps tests off the screen, but it takes thousands of
lines and more than a hundred gigabytes, and becomes a product of its own.

**Decision.** No virtual Mac. Logic is tested with Swift Testing. Screens are pictured from a window
that is never put on screen. One XCUITest tour per app runs on GitHub's hosted runner. What needs a
permission or his hardware, he tries when a build is installed.

**Consequences.** A tour never runs on his Mac. An app that needs a permission is not toured past the
point where the permission is asked.
