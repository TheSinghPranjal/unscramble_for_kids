# Unscramble for Kids

A picture-clue word puzzle for ages 4–10. Kids look at a picture, then drag or
tap scrambled letters into the boxes to spell the word. Every win earns stars,
stickers and badges. Losing is never scary: the picture stays visible and
"Try Again" is always one tap away.

- **300 words**: 100 × 3-letter, 100 × 4-letter, 100 × 5-letter
- **10 categories in every length**: Animals, Food, Nature, Home, Colors, Body,
  Toys, Transport, Weather, School
- **Claymorphism** UI with a pastel kids palette (Fredoka font, bundled)
- **Fully offline**: no accounts, ads, chat or network calls

## Run

```sh
flutter pub get
flutter run
flutter test
```

## Gameplay rules

| Rule | Value |
| --- | --- |
| Default length | 3 letters (last choice is remembered) |
| Lives | 5 soft hearts (kids mode) |
| Wrong letter | −1 heart, tile shakes and stays in the tray |
| Free hint | unlocks after 2 mistakes, once per round: places the next correct letter and flashes the picture + hint text |
| Timer | off for 3 letters, on for 4 (90 s) and 5 (120 s); toggle per length in Settings |
| Points | 10 / 20 / 30 by length, +2 per heart left, +1 per 5 s left, +5 with no hint |

### Stars & rewards

Stars are **lifetime** stars and are never spent, so kids never lose them.
Stickers and themes unlock when the total reaches their threshold.

| Win | Stars |
| --- | --- |
| 3 / 4 / 5 letters | 1–3 / 2–4 / 3–5 (+1 for no hint, +1 for no hearts lost) |
| First time solving a word | +1 |
| First win of the day | +2 |
| Win streak | +1 per consecutive win (max +5) |

Stickers unlock at 5, 12, 20, 40, 60, 80, 110 and 150 stars. Themes: Sunshine
Clay (30) and Ocean Clay (50). Badges: Word Rookie, Ten Wins, Perfect Round,
Streak 5, No-Hint Hero, Triple Champ (25 three-letter wins) and Category
Explorer (a win in all 10 categories).

## Word data: `assets/words/words.json`

The JSON file is the **single source of truth** for words and their images.

```json
{
  "id": "cat_3_001",
  "word": "CAT",
  "length": 3,
  "category": "Animals",
  "hintText": "Says meow and loves to nap",
  "difficulty": "easy",
  "emoji": "🐱",
  "image": "assets/images/words/3_letter/cat.png"
}
```

- `word`: uppercase A–Z, 3–5 letters, matching `length`
- `image`: `assets/images/words/<length>_letter/<lowercase word>.png`
- `emoji` (optional): drawn on placeholder or missing pictures so the game is
  playable before final art exists

On boot the app validates the deck (100 per length, every category in every
length, unique words, ids and images, and the path naming rule). Debug builds
assert on any problem. Release builds log it and show a friendly "picture
coming soon" tile instead of crashing.

## Dropping in the final 300 images

Each word currently has a generated **clay placeholder** PNG (a soft tile in
the category's color). The app spots placeholders through a hidden PNG marker
and draws the word's emoji on top of them.

1. Export your art as **square PNGs**, ideally **512×512 or smaller** so the app
   stays light on low-end devices. Keep the `.png` extension, because the JSON
   paths use it.
2. Name each file exactly like the word in lowercase: `CAT` → `cat.png`,
   `APPLE` → `apple.png`. The exact filename for every word is in
   `assets/words/image_manifest.json` (`expectedPath`).
3. Copy the files over the placeholders in the matching folder:
   - `assets/images/words/3_letter/`
   - `assets/images/words/4_letter/`
   - `assets/images/words/5_letter/`
4. Refresh the checklist:
   ```sh
   dart run tool/build_image_manifest.dart
   ```
   It reports how many images are present, still placeholders, or missing.
5. Verify in the app: **Settings → Word & Image Library**. Every row shows the
   thumbnail, word, category, length, asset path and a status
   (**OK** / **Placeholder** / **Missing image**). Use **Needs art only** to see
   what's left, tap a row for a big preview with the expected filename, and use
   the copy button to copy a mapping report.

Need placeholders again (for example after adding words)?

```sh
python3 tool/generate_placeholders.py   # needs Pillow; never overwrites real art
dart run tool/build_image_manifest.dart
```

### Optional reward art

Stickers and badges render as emoji on clay discs. To use custom art, add
PNGs with the names given in `RewardCatalog`
(`lib/features/unscramble/domain/rewards.dart`), for example
`assets/images/rewards/stickers/happy_star.png`. The app uses a file
automatically whenever it is bundled.

## Architecture

```
lib/
  main.dart / app.dart                 ProviderScope + themed MaterialApp
  shared/
    theme/       kids_palette.dart     color tokens + unlockable ClayPalettes
                 clay_theme.dart       ThemeData (Fredoka, clay dialogs)
    widgets/     clay.dart             ClayCard, ClayButton, ClayLetterTile, …
                 confetti.dart         confetti, shake, bounce (reduce-motion aware)
    prefs/       prefs.dart            SharedPreferences provider + keys
                 app_settings.dart     settings model + controller
    feedback/    sfx.dart              haptics/system sounds (safe no-ops)
  features/unscramble/
    domain/       WordEntry, LengthMode, WordBank, GameState, rewards models + StarRules
    data/         WordRepository, image audit (placeholder detection), RewardRepository
    application/  UnscrambleController, RewardsController, WordDeck, boot
    presentation/ Boot, Home, Game, Rewards, Settings, Word Library, How to Play
tool/
  generate_placeholders.py   clay placeholder PNGs for missing word images
  build_image_manifest.dart  regenerates assets/words/image_manifest.json
```

State is managed with Riverpod (`Notifier`s). Progress and settings are stored
locally in SharedPreferences.

## Tests

- `test/words_json_test.dart`: 100 words per length, every category in every
  length, unique words, ids and images, filenames matching words, files on
  disk, manifest consistency
- `test/word_deck_test.dart`: deal-once-per-pass, reshuffle without immediate
  repeats, easy-first ordering, scramble never shows the answer
- `test/unscramble_controller_test.dart`: length and category filters, empty
  deck, image path on the round, correct and wrong letters, drag/tap-slot
  placement, duplicate letters, hint once per round, lose, timer on/off/time-up,
  pause and leave
- `test/rewards_test.dart`: star math, bonuses, badge unlocks, persistence,
  themes, reset
- `test/widgets_test.dart`: boot to home, picture clue on the game screen, win
  dialog flow, pause overlay, small landscape layout, library listing all 300
  words, rewards empty state

## Privacy

No accounts, no ads, no chat, no external links in gameplay. All progress
stays on the device.
