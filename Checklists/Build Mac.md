# A Mac That Builds the Apps

The owner types no command. He does three things, then an agent does the rest. It asks him only for
what is his: a sign-in, a standard permission, a key pasted from Passwords.

**The owner:**

1. Signs in to his Apple Account, with iCloud Keychain and Desktop and Documents on.
2. Installs Xcode from the App Store and opens it once.
3. Installs the Claude app and signs in. In Code he chooses his home folder and says: "Set up this Mac
   to build my apps from github.com/amansinghphotos/Sagar."

**The agent, in that chat:**

- [ ] `git clone https://github.com/amansinghphotos/Sagar ~/Developer/Sagar`. Then `cd` there.
- [ ] **Owner.** Agents' GitHub key: paste the note of Sagar · Agents' GitHub Key into the file the agent names.
- [ ] `.claude/hooks/start setup <that file>`, then delete the file. It keeps the key, gives git the agents'
      identity, installs `gh`, clones the private notes beside, and brings back his Claude instructions, plugins and skill.
- [ ] `.claude/hooks/start ready` prints nothing. Every session start says what is still missing.
- [ ] Notary: `xcrun notarytool history --keychain-profile Sagar` answers. If not, **Owner**: paste the
      app password from Sagar · Apple Notary into the file the agent names. Store it with
      `notarytool store-credentials Sagar --sync`, his Apple Account from that entry and the team in
      `Config/Export.plist`. Delete the file.
- [ ] **Owner.** Developer ID: paste the note of Sagar · Developer ID into the file the agent names. The agent
      decodes it with `base64 -d` into a `.p12`; open that, give it the password from the same entry. Delete both files.
- [ ] **Owner.** Update key: paste the note of Sagar · Update Key into the file the agent names; `generate_keys -f <file>`, then delete the file.
- [ ] `Scripts/check` is green. `Scripts/build Chete` prints "signed": the update key matches.
- [ ] **Owner.** The first build asks twice to use the keychain (signing, the update key): Always Allow.
- [ ] Tell him: "Ready. Start each new chat in the Sagar folder."

**Before a Mac is given up:** `Scripts/check leaving` says "Nothing lives only on this Mac."
