# Sagar

One repository for the owner's Mac apps. This page is all a session needs. `SPEC.md` says why, and
is for changing the platform. The numbers are in `CONSTRAINTS.md`. The app in work is the word in `NOW`.
Nothing about the owner's own Mac belongs here: such notes are kept outside the repository, beside
this folder, in `Sagar Private`.

## Commands

```
Scripts/check                          every rule, and all the testing a change gets; git runs it before a commit
Scripts/check ready <number>           the one way a pull request is shown to the owner and set to merge
Scripts/build <App>                    a signed build of one app
printf 'New: …\nBetter: …\nFixed: …\n' | Scripts/release <App> <version>
                                       try: notarise, install, draft release, release pull request
Scripts/release <App> <version> withdraw  he reported a fault: mend it, then offer the same number again
swift test                             the logic and picture tests
swift format --in-place --recursive Apps Sources Tests Package.swift
```

`gh` and `git push` act as the agents' GitHub App, and git runs `Scripts/check` before every commit.
The session-start hook sets both up.

## When the Owner Says Something

He writes in plain words, in any chat, without naming a file or an issue. Find its place in the pipeline yourself.

- **Which app.** An app is in the repository if it has a folder in `Apps/` and a page in `spec/`. If he
  names one that is not, it is a new app: `Checklists/New App.md`, spec first.
- **A fault** ("X is broken"). If a build of that app is waiting on him, his words are his answer to
  it: `Scripts/release <App> <version> withdraw`, then the fault is the next slice. Otherwise find or
  open an issue in the app's milestone, quoting only what he said about the
  app, and take it as the next slice.
- **A wish** ("I want X"). If a must-have in `spec/<app>.md` names that behaviour, open an issue for
  it, quoted the same way. If none does, it is a change to the spec: one pull request for him to approve, before any code.
- **Another app than the one in `NOW`.** Tell him in a line what is in work, and ask which comes first.
- **A question.** Answer it, and change nothing.
- **His answer to a pull request** is its review on GitHub: an approval, or a request for changes in
  his words. The session start prints it. After a request for changes on a release:
  `Scripts/release <App> <version> withdraw`, mend the fault, then offer the same number again. On
  any other: `gh pr ready <number> --undo` takes it out of his list, then mend it, answer him there
  in plain words, and run step 6 again.

The stop rules below hold for all of these. Use these skills unasked, by step:
`agent-skills:spec-driven-development` (1), `planning-and-task-breakdown` (2),
`incremental-implementation` with `test-driven-development` (3), `git-workflow-and-versioning` (4 and
6), `shipping-and-launch` (7 and 8), and `debugging-and-error-recovery` for a fault. Step 5 is never
yours: the `reviewer` agent reads the diff. A screen or a look is built with `cook` against reference
pictures. The download page is built with `design-taste-frontend`.

## The Eight Steps

1. **Spec.** No code without `spec/<app>.md` approved by the owner on GitHub.
2. **Plan.** One issue per thin slice, in the milestone `<App> <next version>`. Each names its
   must-have and what will prove it: the test, the picture or the tour step, and no more. A wish he
   wants later is kept as an issue with no milestone, and becomes a spec change when its turn comes.
3. **Build.** One slice per session, on a branch named `<issue number>-<words>` and pushed at once,
   which claims the issue. Write the failing test, see it fail, write the code, see it pass.
4. **Pull request.** Open it as a draft, `gh pr create --draft`, which asks nobody. Fill in the template
   honestly. 400 changed lines at most, naming one issue. A changed screen's picture goes under its
   own heading after the owner's part, so that he sees what he is approving.
5. **Review,** once, when the change is finished. Give the `reviewer` agent the diff, the commit
   messages, the issue and the description. Post its reply on the pull request as a comment that
   names the commit it read, folded inside `<details>`. Mend what it says must be mended, in one
   commit; a nit is yours to take or leave. Only a change to the change itself needs a new reading.
   Mend the description's words on GitHub, which costs no commit.
6. **Ready, then merge,** always and only by `Scripts/check ready <number>`. It waits for both
   checks, the code's and the words', and only if they passed does it show the pull request to
   whoever must answer, and set it to merge. Never push after he has approved: it undoes his approval.
7. **Try.** When the milestone is complete: open a Release issue, run `Scripts/release`, and tell the
   owner what to try in three lines. The app is locked until he answers.
8. **Ship.** His approval merges the release pull request, and GitHub publishes it and proves the
   update. Tick the rest of the Release issue when the `release` run is green.

Read `Checklists/Start.md` at the start of a session and `Checklists/Finish.md` at
the end. A new app follows `Checklists/New App.md`. A Mac set up to build follows
`Checklists/Build Mac.md`. `docs/New Mac.md` is for a person who only uses the apps.

## Stop Rules

Stop and ask the owner, as one pull request he can approve, before any of these:

- A change to any path that `.github/CODEOWNERS` gives an owner: a spec, `NOW`, a picture, a release,
  a key, a dependency, a permission. GitHub will not merge it without him.
- A new dependency, a new key or account, a new permission an app asks for.
- Work on an app that `NOW` does not name, or on an app with a release waiting.
- Anything that would put a window, dialog, sound or prompt on his screen.

Never, whatever the reason:

- Commit anything personal: his data, a workplace detail, a key, an e-mail address, a path under his
  home folder. This repository is public.
- Paste code from an older project or from someone else's. Read it for ideas and write fresh. The one
  exception is Look's motion, taken from Search as `spec/look.md` says.
- Force push, reset hard, rewrite pushed history, or commit past the gate.
- Stash, restore, clean or otherwise clear work you did not make in this session. Stop and say so.
- Write a rule as prose. A rule is a check in `Scripts/check`, or it is not written.
- Weaken a check, skip a test, or silence a warning to get to green.
- Mark anything approved. Only his GitHub approval approves.
- Run a tour (`Tour.swift`) on his Mac: it takes the screen. Tours run on GitHub's runner.

## How the Code Is Laid Out

- `Apps/<App>/Main.swift` only starts the app's Kit. Everything else is in `Sources/<App>Kit/`.
- Shared modules exist once an app needs them: Keep, Shell, Taps, Minds. Look is built whole, ahead of need.
- `import AppKit` only in Shell, Taps and a Kit's `Mac/` folder. Network code only in Shell and Minds.
- Screens name roles from Look, never a colour, a font or a size.
- `package` is the widest access, but for the one scene a Kit hands to `Main.swift`, which is `public`.
  Swift 6 mode everywhere.
- Tests use real code and temporary folders. No mocks. Fixtures are made up, or are records of real runs with nothing personal in them.
- A screen's pictures live in `Tests/<Module>Tests/Pictures/`. A new or changed picture needs his
  approval.

## Speaking to the Owner

Three short lines at most, result first, plain English: what was run and what it showed. A decision
of his is one clickable choice, recommendation first. When he must act, give only the next step.
