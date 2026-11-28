# A New App

Chete is the worked example. Issue 13 asked for it. Pull request 14 shows each line below
done: `gh pr diff 14`. Two lines are not in it, and say so.

- [ ] One pull request, approved by the owner, holds every line below but the last.
- [ ] `spec/<app>.md`: what it is for, its must-haves, what it needs from the network, out of scope.
- [ ] Its name, and its identifier `com.amansingh.<app>`, which never changes after the first release.
- [ ] Each permission it will ask for, beside the must-have that needs it.
- [ ] Its must-haves include the first open on a new Mac: earlier work, permissions, the Claude key.
- [ ] Its offline line: "works offline", or exactly what it fetches and why.
- [ ] A deep clean, `Checklists/Deep Clean.md`, has run since the previous app shipped. This pull request shows
      the owner its before and after: he approves the new app and the clean together.
- [ ] `NOW` names it. The previous app has no open slice and no release waiting.
      Chete was the first app, so `NOW` named it already.
- [ ] `CONSTRAINTS.md` has a line budget for `<App>Kit`.
- [ ] `Config/<App>.xcconfig`, its two targets in `Sagar.xcodeproj`, its targets in `Package.swift`.
- [ ] The empty app builds and its tour passes: one window, one test, `Scripts/check` green.
- [ ] `docs/<app>/appcast.xml`, with no release in it, and its entry on the page, `docs/index.html`.
- [ ] After it merges: a milestone `<App> 1.0` with one issue per slice, each naming its must-have.
      Chete's are issues 52 to 62.
