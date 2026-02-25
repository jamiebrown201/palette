# Palette - Claude Code Instructions

## Project Overview
Palette is a Flutter colour companion app for home decorators. It helps users discover their colour personality, plan room palettes using the 70/20/10 rule, and find real UK paint matches.

## Tech Stack
- **Framework:** Flutter (Dart)
- **State management:** Riverpod
- **Database:** Drift (SQLite)
- **Routing:** GoRouter
- **Target:** Android (emulator-5554)

## Key Commands
- **Run app:** `flutter run -d emulator-5554` (keep running in background)
- **Quick refresh:** `flutter analyze` + `flutter test` (run both to verify changes)
- **Hot restart:** Send `R` to the flutter run terminal, or kill and re-run
- **Take screenshot:** `./scripts/qa_screenshot.sh <descriptive-name>`

## Commit Preferences
- Never include "Co-Authored-By" lines in commits
- Use author: Jamie Brown <jamiebrown201@hotmail.com>

## QA Screenshot Review Process

See [QA Process Guide](docs/qa-process.md) for the full workflow.

**Critical constraint:** Claude has image limits per conversation. The QA review process MUST be done **one screen at a time**:

1. Navigate to a screen (use QA Mode at `/dev` route for quick access)
2. Take ONE screenshot: `./scripts/qa_screenshot.sh <screen-name>`
3. User shares screenshot with Claude
4. Claude reviews and gives specific UI/UX feedback
5. Claude implements fixes immediately
6. Run `flutter analyze` + `flutter test` to verify
7. User hot restarts the app, re-screenshots to verify the fix
8. Only then move to the next screen

**Do NOT:**
- Review multiple screenshots in bulk (wastes image budget)
- Ask user to take screenshots of all remaining screens at once
- Skip the verify step before moving on

## Project Structure
```
lib/
  core/           # Shared widgets, theme, constants, colour science
  data/           # Database, models, repositories, seed data
  features/       # Feature modules (onboarding, rooms, palette, explore, etc.)
  providers/      # App-level Riverpod providers
  routing/        # GoRouter configuration and app shell
```

## QA Mode (Debug Only)
- Access: Profile tab > "QA Mode" button (only visible in debug builds)
- Route: `/dev`
- Features: state toggles (subscription, onboarding, colour blind), data seeding, one-tap navigation to any screen
- Files: `lib/features/dev/screens/qa_mode_screen.dart`, `lib/features/dev/services/qa_seed_service.dart`
