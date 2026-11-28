# Bolo

Bolo (ਬੋਲੋ, "speak") writes what you say, wherever you are typing. Its identifier is
`com.amansingh.bolo`, the same as the Bolo that came before it, so the permissions already given to that
one carry over.

## What It Is For

You hold a key and speak, in any app. When you let go, your words appear where your cursor is, written
as you would have typed them there: the right capitals, the names on your screen spelled as they are
shown, an email laid out as an email. Your voice is heard on this Mac, and is never sent anywhere to be
heard. How well Bolo reads where you are decides how good it is, so most of this page is about that.

## Must-Haves

1. **It writes what you say, in any app.** Hold Right Option and speak; let go, and the words appear.
   Tap it twice to talk hands-free; it stops when you press once, after 45 seconds of quiet, or at ten
   minutes. Escape throws a dictation away. Right Option still works with other keys, as it always
   has. A soft tick sounds as it starts and stops. Saying "send it" at the end presses Return.
   *Asks for:* the microphone, once. macOS shows "Allow “Bolo” to access your microphone?".
   *Proved by:* a test that hears a recording and writes its words; your try with a build.
2. **It hears you on this Mac,** in English, with Fluid Speech Pro, run through FluidAudio. You choose
   the microphone. Your Mac's own catches your first words while AirPods wake, and if a microphone goes
   away mid-sentence, the next takes over. Bolo uses the models already in a folder you choose, so on a
   Mac that has them nothing is downloaded. On a new Mac it downloads the speech model once, about 620
   megabytes. FluidAudio is free to use under the Apache 2.0 licence, and the model under CC BY 4.0;
   the About window credits both.
   *Proved by:* before 1.0 is offered to you, it hears recordings you choose with no more mistakes than
   the Bolo before it. If it makes more, you are asked again.
3. **It reads where you are,** the moment you press the key, in a quarter of a second at most: the app
   and what kind it is, the website's address, the box you are in and whether it holds one line or
   many, the text before and after your cursor, anything selected, and the words near the box, the
   newest messages first. It never reads a password box, and never writes into one. In a remote desktop
   it reads a picture of the window instead. *(waits on round three)*
   *Asks for:* nothing more than pasting needs (must-have 8); Screen Recording only for a remote desktop.
   *Proved by:* a test that reads a real box in a window of its own, with text before and after the
   cursor and a word selected, gets each part back, and is timed; a test that a password box gives
   nothing; your try in a mail app, a chat and a browser.
4. **It writes to fit where you are.** In the middle of a sentence it carries on: a small letter, a
   space where words would touch, no extra full stop. A search box or a subject line gets one line and
   no full stop. In an email, a greeting, paragraphs and sign-off you say each go on their own line.
   Three or more things you list go one to a line in notes and email. It follows the tone of the app
   and of the conversation: relaxed in chats, proper in email and notes. In a terminal or code it
   writes your words exactly. Anything selected is replaced. Numbers, times and dates are digits.
   "Comma", "new line" and "scratch that" do what they say, and a correction keeps only what you meant.
   *(waits on round three)*
   *Proved by:* made-up scenes, each a box with text around the cursor, what you said, and what you
   approved it writes. For example, after "see you at the ", saying "Station at six" writes
   "station at 6".
5. **It finds the word you meant.** A word it half-heard becomes the word on your screen that sounds
   like it: a name in the thread, or a made-up word two people share. Words you teach it are spelled as
   you spell them; you add them one at a time or from a plain file. When you fix a word just after it
   lands, Bolo learns it and says so. In the one app you choose for it, it knows medical words, from a
   list kept on this Mac. *(waits on round three)*
   *Proved by:* tests where a made-up word on screen, heard as two ordinary words, is written as the
   made-up word; and a taught word and a fixed word, each heard a little wrong, written as they should be.
