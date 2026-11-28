# Bolo

Bolo (ਬੋਲੋ, "speak") writes what you say, wherever you are typing. Its identifier is
`com.amansingh.bolo`, the same as the Bolo that came before it, so the permissions already given to that
one carry over.

## What It Is For

You hold a key and speak, in any app. When you let go, your words appear where your cursor is, tidied:
no "um", no false starts, with the punctuation in. Your voice is heard on this Mac, and is never sent
anywhere to be heard.

## Must-Haves

1. **It writes what you say, in any app.** Hold Right Option and speak; let go, and the words appear.
   Tap it twice to talk hands-free; it stops when you press once, after 45 seconds of quiet, or at ten
   minutes. Escape throws a dictation away. Right Option still works with other keys, as it always
   has. A soft tick sounds as it starts and stops. Saying "send it" at the end presses Return.
   *Asks for:* the microphone, once. macOS shows "Allow “Bolo” to access your microphone?".
   *Proved by:* a test that hears a recording and writes its words; your try with a build.
2. **It hears you on this Mac,** in English, with NVIDIA's Parakeet, the speech model your Bolo uses
   now. You choose the microphone. Your Mac's own catches your first words while AirPods wake, and if
   a microphone goes away mid-sentence, the next takes over. The model is downloaded once, about 440
   megabytes, and kept on this Mac; where the earlier Bolo has it, that copy is used. It runs through
   FluidAudio, outside code that is free to use under the Apache 2.0 licence. The About window credits
   both, as their licences ask.
   *Proved by:* before 1.0 is offered to you, it hears recordings you choose with no more mistakes than
   the Bolo before it. If it makes more, you are asked again.
3. **It tidies your words.** It takes out "um", repeats and words you took back, and puts in the
   punctuation. It keeps your words and meaning, and never answers what you said. Your writing fits
   the app: relaxed in chats, proper in email and notes. Claude tidies it. If Claude has not answered
   in five seconds, or there is no network, this Mac tidies it, and Claude's late answer waits on the
   card.
   *Proved by:* made-up dictations, each with the tidy result you approved, and a question that stays a
   question.
4. **It knows your words.** Names and terms you teach it are heard and spelled as you spell them. You add
   them one at a time, or bring in a list from a plain file. When you fix a word just after it lands,
   Bolo learns it and says so. It spells names it can see on your screen as they are shown, reading
   them with the permission you give for pasting. In the one app you choose for it, it knows medical
   words, from a list kept on this Mac.
   *Asks for:* Screen Recording, only for a remote desktop, whose words it cannot read any other way.
   *Proved by:* tests where a taught word, a fixed word and a name on screen, each heard a little wrong,
   are written as they should be.
5. **Private apps stay private.** Words you say in an app you mark as private are never sent to Claude:
   there, this Mac tidies alone. They still go to your history, in iCloud. The list is yours, kept on
   this Mac.
   *Proved by:* a test that a dictation in a private app makes no request to the network.
6. **It puts your words where your cursor is,** and then puts your clipboard back as it was. If the app
   changed while you spoke, or will not take a paste, the words are copied and it says to press
   Command-V. It never writes into a password box. Command-Z in the app takes a dictation back.
   *Asks for:* Device Control and Data Access, once, in System Settings, to hear Right Option and to
   paste. Earlier versions of macOS called it Accessibility. And Paste from Other Apps, to put your
   clipboard back.
   *Proved by:* a test that every kind of thing on the clipboard comes back unchanged, and one that a
   password box is turned down; your try with a build.
7. **A listening bar shows what Bolo is doing.** While you speak, it shows that it is listening and how
   loud you are. Then it shows that it is tidying, and then that your words have landed. It never
   takes the keyboard from the app you are in. A quiet line is the direction; its look is reworked
   with you in pictures and films before it is built.
   *Proved by:* its pictures and a short film beside the one you sent, judged by critics who did not
   build it, then your yes.
8. **Nothing you say is lost.** Its card in the menu bar holds your latest dictations, with Copy, Paste,
   and Try Again for one that did not land. A history window finds any dictation by a word or a date,
   copies it, and shows what was heard and how long it took. Your words and their recordings are kept in your Documents in
   iCloud, so a copy survives if this Mac fails, for 90 days at first. In Settings you choose how long,
   and whether recordings are kept at all.
   *Proved by:* a test that a failed tidy leaves the heard words on the card, that a search finds a
   dictation by word and by date, and that words and recordings older than you chose are deleted.
9. **The first open on a new Mac is a welcome,** made from the same parts as Chete's. It greets you in
   Gurmukhi and in English, and says in two lines what Bolo does: hold Right Option and speak. Then
   one step to a page: the key you hold to talk, chosen from a few, Right Option first, and changed
   later in Settings; the microphone; pasting; your clipboard; and your Claude key. On a Mac with the
   earlier Bolo, one more page brings in your words and history. Last comes the offer to open at
   login. Your speech model downloads meanwhile, shown as a level that rises. Each step says first what
   your Mac will show. Nothing asks you once the welcome is done.
   *Asks for:* your Claude key, once. It is kept in the keychain all your apps share, which iCloud
   Keychain carries, so no other app ever asks again. Login Items, if you choose to open it at login.
   *Proved by:* the tour through every page on GitHub's Mac, pictures you approve, and your try with a
   build for each switch in System Settings.
10. **It takes over the Bolo before it.** In its welcome, it brings in the words you taught it, your
    settings and your history. The earlier Bolo's files are read and never changed. Its models are put
    in the Trash only when you say.
    *Proved by:* a test that reads made-up files in the earlier Bolo's form.
11. **It keeps itself up to date,** as every app here does: it shows what is new, and you choose when.
    *Proved by:* GitHub's Mac installing the release before and watching it take the update.

## The Network

Your voice is never sent anywhere to be heard. Each dictation's words go to Claude to be tidied, unless
there is no network or you are in a private app. Your history and recordings are kept in your Documents
in iCloud. The speech model is downloaded once, from Hugging Face, where its makers publish it, unless
the earlier Bolo already has it. Once a day Bolo fetches its update feed from this site, and downloads
an update only when you choose.

## Out of Scope

These come later, each as its own change to this page:

- Commands: holding Right Command and saying what to do with the selected text, such as "make this
  formal".
- Hearing languages other than English.
- Turning a recording or a meeting into text.
