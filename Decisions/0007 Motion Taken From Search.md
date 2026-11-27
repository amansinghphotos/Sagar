# 7. Motion Taken From Search

Decided by the owner on 26 November 2026.

**Context.** How a thing moves is a handful of exact numbers: a spring's response and damping, a
duration, how far a press gives. Filming another app does not recover them, and Search's were tuned
frame by frame against other browsers on a real Mac. Search is MIT licensed.

**Decision.** Look takes Search's motion word for word, as `spec/look.md` says, and keeps Search's
copyright line and permission notice in `ACKNOWLEDGEMENTS.md` and in each app's About window. The parts
themselves are measured and written fresh.

**Consequences.** One exception to "none is pasted", named and bounded. Later changes in Search are not
taken by themselves: each is a pull request of its own.
