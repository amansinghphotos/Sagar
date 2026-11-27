# 9. A Hidden Mac for Trying Tours

Decided by the owner on 27 November 2026.

**Context.** A tour can be tried only on GitHub's runner, 12 to 25 minutes a try. One chat spent over
three hours on a single tour step, one guess per run. The owner: "We can't have tests that are hung up
for hours. That is just a complete waste of development time [...] If we need to go back to using the
virtual Mac on my machine to run some tests, then so be it, but this is not acceptable".

**Decision.** A chat may try a tour in a hidden virtual Mac on the build Mac, made with Apple's
Virtualization framework by a small program of our own. It has no window and no sound, and asks
nothing on his screen. GitHub's runner still judges every pull request, and a tour never runs on his
Mac itself.

**Consequences.** The guest's files, about 40 gigabytes and a 25-gigabyte download to make, live beside
the project, on its drive, never in the repository. One guest serves every chat, one tour at a time,
and stops itself when idle. It runs the newest macOS Apple offers for it, which may differ from
GitHub's runner. This replaces decision 6 for trying tours, and nothing else.
