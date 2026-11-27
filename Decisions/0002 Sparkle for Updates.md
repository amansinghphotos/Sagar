# 2. Sparkle for Updates

Decided by the owner on 26 November 2026.

**Context.** Apple offers no updater outside the App Store. Writing one means about 600 lines of
security code that nobody outside would review. Most small Mac apps use Sparkle, whose flaws are found
and fixed in public.

**Decision.** Sparkle 2, pinned to an exact version in `Package.swift`, is the one approved
third-party dependency. Only Shell imports it. Each app's feed is `docs/<app>/appcast.xml`, signed
with the update key on the owner's Mac. No delta files and no channels.

**Consequences.** A newer Sparkle is a pull request the owner approves. A release reaches people only
when the feed changes, and the feed changes only with his approval. The keychain trusts Sparkle's
signing tools by their exact build, so a newer Sparkle asks him once to use the update key.
