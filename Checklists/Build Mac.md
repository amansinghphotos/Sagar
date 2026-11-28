# A Mac That Builds the Apps

The owner types no command. He does three things, then an agent does the rest. It asks him only for
what is his: a sign-in, a standard permission, a key pasted from Passwords.

Everything that grows lives on an external drive, in one `Developer` folder: the project, the private notes
beside it, `Tools` (what setup downloads), `Caches` (what Swift and its tests keep for next time), each chat's
copy and every build. The Mac itself keeps only the apps, Xcode, Claude and their own settings.
The drive: a solid-state drive with 100 GB free, formatted APFS (Encrypted); case-sensitive works too. It is
plugged in whenever a chat works.

**The owner:**

1. Signs in to his Apple Account, with iCloud Keychain and Desktop and Documents on.
2. Installs Xcode from the App Store and opens it once. Plugs in the drive.
3. Installs the Claude app and signs in. In Code he chooses the drive and says: "Set up this Mac to
   build my apps from github.com/amansinghphotos/Sagar."

**The agent, in that chat:**

- [ ] `git clone https://github.com/amansinghphotos/Sagar` into `Developer` on the drive. No drive, no clone: ask him to plug it in. If it is already there, pull it and the notes.
- [ ] **Owner.** Agents' GitHub key: paste the note of Sagar · Agents' GitHub Key into the file the agent names.
- [ ] `.claude/hooks/start setup <that file>`, then delete the file. It keeps the key, gives git the agents'
      identity, installs `gh` into `Tools`, clones the private notes beside, sends Xcode's builds to the drive,
      keeps Swift's two caches in `Caches`, and
      puts back his whole Claude setup with the notes' own `Claude/restore`, which proves each piece. It stops if the project is not on its own drive,
      and marks the Mac: from then on, a chat or a commit in a copy off the drive stops.
- [ ] **Owner.** macOS asks once whether Claude may use the drive: Allow.
- [ ] `.claude/hooks/start ready` prints nothing. Every session start says what is still missing.
- [ ] Notary profile: it comes by iCloud Keychain. `xcrun notarytool history --keychain-profile Sagar` answers. If not, stop and tell him.
- [ ] **Owner.** Developer ID: paste the note of Sagar · Developer ID into the file the agent names. The agent
      decodes it with `base64 -d` into a `.p12`; open that, give it the password from the same entry. Delete both files.
- [ ] **Owner.** Update key: paste the note of Sagar · Update Key into the file the agent names; `generate_keys -f <file>`, then delete the file.
- [ ] `Scripts/check` is green. `Scripts/build Chete` prints "signed": the update key matches.
- [ ] `Scripts/tour setup` makes the hidden Mac that tours are tried in: about an hour, most of it Apple's download.
- [ ] **Owner.** The first build asks twice to use the keychain (signing, the update key): Always Allow.
- [ ] **Owner.** Approve the card that archives a chat once its pull request closes: archiving removes the chat's copy.
- [ ] Tell him: "Ready. Start each new chat in the Sagar folder on the drive."

**What stays on the Mac itself, because no setting or link can safely move it:** Xcode and the parts it
installs for the whole Mac; Claude's app and its own folder; `~/.claude`, with his instructions, plugins and
each chat's history, which Claude prunes after a month, and which Claude needs even with the drive away;
Xcode's and Claude's small settings, logs and caches; the keys in the keychain; temporary files, which
macOS clears. With the drive away, Swift builds without its cache, and nothing lands on the Mac.

**If the drive is lost:** a new drive, then the same sentence. The code and the private notes are on GitHub.

**Before a Mac is given up:** `Scripts/check leaving` says "Nothing lives only on this Mac."
