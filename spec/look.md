# Look

Look is how every app here looks and moves. It is one set of parts, made once and shared, so that a new
app starts finished on the outside and only its own feature is new.

Look is not an app. Its work may run beside the app in `NOW`, each in its own copy of the repository
and its own files. While an app is in
work, the parts its screens need are built first, and the app writes none of its own.

## What It Is For

Every app looks like one family, in either of two themes, and feels the same under the hand: the same
buttons, the same lists, the same way a panel arrives. A screen names only Look's parts and roles, never
a colour, a font or a size, so a change to the look reaches every app at once.

## Must-Haves

1. **Two themes, each light and dark.** Modern is Search's look exactly, from Search at commit
   `c92ea7c`: its typeface, colours, sizes, spacing, corners, shadows and parts, with nothing changed
   but the one size named in 2.
   A part Search does not have is drawn the way Search draws its nearest one. Lexicon
   is paper and ink, set in New York, Apple's own serif, sharing Modern's parts and spacing.
   Its paper and ink are those of Lexicon's sketch, light and dark, and every word reads at 4.5 to 1 or
   more. Modern comes first, and Lexicon follows once Modern's pictures are approved. An app chooses its
   theme once. No seasons, no variants.
2. **Roles, not values.** Colour, type, spacing, corner radius, shadow and motion are each a short list
   of names. Each colour pair carries its contrast as a number. Modern keeps Search's colours even
   where words fall below 4.5 to 1. One size of type is not Search's: the hero, larger than any of
   its, for the greeting that leads a welcome.
3. **Every part an app could need, built now,** not one at a time as apps ask:
   - *Actions:* buttons in four kinds (main, plain, quiet, destructive), icon button, button with a
     held menu, pull-down menu, link, small text action, toolbar, context menu.
   - *Choosing and typing:* switch, checkbox, radio choices, segmented control, select, combo box,
     slider, stepper, text field, password field, text over several lines, search field, tags, date
     and time, colour well, shortcut recorder, picture choices.
   - *Holding things:* card, panel, separator, section label, group box, disclosure, split view, tabs,
     inspector, scroll edges, drag handle.
   - *Lists:* list row, tree, table, grid of tiles, setting row and section, label and value, drag to
     reorder, and the mark: an app's or a site's icon, or a letter.
   - *Finding the way:* sidebar and its items, a page that follows the window's size, command palette,
     path, page dots.
   - *Things that appear:* popover, sheet, alert and confirmation, toast with a queue, tooltip showing
     its key, menu-bar panel, floating panel, first-open pages, a card for what is new, an About window
     with its acknowledgements.
   - *Status:* progress bar, spinner, loading placeholder, badge, key cap, count, meter, sound level,
     banner, nothing-here-yet, and an error with Try Again.
   - *Reading:* long text, code, a picture, Quick Look preview, and a style for charts.
4. **Motion like Search's, written here.** Each spring and timing (glide, settle, quick, the shrink to
   97 per cent when pressed, the sliding column) and each transition the parts use is our own code,
   written from how Search's moves at commit `c92ea7c`, and kept close enough that a hand cannot tell
   them apart. Nothing of Search's is pasted, so nothing is owed. Left out: Search's quicker motion in
   Low Power Mode or when the Mac is hot, since power is the owner's to manage, and its test switches.
   Under Reduce Motion every movement is instant, but for the sliding column's short fade, which Search
   keeps.
5. **Keyboard and VoiceOver everywhere.** Controls are Apple's own with a style, so each is reached with
   Tab, shows a focus ring and is read aloud.
6. **A Gallery.** The agents' test window, never shipped, showing every part in every state, with a bar
   to switch theme, light or dark, and window size. Each part is pictured there, and its pictures are
   kept to catch any change no one meant.
7. **Ready for iPhone.** The parts are plain SwiftUI and also build for iPhone. What only a Mac has
   (windows, the menu bar, cursors, blur) sits apart.

## What Proves It

A Modern part is done when its picture matches the same part pictured from Search's own code at
`c92ea7c`, in light and dark, kept beside it as the reference. A part Search does not have, and all of
Lexicon, has no Search picture to match: the owner first sees it in an app's screen, and approves that
screen's pictures. Until then, Lexicon is built toward its sketch, kept beside Search's pictures.
Motion is done when each movement, measured
through time, stays within two hundredths of the same movement measured from Search's own code at
`c92ea7c`, kept beside it as the reference, and a test shows each movement is instant under Reduce
Motion, but for that one fade. Keyboard reach and labels are to be proven by the Gallery's tour and its audit, set aside for now (decision 9).

## Out of Scope

More themes, seasons or variants. Window and menu-bar plumbing, which is Shell's. Anything from a third
party.
