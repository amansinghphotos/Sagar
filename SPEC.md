# Sagar: The Specification

Sagar (ਸਾਗਰ, the ocean) is one repository where the owner's apps are specified, written, checked and
released the same way every time. The owner approved this plan on 26 November 2026. He decides what
each app is for, how it looks, what it costs and anything that is his. Agents do the building, inside
the rules below.

## 1. What It Guards Against

| What It Prevents | The guard | Held by |
|---|---|---|
| Several apps in work at once | One app in work, named in `NOW`. A pull request that touches another app fails, unless it mends a fault in a shipped app. Look's shared parts are not an app. | A check, and his approval to change `NOW` |
| More builds waiting than he can try | One build waits for him at a time. It locks its app: its other pull requests fail until he answers. | A check |
| Home-made tools where standard ones exist | Standard tools only: Xcode, Swift Testing, XCUITest, GitHub issues, pull requests and Actions, Sparkle. | His approval of any dependency |
| Work scattered, with no one record | Every change is a pull request of 400 changed lines at most that names one issue. Branches are deleted on merge. Status is the milestone page. | GitHub settings and a check |
| The look changing unseen | The token file and the approved pictures change only with his approval. The Gallery's pictures are checked against Search's instead. | His approval |
| Rules that nothing enforces | A rule is a required check on `main`, or it is not written. | GitHub |
| Checks added after features | An empty app goes through every gate, release and update included, before any feature. | Order of work |
| A spec approved by anyone but him | A spec merges only with his approval, which agents cannot give. | His approval |

His word is given in two places. In the chat he reports a fault, asks for something or asks a question.
On a pull request he answers with its review: he approves, or he asks for changes in his own words.

"His approval" is a GitHub approval from his own account. Agents work as a GitHub App with no admin
rights, which cannot approve for him. He approves his decisions and only those: what an app must do,
how a screen looks, each release, and anything involving money, keys or an outside dependency
(`.github/CODEOWNERS` is the list). A change to the working rules is checked by GitHub's Mac and the
reviewer, and carries the label `rules`, so he can read every one of them in one list at any time.
His pending approvals are the only list of things waiting on him.

## 2. Principles

1. Simple beats complete. A part that needs explaining twice is removed.
2. He is asked for a yes on each app's must-have list, on a change to the look, on each release, and
   on anything that involves money, a key, a dependency or a permission. Everything else is decided
   and reported in a line. Agents merge ordinary work themselves once checks are green.
3. What Apple provides is used as Apple intends. A dependency needs his yes and a decision record.
4. Every line is written fresh, test first. Other code is read for ideas, and none is pasted.
5. Shared code is written when the first app needs it, not ahead of need.
6. Built to last. The method lives in plain Markdown, git, shell and GitHub's oldest features. The
   Claude layer is thin and only points at those files. Apps work offline unless their spec names what
   they need from the network.
7. Checklists, as in aviation: every repeated procedure is a short list that is read every time.

Until Look's first set of parts is approved, decision 7 sets principle 5 aside for Look alone.

## 3. The Repository

```
README.md  SPEC.md  CONSTRAINTS.md  CLAUDE.md  NOW
Package.swift          every module and its tests
Sagar.xcodeproj        one thin target per app and one tour per app
Config/                Shared.xcconfig, <App>.xcconfig, Info.plist, Export.plist
Apps/<App>/            Main.swift, Tour.swift, assets, entitlements
Sources/Look/          tokens, themes, components (pure SwiftUI)
Sources/Keep/          his settings and data as plain files, export, import, sealing, event log
Sources/Shell/         what every Mac app repeats: settings, permissions, login item, updates
Sources/Taps/          event taps and C callbacks as streams
Sources/Minds/         speech and language models behind one interface
Sources/<App>Kit/      one app's feature; Mac-only files under Mac/
Tests/<Module>Tests/   Swift Testing; approved pictures under Pictures/
spec/<app>.md          what it is for, must-haves, network needs, out of scope
spec/look.md           every part of the look, its two themes and its motion
docs/                  what is served to people: the download page, each app's update feed, New Mac.md
Checklists/            every repeated procedure, read every time
Decisions/             why things are the way they are
.claude/               settings, two hooks, one reviewer agent
.github/               check.yml, release.yml, CODEOWNERS, the two templates, the rulesets
Scripts/               check, build, release
```

