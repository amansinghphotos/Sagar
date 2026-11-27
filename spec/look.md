# Look

Look is how every app here looks and moves. It is one set of parts, made once and shared, so that a new
app starts finished on the outside and only its own feature is new.

Look is not an app. Its work may run beside the app in `NOW`, each in its own git worktree and its own
files. While an app is in
work, the parts its screens need are built first, and the app writes none of its own.

## What It Is For

Every app looks like one family, in either of two themes, and feels the same under the hand: the same
buttons, the same lists, the same way a panel arrives. A screen names only Look's parts and roles, never
a colour, a font or a size, so a change to the look reaches every app at once.

## Must-Haves

1. **Two themes, each light and dark.** Modern is plain and neutral, measured from Search: 13-point
   text, 11.5 for details, 26-point icon buttons, cards rounded at 11 points and panels at 16. Lexicon
   is paper and ink, set in Caslon, sharing Modern's parts and spacing. Modern comes first, and Lexicon
   follows once Modern's pictures are approved. An app chooses its theme once. No seasons, no variants.
2. **Roles, not values.** Colour, type, spacing, corner radius, shadow and motion are each a short list
   of names. Each colour pair carries its contrast as a number, and words meant to be read pass 4.5 to 1.
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
4. **Motion from Search, as written.** Search's springs and timings (glide, settle, quick, the press
   that gives to 97 per cent, the sliding column) and the transitions its parts use are taken word for
   word from Search at commit `c92ea7c`, with its MIT notice kept. Left out: Search's slower motion in
   Low Power Mode, since power is the owner's to manage, and its test switches. Changed only where
   Swift 6 or this repository's rules require. Every movement stops under Reduce Motion.
5. **Keyboard and VoiceOver everywhere.** Controls are Apple's own with a style, so each is reached with
   Tab, shows a focus ring and is read aloud.
6. **A Gallery.** One window, never shipped, showing every part in every state, with a bar to switch
   theme, light or dark, and window size. Each page is pictured in four looks, Modern and Lexicon, light
   and dark, and those pictures are what the owner approves.
7. **Ready for iPhone.** The parts are plain SwiftUI and also build for iPhone. What only a Mac has
   (windows, the menu bar, cursors, blur) sits apart.

## What Proves It

A part is done when its Gallery pictures are approved. Motion is done when the reviewer, reading it beside
Search's source, finds nothing changed beyond what must-have 4 allows, and a test shows each movement
is none under Reduce Motion. Keyboard reach and labels are proven by the Gallery's tour and its audit.

## Out of Scope

More themes, seasons or variants. Window and menu-bar plumbing, which is Shell's. Anything from a third
party but Search's motion.
