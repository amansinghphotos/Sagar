# 3. A Public Repository

Decided by the owner on 26 November 2026.

**Context.** GitHub enforces required checks, code owners and rulesets on a free account only for a
public repository. Release files and the update feed must be public for family to download.

**Decision.** `amansinghphotos/Sagar` is public and holds code, releases, the download page and the
feeds.

**Consequences.** Nothing personal is ever committed: no data of the owner's, no workplace detail, no
key, no e-mail address, no path under his home folder. Commits carry GitHub's no-reply address.
`Scripts/check` and GitHub's secret scanning both look. Notes about anyone's own equipment stay out.

## Looked at Again on 27 November 2026 (Issue 12)

**Question.** Before an app that handles spoken words, should the code be private while the downloads
stay public?

**Read that day,** from GitHub's own pages: Actions billing, runner pricing, its plans, the plans FAQ,
releases, Pages, rulesets and secret scanning.

- Standard hosted runners, the Mac included, are free for a public repository.
- For a private one, a Mac minute costs $0.062 and a Linux minute $0.006. Each job is rounded up to
  a whole minute.
- GitHub Pro costs $4 a month and includes $18 of Actions use, about 290 Mac minutes. For private
  repositories it adds protected branches, code owners, required reviewers and Pages. The rulesets
  page names only Team and Enterprise, so the tag rules on Pro are unconfirmed.
- Only people who can read a repository can see its releases, so people without access could not
  download from a private one.
- A Pages site stays public even when its repository is private.
- Secret scanning is free for public repositories only, so a private one keeps just `Scripts/check`'s look.

**Measured.** The repository's first day, 27 November from 03:47 to 17:07 UTC, about twenty chats at
once: 280 code checks on GitHub's Mac, about 1,611 minutes, with a passing check at 7.6 minutes in the
middle; and 384 word checks on Linux, a minute each once rounded.

**What private would cost.** A day like that is about $100 of Mac time. If every day were as busy, that
is about $3,000 a month; at a tenth of that pace, about $300. Pro adds $4 and takes $18 off. Running the checks on his own Mac would be free, but
tours take the screen, which the rules forbid.

**What private would rebuild.** On Pro, the feeds and the download page can stay here, served by Pages.
Only the release files move, to a second, public repository. `Scripts/release` drafts each release
there. `release.yml` makes it public there after his approval, so it needs a token from the agents' app
that can write to that repository, kept as a GitHub secret. Today it uses only GitHub's own token for
this repository, and section 6 keeps GitHub free of such keys. The agents' app must be installed on
both. The download page's link to each app's spec stops working.

**What argues for privacy today.** Nothing. A search for e-mail addresses, home folder paths and private
names or places found none. The only names are his GitHub name and his web address, which the download
page shows anyway. An app that handles spoken words keeps them on his Mac, never in the code.

**Outcome, once he approves.** It stays public. Privacy is decided again before a spec needs something in the code that
cannot be public.
