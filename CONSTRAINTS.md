# Constraints

These are the numbers. Each is held by the check named beside it. A change to one is a change to the working
rules: it carries the label `rules` and is read by the reviewer. A number with no check does not
belong here.

## Line Budget

Swift lines in `Sources/<Module>/`, blank lines and comments included. A module without a row fails.
Held by `Scripts/check` budget. The rows are in alphabetical order, held by `Scripts/check` order.

| Module | Lines at most |
|---|--:|
| Each app's Main.swift, which only starts its Kit | 30 |
| CheteKit | 1500 |
| Gallery | 1500 |
| Keep | 300 |
| Look | 6000 |
| Shell | 600 |

## Every Pull Request

| Rule | Number | Held by |
|---|--:|---|
| Changed lines, added plus deleted | 400 | `Scripts/check` size |
| Issues named, exactly (a release names every one it ships) | 1 | `Scripts/check` template |
| Unticked boxes in the description | 0 | `Scripts/check` template |
| Compiler warnings | 0 | `Scripts/check` build |
| `swift format lint --strict` findings | 0 | `Scripts/check` format |
| Apps touched other than the one in `NOW` | 0 | `Scripts/check` scope |
| Pull requests for an app with a release waiting | 0 | `Scripts/check` lock |
| AppKit imports outside Shell, Taps and a Kit's `Mac/` | 0 | `Scripts/check` imports |
| Raw colours or fonts outside Look | 0 | `Scripts/check` look |
| Network code outside Shell and Minds | 0 | `Scripts/check` network |
| Secrets, e-mail addresses, or authors without GitHub's no-reply address | 0 | `Scripts/check` secrets |

## The App in Work, Measured by Its Tour on the Hosted Runner

| Rule | Number | Held by |
|---|--:|---|
| Launch to first frame, fastest of three, by Apple's launch metric, in seconds | 2 | the tour |
| Processor time while its window is hidden and nothing is asked, percent over 10 s | 1 | the tour |
| Accessibility audit findings | 0 | the tour |
| Screens that differ from their approved pictures | 0 | the picture tests |

A screen counts as differing when more than 40 of its pixels differ from the approved picture by more
than 24 of the 255 steps of a colour. Both numbers live in `Tests/Pictures/Pictures.swift`: they
allow for edges smoothed differently on two Macs, and one changed word is far more.
