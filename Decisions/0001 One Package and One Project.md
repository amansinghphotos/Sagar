# 1. One Package and One Project

Decided by the owner on 26 November 2026.

**Context.** Apps share most of their code. SwiftPM builds and tests modules but cannot make a signed
app bundle. A package per module makes every shared symbol `public` and multiplies manifests. A
project per app repeats the same settings in every app.

**Decision.** One `Package.swift` holds every module and its tests. One `Sagar.xcodeproj`, in Xcode's
JSON format, holds one thin target per app and one tour per app. Settings live only in `Config/`.

**Consequences.** `package` access reaches across modules, so almost nothing is `public`. One
`swift test` covers everything. Both files are the owner's: a new module or app needs his
approval.
