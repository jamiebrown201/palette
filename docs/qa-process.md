# QA Screenshot Review Process

## Overview

This is a systematic screen-by-screen visual QA process for the Palette app. The user takes screenshots on the Android emulator, shares them with Claude for review, and Claude implements fixes before moving on.

## Key Constraint: Image Limits

Claude has a limited number of images it can process per conversation. To work within this:

- **Review ONE screen at a time** - never batch multiple screenshots
- **Fix before moving on** - implement changes, verify with `flutter analyze` + `flutter test`, then move to the next screen
- **If a conversation hits the image limit**, start a new conversation and pick up from the tracking list below

## Setup

1. App must be running on `emulator-5554` (user launches from IDE)
2. Unified QA script: `./scripts/qa.sh`

## Quick Commands

```bash
# Navigate to a screen and take a screenshot
./scripts/qa.sh <screen>

# Seed demo data, restart app, navigate, and screenshot
./scripts/qa.sh <screen> --seed

# Just seed the DB and restart (no navigation)
./scripts/qa.sh --seed-only

# List all available screens
./scripts/qa.sh --list
```

Available screens: `home`, `rooms`, `room-detail`, `explore`, `wheel`, `white-finder`, `paint-library`, `profile`, `palette`, `red-thread`, `paywall`, `capture`, `onboarding`, `dev`

## Workflow Per Screen

```
1. Claude navigates + screenshots: ./scripts/qa.sh <screen>
   (use --seed on first run of a session to populate demo data)
2. Claude reads the screenshot and reviews it
3. Claude provides feedback:
   - Layout and spacing issues
   - Typography and readability
   - Colour usage and contrast
   - Touch target sizes
   - Empty states
   - Overall visual polish
4. Claude implements fixes immediately
5. Claude runs: flutter analyze + flutter test
6. User hot restarts app and verifies visually
7. If good, move to next screen. If not, iterate.
```

## Screen Checklist

Track progress by updating this list. Mark screens as they're reviewed:

### Completed
- [x] Home (with seeded data)
- [x] QA Mode screen
- [x] Room List
- [x] Explore
- [x] Colour Wheel
- [x] White Finder

### Remaining
- [ ] Room Detail
- [ ] Create Room
- [ ] Paint Library
- [ ] Profile
- [ ] My Palette / Colour DNA
- [ ] Red Thread
- [ ] Paywall
- [ ] Onboarding Page 1: Memory Prompt
- [ ] Onboarding Page 2: Visual Preference
- [ ] Onboarding Page 3: Property Context
- [ ] Onboarding Page 4: Quiz Result
- [ ] Capture (coming soon placeholder)

## What to Look For

When reviewing a screenshot, check:

1. **Spacing** - Consistent padding, no cramped or overly sparse areas
2. **Typography** - Hierarchy is clear, text is readable, no truncation issues
3. **Colours** - On-brand (warm neutrals, sage green accents), sufficient contrast
4. **Components** - Buttons are tappable size (48dp+), cards have consistent styling
5. **Content** - Demo data renders correctly, no placeholder text leaking through
6. **Empty states** - Graceful handling when data is missing
7. **Navigation** - Back buttons, tab bar state, screen titles are correct
8. **Overall feel** - Does it feel like a polished, premium app?

## Picking Up From a Previous Session

When continuing QA in a new conversation:

1. Read this file to see which screens are done and which remain
2. Run `./scripts/qa.sh --seed-only` to seed demo data on first run
3. Start with the next unchecked screen: `./scripts/qa.sh <screen>`
4. Follow the same one-at-a-time workflow
