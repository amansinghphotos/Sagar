# A New Repository

Only the owner's own sign-in can do these. An agent does them with it once, and then it is removed.
- [ ] `gh repo create amansinghphotos/Sagar --public`, with Issues on, and push the first commit to `main`.
- [ ] Merging: squash only, branches deleted on merge, auto-merge allowed. No wiki, no projects.
- [ ] Actions: GitHub's own actions only, the code on its `xcode-27` runner and a request's words on
      `ubuntu-latest`. The token reads only by default and cannot approve; `release.yml` alone asks to
      write, to publish a release.
- [ ] Security: secret scanning with push protection, and Dependabot alerts. Labels: `release`, `rules`.
- [ ] Pages: from `docs/` on `main`, at the address in `docs/CNAME`, HTTPS enforced.
- [ ] Rules: both files in `.github/rulesets/`, applied as they are, with nobody able to bypass them.
- [ ] The agents' app, Sagar Agent, installed on this repository alone, by the owner, from the app's own
      page: GitHub removes it when its last repository is deleted. It may write code, workflows, issues
      and pull requests, read checks, and nothing else. Then `.claude/hooks/start setup`.
- [ ] The owner's sign-in leaves this Mac: `gh auth logout`. Then `Checklists/Build Mac.md`.
- [ ] A first pull request from the agents' app goes green, and cannot merge a spec without him.