6. **It tidies quickly, sending little.** It takes out "um", repeats and words you took back, keeps
   your words and meaning, and never answers what you said. A short, plain dictation, up to 25 words
   with nothing to correct and no doubtful name, is tidied on the spot by Bolo's own rules. Anything
   else goes to Claude,
   with only what helps: where you are, a few lines around your cursor, the words on screen that sound
   like yours, and what you said. Its standing instructions are kept ready, so each dictation sends
   little. If Claude has not answered in five seconds, or there is no network, or you are in a private
   app, a model on this Mac tidies it, and Claude's late answer waits on the card. That model is the one
   you pick after a test on your own dictations; if it needs outside code, you are asked first. Every
   answer is checked before it lands: one that answers you, runs long or invents words gives way to the
   next. *(waits on round three)*
   *Proved by:* the scenes of must-have 4 tidied by Bolo's rules, by Claude and by the model on this
   Mac, each scored against the text you approved for that scene; a test that what goes
   to Claude holds only those four parts; and the time from letting go to the words landing, measured
   on your Mac.
7. **Private apps stay private.** Words you say in an app you mark as private are never sent to Claude:
   there, this Mac tidies alone. They still go to your history, in iCloud. The list is yours, kept on
   this Mac.
   *Proved by:* a test that a dictation in a private app makes no request to the network.
8. **It puts your words where your cursor is,** and then puts your clipboard back as it was. If the app
   changed while you spoke, or will not take a paste, the words are copied and it says to press
   Command-V. Command-Z in the app takes a dictation back.
   *Asks for:* Device Control and Data Access, once, in System Settings, to hear Right Option, to read
   where you are, and to paste. Earlier versions of macOS called it Accessibility. And Paste from Other
   Apps, to put your clipboard back.
   *Proved by:* a test that every kind of thing on the clipboard comes back unchanged, and one that a
   password box is turned down; your try with a build.
9. **A listening bar shows what Bolo is doing.** While you speak, it shows that it is listening and how
   loud you are. Then it shows that it is tidying, and then that your words have landed. It never
   takes the keyboard from the app you are in. A quiet line is the direction; its look is reworked
   with you in pictures and films before it is built.
   *Proved by:* its pictures and a short film beside the one you sent, judged by critics who did not
   build it, then your yes.
10. **Nothing you say is lost.** Its card in the menu bar holds your latest dictations, with Copy, Paste,
    and Try Again for one that did not land. A history window finds any dictation by a word or a date,
    copies it, and shows what was heard and how long it took. Your words and their recordings are kept
    in your Documents in iCloud, so a copy survives if this Mac fails, for 90 days at first. In Settings
    you choose how long, and whether recordings are kept at all.
    *Proved by:* a test that a failed tidy leaves the heard words on the card, that a search finds a
    dictation by word and by date, and that words and recordings older than you chose are deleted.
11. **The first open on a new Mac is a welcome,** made from the same parts as Chete's. It greets you in
    Gurmukhi and in English, and says in two lines what Bolo does: hold Right Option and speak. Then
    one step to a page: the key you hold to talk, chosen from a few, Right Option first, and changed
    later in Settings; the microphone; pasting; your clipboard; your Claude key; and the folder of
    models, or their download. On a Mac with the earlier Bolo, one more page brings in your words and
    history. Last comes the offer to open at login. Each step says first what your Mac will show.
    Nothing asks you once the welcome is done.
    *Asks for:* where your models are, if you have them. Your Claude key, once: it is kept in the
    keychain all your apps share, which iCloud Keychain carries, so no other app ever asks again. Login
    Items, if you choose to open it at login.
    *Proved by:* the tour through every page on GitHub's Mac, pictures you approve, and your try with a
    build for each switch in System Settings.
12. **It takes over the Bolo before it.** In its welcome, it brings in the words you taught it, your
    settings and your history. The earlier Bolo's files are read and never changed. Its models are put
    in the Trash only when you say.
    *Proved by:* a test that reads made-up files in the earlier Bolo's form.
13. **It keeps itself up to date,** as every app here does: it shows what is new, and you choose when.
    *Proved by:* GitHub's Mac installing the release before and watching it take the update.

## The Network

Your voice is never sent anywhere to be heard. Each dictation's words, with the little that helps, go
to Claude to be tidied, unless the rules tidy it on the spot, there is no network, or you are in a
private app. Your history and recordings are kept in your Documents in iCloud. On a Mac without the
models, the speech model and the model that tidies offline, unless that is Apple's own, are downloaded
once, from Hugging Face, where their makers publish them. Once a day Bolo fetches its update feed from
this site, and downloads an update only when you choose.

## Out of Scope

These come later, each as its own change to this page:

- Commands: holding Right Command and saying what to do with the selected text, such as "make this
  formal".
- Hearing languages other than English.
- Turning a recording or a meeting into text.
