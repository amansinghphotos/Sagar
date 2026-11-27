# A Mac That Builds the Apps

The owner types no command. He does three things, then an agent does the rest. It asks him only for
what is his: a sign-in, a standard permission, a key pasted from Passwords.

Everything that grows lives on an external drive: the project, the private notes beside it, each chat's
copy, and every build. The Mac itself keeps only the apps, Xcode, Claude and their own settings.
The drive: a 1 TB solid-state drive on USB 4 or Thunderbolt, formatted APFS (Encrypted), always plugged in
when a chat works.

**The owner:**

1. Signs in to his Apple Account, with iCloud Keychain and Desktop and Documents on.
2. Installs Xcode from the App Store and opens it once. Plugs in the drive.
3. Installs the Claude app and signs in. In Code he chooses the drive and says: "Set up this Mac to
   build my apps from github.com/amansinghphotos/Sagar."

**The agent, in that chat:**

- [ ] `git clone https://github.com/amansinghphotos/Sagar` onto the drive, as `Sagar` at its top. No drive, no clone: ask him to plug it in.
- [ ] **Owner.** Agents' GitHub key: paste the note of Sagar · Agents' GitHub Key into the file the agent names.
- [ ] `.claude/hooks/start setup <that file>`, then delete the file. It keeps the key, gives git the agents'
      identity, installs `gh`, clones the private notes beside, sends Xcode's builds to the drive, and
      brings back his Claude instructions, plugins and skill. It stops if the project is not on its own drive.
- [ ] **Owner.** macOS asks once whether Claude may use the drive: Allow.
- [ ] `.claude/hooks/start ready` prints nothing. Every session start says what is still missing.
- [ ] Notary profile: it comes by iCloud Keychain. `xcrun notarytool history --keychain-profile Sagar` answers. If not, stop and tell him.
- [ ] **Owner.** Developer ID: paste the note of Sagar · Developer ID into the file the agent names. The agent
      decodes it with `base64 -d` into a `.p12`; open that, give it the password from the same entry. Delete both files.
- [ ] **Owner.** Update key: paste the note of Sagar · Update Key into the file the agent names; `generate_keys -f <file>`, then delete the file.
- [ ] `Scripts/check` is green. `Scripts/build Chete` prints "signed": the update key matches.
- [ ] **Owner.** The first build asks twice to use the keychain (signing, the update key): Always Allow.
- [ ] **Owner.** Approve the card that archives a chat once its pull request closes: archiving removes the chat's copy.
- [ ] Tell him: "Ready. Start each new chat in the Sagar folder on the drive."

**What stays on the Mac itself:** Xcode, Claude and `gh`; `~/.claude`, with his instructions and each chat's
history, which Claude prunes after a month; Swift's shared package cache in `~/Library/Caches`, which macOS
may empty; the keys in the keychain; temporary files, which macOS clears.

**If the drive is lost:** a new drive, then the same sentence. The code and the private notes are on GitHub.

**Before a Mac is given up:** `Scripts/check leaving` says "Nothing lives only on this Mac."