A module exists once an app needs it. AppKit is allowed only in Shell, Taps and a Kit's `Mac/` folder.
Network code is allowed only in Shell (updates) and Minds. Windows adapt by container width, and each
screen is pictured narrow, default and wide.

## 4. The Pipeline, the Same for Every Change

1. **Spec.** `spec/<app>.md` arrives as a pull request. He approves it on GitHub.
2. **Plan.** The spec becomes issues in one GitHub milestone, one thin slice each.
3. **Build.** A fresh session per slice: a failing test, the code, the test passing.
4. **Pull request,** naming its issue: "For" one in a milestone, which its release closes, and
   "Closes" for any other. `Scripts/check` runs on a clean macOS 27 runner.
5. **Review.** A reviewer agent that can only read files checks the diff against the spec and
   `CONSTRAINTS.md`.
6. **Merge** with green checks, squashed, branch deleted.
7. **Try.** When a milestone is complete, `Scripts/release <App> <version>` installs one signed and
   notarised build on his Mac, holds the same file as a draft release, and opens the release pull
   request. If the app was open, it is quit and opened again, and shows what is new (section 5)
   without taking his keyboard. If it was closed, or will not quit, it shows that when he next opens
   it. That reopening is the one window a release puts on his screen, by his choice. He is told what
   to try in three lines. The app is now locked.
8. **Ship.** He approves the release pull request, and that is all. GitHub merges it, makes that same
   file public, and on a clean Mac installs the previous release and watches it take the update. If he
   reports a fault instead, the release is withdrawn, the fault is fixed, and step 7 repeats under the
   same number.

The checklists in `Checklists/` and `.github/` are read every time. A session's start prints the
first of them, and a release will not start while its own has a box unticked.

## 5. Versions, Updates and Faults

- One channel. No betas and no switch: the build he tries is the file that ships.
- A version has two numbers, and moves only when a release ships: 1.0, 1.1, 1.2, whether it adds or
  mends. A build he sends back is mended and offered again under the same number, so people who had
  1.3 next see 1.4. The date stamp in the About window tells one try from the next.
- The first number changes, to 2.0, only when an app cannot open the previous version's files without
  converting them, or drops a must-have. That is his call each time.
- There is no third number: every copy is offered each update, so no old version is ever mended. Under the
  version each build carries its commit's date and time, which always rises and is what Sparkle compares.
- One build waiting for him at a time, and one app in work.
- Each GitHub release carries three plain lines: New, Better, Fixed.
- A fault he describes becomes an issue, and the release that mends it says so in plain words. An
  app's issue stays open until he approves that release: an open issue means not yet confirmed by him.
- An update is always offered and never forced or silent: the app shows what is new and the person
  chooses to install it, to be reminded later, or to skip that version.
- The first time an app's window opens on a new build, it shows Look's card for what is new, once,
  with that release's three lines. On his Mac it tells him a build to try is in place and what to
  look for. For everyone else it follows the update. A mended build under the same number shows it
  again. An app's very first open shows its welcome instead.
- Sparkle checks daily. A published release is never taken back: a bad one is mended, or the last
  good code is released again, under the next number.
- Before a release an agent confirms it opens the files the previous release wrote, and ticks that
  in the Release issue. After his approval GitHub's Mac installs the previous release and watches it
  take the update.

### Mending a Shipped App

A fault in a shipped app is mended beside the app in work, and `NOW` stays as it is. (`Scripts/check`
scope)

- His report is enough to start. The fault becomes an issue marked `fault`, in the milestone for the
  app's next number. Only its branch may touch the shipped app. (`Scripts/check` scope)
- That milestone holds faults only. Nothing new reaches a shipped app until `NOW` names it again.
  (`Scripts/check` scope and `Scripts/release`)
- The mend is made on `main`, like any slice. GitHub's Mac tours that app too, as well as the app in
  work. (`Scripts/check` tour)
- Its release is tried and shipped like any other. It waits only while another build waits for him.
  (`Scripts/release`)
- It locks only the app it mends, so the app in work never waits for it. (`Scripts/check` lock)

## 6. Keys

