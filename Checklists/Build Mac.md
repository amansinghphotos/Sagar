# A Mac That Builds the Apps

The owner installs Xcode and the Claude app, and signs in to iCloud and Claude. An agent does the rest.

- [ ] Xcode is the version `.github/workflows/check.yml` names. GitHub's `gh` is in `~/.local/bin`, signed in to nothing.
- [ ] The Claude app has the owner's `~/.claude/CLAUDE.md` and the agent-skills, taste-skill and cook plugins.
- [ ] `git clone https://github.com/amansinghphotos/Sagar ~/Developer/Sagar`, then `swift build` in it.
- [ ] Notary profile: it comes by iCloud Keychain. `xcrun notarytool history --keychain-profile Theatre` answers.
- [ ] **Owner.** Developer ID: sign in to Xcode's Settings, Accounts; Manage Certificates; add Developer ID Application.
- [ ] **Owner.** Agents' GitHub key: on the Sagar Agent app's GitHub page, Generate a private key.
- [ ] `.claude/hooks/start setup <that downloaded file>`, then delete the file.
- [ ] **Owner.** Update key: paste its text from Passwords into the file an agent names; `generate_keys -f <file>`, then delete the file.
- [ ] `Scripts/check` is green. `Scripts/build <App>` prints "signed": the update key matches.
- [ ] **Owner.** The first build asks twice to use the keychain (signing, the update key): Always Allow.
