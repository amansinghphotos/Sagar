# 9. Audit Findings Are Reported, Not Failing

Decided by the owner on 27 November 2026.

**Context.** Apple's accessibility audit failed Chete's tour whenever its find field held the keyboard,
though the field looked right, and Apple says nothing about the finding (#98). Asked about it, he said:
"I don't think you need to worry about the voiceover and accessibility stuff right now. We can add that
in later [...] Right now, the app is only made for me, my girlfriend, and my family, and they don't have
any special needs in that sense."

**Decision.** Every tour still runs the audit. Its findings are written into the run's summary, but they
fail nothing, until he says to bring that back. Every other check in a tour still fails it.

**Consequences.** Look's must-have 5, keyboard and VoiceOver everywhere, stands but is not proven for
now. Coming back to it is #252: once a hidden virtual Mac is on the external drive, try again; if it
still fights, it stays pinned. Turning it back on is one line in each app's tour.