Five keys, each kept in the owner's Passwords under a name that begins with "Sagar", with a note that
says what it is for. A new Mac gets each one in one of two ways: iCloud Keychain carries it, or he
pastes it from Passwords once. A key is never made anew for a new Mac. Signing stays on his Mac, so
GitHub holds no signing secret. His sign-ins to Apple, Claude and GitHub are passwords, not keys, and
his GitHub sign-in stays in his browser and phone, never in a terminal an agent can reach.

| In Passwords | What it is for | If it is lost | A new Mac |
|---|---|---|---|
| Sagar · Update Key | Proves each update comes from him: every installed copy checks it | No installed copy can update again | He pastes it once |
| Sagar · Developer ID | Apple's signature on each app, without which a Mac will not open it | He makes a new one in Xcode | He pastes it once |
| Sagar · Apple Notary | Lets Apple check each build before anyone downloads it; on a Mac it is the notary profile named Sagar | He makes a new one on his Apple Account | iCloud Keychain |
| Sagar · Agents' GitHub Key | The agents' own GitHub identity, never his | He generates a new one on the app's page | He pastes it once |
| Sagar · Claude API Key | Lets an app talk to Claude; made when the first such app asks for it | He makes a new one on Claude's site | iCloud Keychain |

These five are all that signing, publishing and updating need, and none can stand in for another.
The update key and the Developer ID live in the login keychain, which does not sync, so those two,
and the agents' key, are pasted.

One Claude API key serves every app. The first app that talks to Claude asks for it once and keeps it
in Apple's shared keychain group for his team, which iCloud Keychain carries to his other Macs. An app
that does not talk to Claude never asks. This is built with the first app that needs it.

## 7. Tests

1. Logic: Swift Testing, written first, on real code with temporary folders.
2. Screens: pictures taken from a real window that is never put on screen, compared with approved
   pictures.
3. The real app: one XCUITest tour per app on the hosted runner, with an accessibility audit, where
   the app needs no permission.
4. What needs a permission or his hardware he tries at step 7.

## 8. The Look and the Words

`spec/look.md` says what Look holds: two themes, Modern and Lexicon, over one set of parts, with
Search's motion. Modern is Search's look exactly, proved part by part against Search's own pictures.

Every app's words are written the way a friendly person would say them: short, warm and plain. One
idea to a sentence, everyday words, "you" for the reader, and contractions where they sound natural.
A label says plainly what it is, and the line under it says what you will notice, never how it works.
This holds for every app and every part they share. That means windows, settings, first open, menus,
alerts, updates, About, the download page and the release notes.

What can be counted becomes a check in `Scripts/check`, with its numbers in `CONSTRAINTS.md`: no
sentence an app shows runs past 12 words, and none uses a listed stock word, such as "seamlessly".
Until that check is built, the reviewer holds both. Whether words are warm and easy to read is judged
by the reviewer on every change, and by him on each picture.

## 9. Boundaries

- **Always:** a test first; `Scripts/check` green before a commit; one issue per pull request.
- **His approval first:** `spec/`, `NOW`, approved pictures and the token file, releases and all that
  is served to people, signing and keys, a dependency, a permission. `.github/CODEOWNERS` is the list.
- **Checked without him:** the working rules, which are the scripts, checks, hooks, checklists and
  numbers. Such a change carries the label `rules` and is read by the reviewer.
- **Never:** anything personal in this repository (his data, a workplace detail, a key, an e-mail
  address); a force push; a line pasted from another project; a window on his screen unasked.

## 10. Honest Limits

GitHub enforces the checks and his approvals: the rules on `main` are written in `.github/rulesets/`.
Spec-first and test-first order inside a slice rest on the instructions and the reviewer. A pull
request that changes a check runs its own new version, and is read by the reviewer, not by him.

Launch is judged by the fastest of three launches on GitHub's Mac. That shows what the code costs,
not how an app feels on its very first open after an install, which he judges when he tries a build.

The guards catch honest mistakes, not deliberate ones. The agents' app may push workflow files, so a
branch could carry a workflow that reports a pass it did not earn. The network rule reads for the
usual calls and cannot see every way to fetch a file.

## 11. Written When the First App Needs It

Look, with its Gallery target and a check that it also compiles for iPhone. Keep. Shell's settings
window, permissions, login item, menu bar, hot keys and Send Report. Taps and Minds.

Contrast will be a number on Look's colour roles, worked out from their values. The tour's audit leaves
contrast out: GitHub's screen has one pixel a point, and there the audit fails plain black text on white.
