# Bolo

Bolo (ਬੋਲੋ, "speak") writes what you say, wherever you are typing. Its identifier is
`com.amansingh.bolo`, the same as the Bolo that came before it, so the permissions already given to that
one carry over.

## What It Is For

You hold a key and speak, in any app. When you let go, your words appear where your cursor is, tidied:
no "um", no false starts, with the punctuation in. Your voice is heard on this Mac and never leaves it.

Lines marked *(waits on your tick)* follow the recommendation on the page of six choices. They change
to match what you tick, before this is approved.

## Must-Haves

1. **It writes what you say, in any app.** Hold Right Option and speak; let go, and the words appear.
   Tap it twice to talk hands-free, and press it once to stop. Escape throws a dictation away. Right
   Option still works with other keys, as it always has. *(waits on your tick)*
   Your first words are caught, even on AirPods, and a microphone that goes away mid-sentence is
   replaced by the next.
   *Asks for:* the microphone, once. macOS shows "Allow “Bolo” to access your microphone?".
   *Proved by:* a test that hears a recording and writes its words; your try with a build.
2. **It hears you on this Mac,** with Apple's own speech, which macOS downloads once and keeps up to
   date. What you say is never sent anywhere to be heard. Apple's speech asks for no permission of its
   own. *(waits on your tick)*
   *Proved by:* before 1.0 is offered to you, it hears recordings you choose with no more mistakes than
   the Bolo before it. If it makes more, you are asked again.
3. **It tidies your words.** It takes out "um", repeats and words you took back, and puts in the
   punctuation. It keeps your words and meaning, and never answers what you said. Claude tidies them,
   and this Mac tidies them when there is no network. *(waits on your tick)*
   *Proved by:* made-up dictations, each with the tidy result you approved, and a question that stays a
   question.
4. **It knows your words.** Names and terms you teach it are heard and spelled as you spell them. You can
   add one at a time, or bring in a list from a plain file.
   *Proved by:* a test where a taught word, heard a little wrong, is written as taught.
5. **Private places stay private.** Apps you mark as private never send your words to Claude: there,
   this Mac tidies alone. The list is yours, kept on this Mac.
   *Proved by:* a test that a dictation in a private app makes no request to the network.
6. **It puts your words where your cursor is,** and then puts your clipboard back as it was. If the app
   changed while you spoke, or will not take a paste, the words are copied and it says to press
   Command-V. It never writes into a password box. *(waits on your tick)*
   *Asks for:* Device Control and Data Access, once, in System Settings, to hear Right Option and to
   paste. Earlier versions of macOS called it Accessibility. And Paste from Other Apps, to put your
   clipboard back.
   *Proved by:* a test that every kind of thing on the clipboard comes back unchanged, and one that a
   password box is turned down; your try with a build.
7. **A listening bar shows it hears you.** A small bar above the Dock, whose band of dots rises and falls
   with your voice, in two calm colours. It says when it is tidying, and glows once as the words land.
   It never takes the keyboard from the app you are in. *(waits on your tick)*
   *Proved by:* its pictures and a short film beside the one you sent, judged by critics who did not
   build it, then your yes.
8. **Nothing you say is lost.** Its card in the menu bar holds your latest dictations, with Copy, Paste,
   and Try Again for one that did not land. Your words are kept for 90 days, and no recording is kept.
   *(waits on your tick)*
   *Proved by:* a test that a failed tidy leaves the heard words on the card, and that older ones go.
9. **The first open on a new Mac is a welcome,** made from the same parts as Chete's. It greets you in
   Gurmukhi and in English, and says in two lines what Bolo does: hold Right Option and speak. Then
   one step to a page: the key you hold to talk, chosen from a few, Right Option first, and changed
   later in Settings; the microphone; pasting; your clipboard; and your Claude key. On a Mac with the
   earlier Bolo, one more page brings in your words and history. Last comes the offer to open at
   login. Apple's speech downloads meanwhile, shown as a level that rises. Each step says first what
   your Mac will show. Nothing asks you once the welcome is done.
   *Asks for:* your Claude key, once. It is kept in the keychain all your apps share, which iCloud
   Keychain carries to your other Macs, so no other app ever asks again. Login Items, if you choose to
   open it at login.
   *Proved by:* the tour through every page on GitHub's Mac, pictures you approve, and your try with a
   build for each switch in System Settings.
10. **It takes over the Bolo before it.** In its welcome, it brings in the words you taught it, your
    settings and your history. The earlier Bolo's files are read and never changed. Its models are put
    in the Trash only when you say.
    *Proved by:* a test that reads made-up files in the earlier Bolo's form.
11. **It keeps itself up to date,** as every app here does: it shows what is new, and you choose when.
    *Proved by:* GitHub's Mac installing the release before and watching it take the update.

## The Network

Your voice never leaves this Mac. Each dictation's words go to Claude to be tidied, unless there is no
network or you are in a private place. macOS downloads Apple's speech for your language once. Once a
day Bolo fetches its update feed from this site, and downloads an update only when you choose.

## Out of Scope

These come later, each as its own change to this page:

- Commands: holding Right Command and saying what to do with the selected text.
- Reading names from your screen, and a style for each app.
- Learning a word when you correct it after a paste.
- Saying "send it" to press Return.
- Turning a recording or a meeting into text.
