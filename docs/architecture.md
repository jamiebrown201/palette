# Palette -- Architecture Document

> **Generated from codebase inspection, March 2026.**
> This document describes what IS implemented, not aspirational design. Partially implemented features are noted as such.

---

## 1. System Overview

Palette is a **Flutter application** targeting Android, built with a **local-first architecture** and **Supabase authentication**. All user data is stored on-device in a SQLite database via the Drift ORM. Supabase provides authentication (Google OAuth + email/password) and user identity; local data is linked to the Supabase user via `supabaseUserId` on the `UserProfiles` table.

**Key characteristics:**

- **Offline-capable:** All colour science, palette generation, and room planning run on-device with zero network dependency. Auth requires connectivity for sign-in but sessions persist offline.
- **Auth-gated:** Users complete the onboarding quiz without an account, then must sign in (Google or email) to access the main app. Auth state drives GoRouter redirects.
- **Seed data model:** A bundled JSON file (`assets/data/paint_colours.json`, ~131 KB) containing 200+ UK paint colours from Farrow & Ball, Little Greene, Dulux Heritage, and Crown is loaded into SQLite on first launch.
- **No code generation for models:** Data models are plain Dart classes with manual `copyWith` methods, not Freezed-generated (despite `freezed` being a dev dependency). Drift tables use `@UseRowClass` to map directly to these model classes.
- **Target:** Android (emulator-5554), Dart SDK ^3.10.4.
- **Env config:** App requires `--dart-define-from-file=dart_defines.env` with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GOOGLE_WEB_CLIENT_ID`.

---

## 2. App Architecture

### 2.1 Folder Structure

```
lib/
  main.dart                  # Entry point: DB init, seed data, provider overrides
  app.dart                   # MaterialApp.router with theme + GoRouter
  core/
    colour/                  # Colour science engine (pure Dart, no Flutter deps)
    constants/               # Enums, renter constraints, room mode config
    theme/                   # Material theme, typography, colour constants
    widgets/                 # Shared UI components (cards, swatches, gates)
  data/
    database/                # Drift database, tables, converters, connection
    models/                  # Plain Dart data classes
    repositories/            # Data access layer (one per entity)
    services/                # Seed data loading, retailer config
  features/
    auth/                    # Authentication gate (Google OAuth + email sign-in)
    capture/                 # Colour capture from camera (placeholder)
    colour_wheel/            # Interactive colour wheel + white finder tool
    dev/                     # QA mode screen (debug builds only)
    explore/                 # Learning content, paint library, colour tools
    home/                    # Dashboard with next-action guidance
    onboarding/              # Colour DNA quiz (3-stage) + result reveal
    palette/                 # Personal colour palette viewer/editor
    profile/                 # User settings, subscription, accessibility
    red_thread/              # Whole-home colour coherence system
    rooms/                   # Room creation, 70/20/10 planner, room detail
    subscription/            # Paywall screen
  providers/                 # App-level Riverpod providers
  routing/                   # GoRouter config and app shell
```

### 2.2 Feature Module Pattern

Each feature module follows a consistent internal structure (not all features use every sub-folder):

```
features/<feature>/
  data/           # Feature-specific constants, content definitions
  logic/          # Pure Dart business logic (no Flutter imports)
  models/         # Feature-specific data models
  providers/      # Riverpod providers scoped to this feature
  screens/        # Screen-level widgets
  widgets/        # Feature-specific UI components
  services/       # Feature-specific services
```

**Key design principle:** Business logic lives in `logic/` as pure functions or plain classes with no Flutter dependency. This makes them directly unit-testable without widget testing infrastructure.

---

## 3. State Management

### 3.1 Riverpod Setup

The app uses **Riverpod v2** (`flutter_riverpod: ^2.6.1`) with a mix of:

- **Classic providers** (`StateProvider`, `Provider`, `StreamProvider`, `FutureProvider`) for app-level state and most feature providers.
- **Code-generated providers** (`@riverpod`, `@Riverpod(keepAlive: true)`) via `riverpod_annotation` + `riverpod_generator` for the database layer and some feature providers (red thread, database repositories).

**Entry point (`main.dart`):**
Supabase is initialised before the database in `main.dart` via `Supabase.initialize()` with URL and anon key from dart defines. The `ProviderScope` wraps the entire app with critical overrides initialised before `runApp`:

```
ProviderScope(
  overrides: [
    paletteDatabaseProvider         // Drift DB instance
    hasCompletedOnboardingProvider  // Onboarding gate
    subscriptionTierProvider        // Free/Plus/Pro/ProjectPass
    colourBlindModeProvider         // Accessibility toggle
    renterConstraintsProvider       // Owner vs renter constraints
  ],
  child: PaletteApp(),
)
```

Auth providers (`supabaseClientProvider`, `authStateProvider`, `isAuthenticatedProvider`, `currentUserProvider`) read from `Supabase.instance.client` directly and do not need overrides.

### 3.2 Provider Organisation

**App-level providers** (`lib/providers/`):

| Provider | Type | Purpose |
|---|---|---|
| `paletteDatabaseProvider` | `@Riverpod(keepAlive: true)` | Drift database instance (must be overridden) |
| `paintColourRepositoryProvider` | `@Riverpod(keepAlive: true)` | Paint colour data access |
| `roomRepositoryProvider` | `@Riverpod(keepAlive: true)` | Room CRUD |
| `paletteRepositoryProvider` | `@Riverpod(keepAlive: true)` | Palette colour data access |
| `colourDnaRepositoryProvider` | `@Riverpod(keepAlive: true)` | DNA result data access |
| `redThreadRepositoryProvider` | `@Riverpod(keepAlive: true)` | Thread colour data access |
| `userProfileRepositoryProvider` | `@Riverpod(keepAlive: true)` | User profile data access |
| `colourInteractionRepositoryProvider` | `@Riverpod(keepAlive: true)` | Colour interaction tracking |
| `seedDataServiceProvider` | `@Riverpod(keepAlive: true)` | Seed data loading |
| `hasCompletedOnboardingProvider` | `StateProvider<bool>` | Onboarding gate flag |
| `subscriptionTierProvider` | `StateProvider<SubscriptionTier>` | Current tier |
| `colourBlindModeProvider` | `StateProvider<bool>` | Accessibility |
| `renterConstraintsProvider` | `StateProvider<RenterConstraints>` | Renter permissions |
| `roomModeConfigProvider` | `Provider.family<RoomModeConfig, bool>` | Per-room mode config |
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Supabase client instance |
| `authServiceProvider` | `Provider<AuthService>` | Auth operations (sign in/out) |
| `authStateProvider` | `StreamProvider<AuthState>` | Streams auth state changes |
| `isAuthenticatedProvider` | `Provider<bool>` | Whether user has active session |
| `currentUserProvider` | `Provider<User?>` | Current Supabase user |

**Feature-level providers** (in each feature's `providers/` folder):

- **Onboarding:** `quizNotifierProvider` -- `StateNotifierProvider<QuizNotifier, QuizState>` managing the multi-stage quiz flow.
- **Palette:** `latestColourDnaProvider` (stream), `paletteColoursProvider` (stream, family by result ID).
- **Rooms:** `allRoomsProvider` (stream), `roomByIdProvider` (future, family by ID), `furnitureForRoomProvider` (future, family by room ID).
- **Red Thread:** `threadColoursProvider` (stream), `coherenceReportProvider` (future), `threadHexesProvider` (future), `adjacentRoomPairsProvider` (future), `floorPlanTemplatesProvider` (future).
- **Colour Wheel:** `colourWheelProviders` for interactive wheel state.
- **Onboarding (drift):** `dnaDriftProvider` for detecting taste evolution.

### 3.3 State Flow Pattern

1. **Database as source of truth:** All persistent state flows through Drift repositories.
2. **Streams for reactivity:** `StreamProvider` watches database tables so UI updates automatically on data changes.
3. **Providers for derived state:** Complex computations (coherence reports, room mode configs) are expressed as derived providers.
4. **StateNotifier for complex flows:** The onboarding quiz uses `StateNotifier` to manage multi-step wizard state with undo capability.

---

## 4. Routing

### 4.1 GoRouter Configuration

The app uses **GoRouter v14** with `StatefulShellRoute.indexedStack` for tab-based navigation with independent navigator stacks per tab.

**Navigator keys:** Six navigator keys (1 root + 5 tab branches) enable full-screen routes to overlay the tab shell.

### 4.2 Route Structure

**Full-screen routes** (outside tab shell, use root navigator):

| Route | Screen | Notes |
|---|---|---|
| `/auth` | `AuthScreen` | Auth gate (Google + email options) |
| `/auth/email` | `EmailAuthScreen` | Email sign-in/sign-up form |
| `/onboarding` | `OnboardingScreen` | Colour DNA quiz flow |
| `/palette` | `PaletteScreen` | Personal palette viewer |
| `/paywall` | `PaywallScreen` | Subscription upgrade |
| `/red-thread` | `RedThreadScreen` | Whole-home coherence |
| `/dev` | `QaModeScreen` | Debug only (`kDebugMode`) |

**Tab-based routes** (5 tabs with `StatefulShellBranch`):

| Tab | Base Route | Sub-routes |
|---|---|---|
| Home | `/home` | -- |
| Rooms | `/rooms` | `/rooms/:roomId` |
| Capture | `/capture` | -- |
| Explore | `/explore` | `/explore/wheel`, `/explore/white-finder`, `/explore/paint-library` |
| Profile | `/profile` | -- |

### 4.3 Navigation Guards

The router watches both `hasCompletedOnboardingProvider` and `isAuthenticatedProvider`, rebuilding on state changes:

| Onboarded | Authenticated | Redirect |
|---|---|---|
| No | No | `/onboarding` |
| Yes | No | `/auth` |
| No | Yes | `/onboarding` |
| Yes | Yes | Allow through |

- **QA bypass:** `/dev` and `/dev/*` routes skip all auth checks.
- **Trailing slash normalisation:** Deep links with trailing slashes are normalised.
- **Error fallback:** Unknown routes render `HomeScreen`.

### 4.4 App Shell

The `AppShell` widget provides the `NavigationBar` with 5 destinations: Home, Rooms, Capture, Explore, Profile. It uses `StatefulNavigationShell.goBranch` for tab switching with state preservation.

---

## 5. Data Layer

### 5.1 Drift Database

**Database class:** `PaletteDatabase` (schema version 17)

**Connection:** `NativeDatabase.createInBackground(file)` using `sqlite3_flutter_libs`. Database file lives at `${applicationDocumentsDirectory}/palette.sqlite`.

### 5.2 Tables

| Table | Row Class | Purpose |
|---|---|---|
| `PaintColours` | `PaintColour` | Seed paint colour library (200+ UK paints) |
| `ColourDnaResults` | `ColourDnaResult` | Quiz results with family, archetype, system palette |
| `PaletteColours` | `PaletteColour` | User's editable palette colours (linked to DNA result) |
| `Rooms` | `Room` | Room profiles with direction, mood, hero/beta/surprise colours |
| `LockedFurnitureItems` | `LockedFurniture` | Existing furniture items locked into room planning |
| `RedThreadColours` | `RedThreadColour` | Whole-home unifying colours (2-4 colours) |
| `RoomAdjacencies` | `RoomAdjacency` | Room connectivity graph for coherence checking |
| `UserProfiles` | `UserProfile` | Single-row table for user preferences, state, and `supabaseUserId` |
| `ColourInteractions` | `ColourInteraction` | Colour selection tracking for DNA drift detection |

### 5.3 Type Converters

- `EnumNameConverter<T>` -- Generic converter for all enum types (stores enum name as text).
- `StringListConverter` -- Comma-separated string list (used for `colourHexes`).
- `RoomMoodListConverter` -- Comma-separated `RoomMood` enum list.

### 5.4 Migration History

| Version | Changes |
|---|---|
| 1 | Initial schema |
| 2 | Added `dnaConfidence`, `archetype` to `ColourDnaResults` |
| 3 | Added `undertoneTemperature`, `systemPaletteJson` to `ColourDnaResults`; re-seeded `PaintColours` (new `cabStar`, `chromaBand` columns) |
| 4 | Added `saturationPreference` to `ColourDnaResults` |
| 5 | Created `ColourInteractions` table; added `driftPromptDismissedAt` to `UserProfiles` |
| 6 | Added renter constraint columns to `UserProfiles` (`canPaint`, `canDrill`, `keepingFlooring`, `isTemporaryHome`, `reversibleOnly`) |
| 7-16 | Products, shopping list, moodboards, samples, notifications, partner profiles, diary entries |
| 17 | Added `supabaseUserId` to `UserProfiles` for auth identity linking |

### 5.5 Repositories

Each repository wraps direct Drift queries with a clean API. Repositories are instantiated via Riverpod providers with `keepAlive: true`.

| Repository | Key Operations |
|---|---|
| `PaintColourRepository` | `getAll`, `getByBrand`, `getByFamily`, `getByUndertone`, `search`, `findClosestMatches` (CIEDE2000), `findCrossBrandMatches` |
| `RoomRepository` | CRUD for rooms and locked furniture, `watchAllRooms` (stream), `roomCount` |
| `ColourDnaRepository` | `getById`, `watchLatest` (stream) |
| `PaletteRepository` | `watchForResult` (stream by DNA result ID) |
| `RedThreadRepository` | `watchThreadColours` (stream), `getThreadColours`, `getAdjacencies` |
| `UserProfileRepository` | `getOrCreate` (single-row pattern), `linkSupabaseUser` |
| `ColourInteractionRepository` | Colour interaction tracking for drift detection |

### 5.6 Seed Data

**`SeedDataService`** loads `assets/data/paint_colours.json` on first launch:
1. Checks if paint colours exist in DB (`count() > 0`).
2. If empty, parses JSON, computes Lab values + classifies undertone/family/chroma from hex, and batch-inserts.
3. Supports forced re-seed (deletes all paints, reloads).

**Other bundled data files:**
- `quiz_content.json` -- Quiz card definitions with family weights.
- `palette_families.json` -- Palette family metadata.
- `floor_plan_templates.json` -- Floor plan layout templates for the red thread visualiser.
- `retailer_configs.json` -- UK paint retailer URLs (Farrow & Ball, Little Greene, Dulux Heritage, Crown) with product/search URL templates and affiliate support.

---

## 6. Data Models

### 6.1 Key Entities and Relationships

```
UserProfile (single row)
  |-- colourDnaResultId --> ColourDnaResult
                              |-- systemPaletteJson (JSON blob: SystemPalette)
                              |-- primaryFamily, secondaryFamily
                              |-- archetype, dnaConfidence
                              |-- undertoneTemperature, saturationPreference
                              |-- PaletteColour[] (via colourDnaResultId FK)

Room
  |-- heroColourHex, betaColourHex, surpriseColourHex
  |-- direction, usageTime, moods, budget
  |-- isRenterMode, wallColourHex
  |-- LockedFurniture[] (via roomId FK)
  |-- RoomAdjacency[] (via roomIdA/roomIdB)

RedThreadColour
  |-- paintColourId --> PaintColour (optional)

PaintColour (seed data)
  |-- brand, name, code, hex
  |-- labL, labA, labB (CIE L*a*b*)
  |-- lrv (Light Reflectance Value)
  |-- undertone (warm/cool/neutral)
  |-- paletteFamily (7 families)
  |-- cabStar, chromaBand (muted/mid/bold)
  |-- approximatePricePerLitre (optional, for budget filtering)

ColourInteraction (append-only log)
  |-- interactionType, hex, contextScreen, contextRoomId
```

### 6.2 SystemPalette (Embedded JSON)

The `SystemPalette` is stored as a JSON string in `ColourDnaResults.systemPaletteJson`. It contains role-based colour assignments:

| Role | Count | Purpose |
|---|---|---|
| `trimWhite` | 1 | White/off-white for ceilings and trim |
| `dominantWalls` | 1-2 | Primary wall colours |
| `supportingWalls` | 2-3 | Secondary/adjacent room walls |
| `deepAnchor` | 1 | Dark grounding colour (feature walls, furniture) |
| `accentPops` | 0-1 | Vivid accent colours (0 for muted users) |
| `spineColour` | 1 | Neutral connector tying rooms together |

Each role contains a `PaintReference` with `paintId`, `hex`, `name`, `brand`, `role`, and `roleLabel`.

---

## 7. Colour Science Engine

The colour science engine is the algorithmic core of the app. It lives in `lib/core/colour/` as pure Dart functions with zero Flutter dependencies, making it fully unit-testable.

### 7.1 Colour Space Pipeline

```
Hex String (#RRGGBB)
  --> sRGB (0-255)
    --> Linear RGB (gamma-corrected)
      --> CIE XYZ (D65 illuminant)
        --> CIE L*a*b* (perceptually uniform)
          --> CIE LCh (cylindrical: lightness, chroma, hue)
```

**Implementation:** `colour_conversions.dart` -- Full bidirectional conversion pipeline following IEC 61966-2-1:1999 (sRGB) with D65 reference white (X=95.047, Y=100.000, Z=108.883).

### 7.2 Colour Difference: CIEDE2000

**Implementation:** `delta_e.dart` -- Full CIEDE2000 (CIE 142-2001) implementation per Sharma, Wu, Dalal (2005). Uses reference conditions kL = kC = kH = 1.

**Usage throughout the app:**
- Paint colour matching (find closest paint to any hex).
- Cross-brand equivalents (find same-colour across brands, threshold dE < 5).
- Palette harmony analysis (detect near-duplicates at dE < 5, disconnected pairs at dE > 50).
- Room coherence checking (thread colour match within dE < 15).
- 70/20/10 beta/surprise candidate selection (dE range filtering).

**Match percentage:** Converts delta-E to a human-readable 0-100% match using a sigmoid curve: `100 * exp(-0.03 * dE^2 / 10)`.

### 7.3 Colour Classification

**Undertone classification** (`undertone.dart`):
- Weighted score: `warmth = b* * 0.7 + a* * 0.3`
- Thresholds: warm (> 5.0), cool (< -5.0), neutral (in between)
- Returns `UndertoneResult` with classification and confidence (0.0-1.0).

**Palette family classification** (`palette_family.dart`):
Seven families classified by L* (lightness) and chroma thresholds, checked in priority order:
1. **Darks:** L* < 25
2. **Pastels:** L* > 70, chroma < 30
3. **Brights:** L* 40-75, chroma > 50
4. **Jewel Tones:** L* 20-55, chroma 30-60
5. **Earth Tones:** L* 30-65, chroma 15-45, warm-leaning (b* > 0, a* > -5)
6. **Warm Neutrals:** L* > 40, chroma < 15, b* > 0
7. **Cool Neutrals:** fallback

**Chroma band classification** (`chroma_band.dart`):
- Muted: Cab* < 25
- Mid: 25-50
- Bold: Cab* > 50

### 7.4 Colour Relationships

**Implementation:** `colour_relationships.dart` -- Hue-angle-based operations in LCh space:

| Function | Hue Rotation | Description |
|---|---|---|
| `complementary(lab)` | +180 degrees | Vibrant contrast |
| `analogous(lab)` | +/- 30 degrees | Harmonious, cohesive |
| `triadic(lab)` | +120, +240 degrees | Balanced vibrancy |
| `splitComplementary(lab)` | +150, +210 degrees | Softer contrast |

**Pair classification** (`colour_plan_harmony.dart`):

| Hue Difference | Classification |
|---|---|
| 0-35 degrees | Analogous |
| 110-130 degrees | Triadic |
| 140-160 degrees | Split-complementary |
| 165-195 degrees | Complementary |

### 7.5 Light Simulation

**Kelvin simulation** (`kelvin_simulation.dart`):
- Converts colour temperature (Kelvin) to RGB tint using the Tanner Helland polynomial approximation.
- Blends tint with base colour at configurable opacity (default 15%).
- Kelvin lookup table maps `CompassDirection x UsageTime` to temperature values for UK natural light conditions (e.g., north-facing evening = 9000K, south-facing evening = 4000K).

**Light recommendations** (`light_recommendations.dart`):
- 16-combination matrix of compass direction x usage time.
- Each entry provides: summary, detailed recommendation, preferred undertone, and avoid undertone.
- Based on Sowerby's colour-light interaction principles.

### 7.6 Palette Feedback System

**Impact analysis** (`palette_feedback.dart: describePaletteImpact`):
- When a colour is added, describes its relationship to existing palette colours.
- Checks named hue relationships (prioritised: complementary > triadic > split-complementary > analogous).
- Falls back to undertone balance observations, then tonal proximity.

**Role analysis** (`palette_feedback.dart: describeColourRole`):
- When removing a colour, describes its role (relationship anchor, undertone contributor, chroma contributor).
- Generates warnings about what removing it would break.

**Palette health** (`palette_feedback.dart: analysePaletteHealth`):
- Holistic analysis of a full palette across five dimensions:
  1. **Pairwise hue analysis** -- detects near-duplicates, disconnected pairs, and named relationships.
  2. **Lightness spread** -- flags clustering (range < 15 L*) or praises good range (> 50 L*).
  3. **Chroma diversity** -- detects all-muted or all-bold palettes.
  4. **Family coherence** -- identifies dominant family (>= 60% of colours).
  5. **Undertone balance** -- checks warm/cool distribution.
- Returns verdict string, explanation, clashes, strengths, insights, and actionable suggestion.

### 7.7 Colour Suggestions Engine

**Implementation:** `colour_suggestions.dart` -- Context-aware suggestion generation.

`PickerContext` captures the full context: picker role (hero/beta/surprise/palette/redThread), existing colours, room properties, DNA hexes, red thread hexes, undertone, and DNA anchors.

Generates up to 5 ranked `ColourSuggestion` entries per picker, using slot-based allocation to guarantee category diversity (DNA match, complementary, analogous, triadic, direction-appropriate, family complement, red thread, tonal neighbour).

---

## 8. Feature Modules

### 8.1 Onboarding (Colour DNA Quiz)

**Location:** `lib/features/onboarding/`

**Flow:** 3-stage onboarding quiz managed by `QuizNotifier` (StateNotifier):
- **Stage 1:** 4 memory prompts -- user picks 1 card from 6-8 options each. Cards carry family weights.
- **Stage 2:** 8 room images -- multi-select. Selection count is normalised (budget = 4, so selecting 1 card = 4x weight, selecting 8 = 0.5x each).
- **Stage 3:** Property context -- optional metadata (property type, era, tenure, project stage).

**Weight calculation** (`quiz_weight_calculator.dart`):
- Stage 1: 50% weight. Stage 2: 40% weight (normalised). Stage 3: 10% (reserved).
- Consistency bonus: if 3+ of 4 Stage 1 cards agree on the same primary family, +2 bonus.
- Confidence scoring: high (clear winner), medium (top two close), low (no clear winner).

**Palette generation** (`palette_generator.dart`):
1. Sort families by weight to determine primary and secondary.
2. Collect candidates from primary (60%) and secondary (40%) families.
3. Soft-sort candidates by undertone preference then saturation preference.
4. Select with L* (lightness) spread across deterministic buckets.
5. Add 1-2 surprise colours from a complementary family.
6. Result: ~10 `PaletteColourEntry` items.

**System palette generation** (`system_palette_generator.dart`):
Role-based palette using progressive relaxation (strict filters first, widening if too few candidates):
1. **Trim White:** Closest white to primary family's average a*/b*, L* > 90 (relaxes to > 80).
2. **Dominant Walls:** 1-2 from primary family, L* 55-80, optionally blended with property era affinity (80% user / 20% era).
3. **Supporting Walls:** 2-3 from primary+secondary, min dE 10 from dominant.
4. **Deep Anchor:** 1 dark colour (L* < 45), closest dE to dominant wall.
5. **Accent Pops:** 0-1 from complementary families, Cab* > 30 (0 for muted saturation preference).
6. **Spine Colour:** 1 neutral mid-tone (L* 60-80, Cab* < 30), minimising summed dE to all wall colours.

**Undertone temperature derivation** (`undertone_temperature.dart`):
Winner-takes-all from quiz tally; returns neutral if gap <= 2 between top two.

**Saturation preference derivation** (`undertone_temperature.dart`):
Winner-takes-all from quiz tally; defaults to mid on tie.

**Archetype mapping** (`archetype_definitions.dart`):
Maps `PaletteFamily x ChromaBand` to one of 14 colour archetypes (e.g., Warm Neutrals + Muted = "The Cocooner"). Each archetype has rich content: headline, description, style tips, best materials/moods/wood tones/metal finishes/fabrics, contrast level, and accent saturation guidance.

**DNA drift detection** (`dna_drift.dart`):
Analyses recent `ColourInteraction` records against the user's DNA result. Computes per-dimension drift scores (family, chroma, undertone) and an overall weighted score (40% family, 30% chroma, 30% undertone). Drift > 0.4 on any axis triggers a suggestion for the new preference.

### 8.2 Rooms (70/20/10 Planner)

**Location:** `lib/features/rooms/`

**Screens:** `RoomListScreen`, `CreateRoomScreen`, `RoomDetailScreen`.

**Room creation** captures: name, compass direction (optional), usage time, moods (multi-select from 8 options), budget bracket, and renter mode toggle.

**70/20/10 colour plan** (`seventy_twenty_ten.dart`):
- **Hero (70%):** User-selected wall colour (or key textile for renters who can't paint).
- **Beta (20%):** Algorithm-selected supporting colour using progressive dE relaxation (10-35 strict, down to 3-70 fallback), filtered by undertone preference from DNA or light direction.
- **Surprise (10%):** From complementary family, dE > 15 from hero.
- **Dash:** Optional red thread colour -- closest paint match to any thread hex.
- Supports **locked furniture:** existing items pre-fill their tier; the algorithm generates only for unfilled tiers. Conflicting locked items (dE > 40) trigger warnings.
- **Budget filtering:** Filters candidate paints by price per litre (affordable <= GBP 25, mid-range GBP 15-50, investment > GBP 30).

**Colour plan harmony** (`colour_plan_harmony.dart`):
Analyses the harmony of a generated 70/20/10 plan. Classifies all pairwise hue relationships, detects near-duplicates (dE < 5) and bold disconnected pairs (dE > 50), and generates educational verdicts (e.g., "Complementary contrast", "Analogous harmony").

**Room story** (`room_story.dart`):
Generates 2-3 sentence contextual explanations of why a room's colours work together, incorporating light direction + undertone alignment, colour relationships, and mood/renter context.

**Light recommendations** (`light_recommendations.dart`):
16-combination matrix providing direction-aware colour guidance based on Sowerby's research. Each entry includes preferred and avoid undertones.

**Room colour psychology** (`room_colour_psychology.dart`):
Feature-specific constants for room-type colour guidance.

### 8.3 Renter Mode

**Three-mode strategy pattern** via `RoomModeConfig`:

| Mode | Condition | Hero Meaning | Canvas |
|---|---|---|---|
| Owner | Not renter | Wall colour | Paint-first 70/20/10 |
| Renter Can Paint | Renter + can paint | Approved wall colour | Wall is fixed but choosable |
| Renter Can't Paint | Renter + can't paint | Key textile colour | Textiles-only design |

All labels, prompts, and descriptions adapt per mode. The config is a `const` object selected by `RoomModeConfig.forRoom()` and consumed by screens via `roomModeConfigProvider`.

**Renter constraints** are captured during onboarding: `canPaint`, `canDrill`, `keepingFlooring`, `isTemporaryHome`, `reversibleOnly`.

### 8.4 Red Thread (Whole-Home Coherence)

**Location:** `lib/features/red_thread/`

**Concept:** 2-4 unifying colours that appear in some form in every room, creating subconscious whole-home coherence (from Sowerby's "red thread" principle).

**Coherence checker** (`coherence_checker.dart`):
- Checks each room's hero/beta/surprise colours against thread colours using delta-E < 15 threshold.
- Returns a `CoherenceReport` with per-room connection status and overall coherence flag.

**Floor plan visualiser** (`floor_plan_painter.dart`, `floor_plan_template.dart`):
- Loads templates from `floor_plan_templates.json`.
- Custom painter renders room layouts with colour-coded thread connections.

**Room adjacencies:** Graph of which rooms connect to each other, stored in `RoomAdjacencies` table and used for side-by-side colour comparison.

### 8.5 Palette (Personal Colour Palette)

**Location:** `lib/features/palette/`

**Screens:** `PaletteScreen` with `PaletteGrid`.
**Widgets:** `ColourDetailSheet` (paint info + cross-brand matches), `ColourReviewSheet` (palette health analysis).

Displays the user's DNA-generated palette colours with premium-gated editing (requires Palette Plus). Provides health analysis via `analysePaletteHealth`.

### 8.6 Explore (Learning & Tools)

**Location:** `lib/features/explore/`

- **ExploreScreen:** Hub for learning content and colour tools.
- **ColourWheelScreen:** Interactive colour wheel with relationship visualisation.
- **WhiteFinderScreen:** White/off-white recommendation tool based on room direction and existing palette undertones. Accepts optional `roomId` query parameter.
- **PaintLibraryScreen:** Browse and search the full paint colour database.
- **Paint matching** (`paint_match.dart`): Cross-brand paint matching using CIEDE2000.
- **Learn content** (`learn_content.dart`): Educational articles about colour theory.

### 8.7 Home (Dashboard)

**Location:** `lib/features/home/`

- **HomeScreen:** Dashboard with DNA summary card and contextual next-action guidance.
- **Next action logic** (`next_action.dart`): Determines what the user should do next based on their current state (complete onboarding, create first room, add red thread colours, etc.).

### 8.8 Capture

**Location:** `lib/features/capture/`

**Status:** Placeholder. `CaptureScreen` exists but colour capture from camera is not yet implemented as a full feature.

### 8.9 Profile

**Location:** `lib/features/profile/`

- **ProfileScreen:** User settings, subscription tier display, colour blind mode toggle, QA mode access (debug builds only).

### 8.10 Subscription

**Location:** `lib/features/subscription/`

- **PaywallScreen:** Subscription upgrade UI.
- **Tiers:** Free, Plus, Pro, Project Pass. Premium features are gated via `PremiumFeature.requiredTier` checks.
- **Premium gates:** `PremiumGate` widget (in `core/widgets/`) handles paywall presentation.
- **Note:** Actual payment processing is not implemented -- subscription state is managed locally.

### 8.11 Dev / QA Mode

**Location:** `lib/features/dev/`

- **QaModeScreen:** Debug-only screen accessible at `/dev` route.
- **Features:** State toggles (subscription tier, onboarding status, colour blind mode), data seeding, one-tap navigation to any screen.
- **QaSeedService:** Generates test data (rooms, palette colours, thread colours) for QA testing.

---

## 9. Subscription & Premium Gating

**Tiers (enum `SubscriptionTier`):**

| Tier | Index | Gated Features |
|---|---|---|
| Free | 0 | Onboarding quiz, palette view, explore tools (limited) |
| Plus | 1 | Palette editing, light recommendations, 70/20/10 planner, red thread, unlimited moodboards, colour capture to palette, PDF export |
| Pro | 2 | Partner mode |
| Project Pass | 3 | (Reserved) |

**Implementation:** `subscriptionTierProvider` holds current tier. `PremiumFeature` enum maps each feature to its `requiredTier`. The `PremiumGate` widget wraps gated UI and presents the paywall when the user's tier is insufficient.

---

## 10. Testing Strategy

### 10.1 Test Coverage

The test suite (`test/`) contains **34 test files** across three categories:

**Colour science unit tests** (8 files):
- `colour_conversions_test.dart` -- Hex/RGB/Lab/LCh round-trip accuracy.
- `delta_e_test.dart` -- CIEDE2000 against reference values.
- `colour_relationships_test.dart` -- Hue rotation and pair classification.
- `colour_suggestions_test.dart` -- Context-aware suggestion generation.
- `kelvin_simulation_test.dart` -- Kelvin-to-RGB and light simulation.
- `undertone_test.dart` -- Undertone classification accuracy.
- `chroma_band_test.dart` -- Chroma band thresholds.
- `palette_feedback_test.dart` -- Impact analysis, role analysis, health summaries.

**Feature logic unit tests** (17 files):
- Onboarding: `palette_generator_test.dart`, `quiz_state_test.dart`, `quiz_weight_calculator_test.dart`, `quiz_weight_balance_test.dart`, `system_palette_generator_test.dart`, `undertone_temperature_test.dart`, `archetype_definitions_test.dart`, `era_affinities_test.dart`, `dna_drift_test.dart`, `system_palette_test.dart` (model serialisation).
- Rooms: `seventy_twenty_ten_test.dart`, `light_recommendations_test.dart`, `colour_plan_harmony_test.dart`, `room_story_test.dart`, `room_colour_psychology_test.dart`.
- Red thread: `coherence_checker_test.dart`, `floor_plan_template_test.dart`.

**Repository / service tests** (5 files):
- `paint_colour_repository_test.dart`, `room_repository_test.dart`, `user_profile_repository_test.dart`.
- `seed_data_service_test.dart`, `retailer_config_test.dart`.

**Integration tests** (1 file):
- `palette_pipeline_test.dart` -- End-to-end test of the quiz-to-palette pipeline.

**Widget / provider tests** (3 files):
- `colour_wheel_providers_test.dart`, `colour_review_sheet_test.dart`, `room_mode_config_test.dart`.

### 10.2 Testing Approach

- **Pure function testing:** Business logic in `logic/` directories is tested as pure functions with no mocking needed.
- **Snapshot-style tests:** Algorithm outputs (palette generation, weight calculation) are tested with fixed inputs and asserted outputs.
- **Golden path + boundary tests:** Quiz weight calculator tests include pure inputs, mixed inputs, minimum input, maximum input, and contradictory input.
- **Delta-E assertions:** System palette tests assert undertone consistency across generated colours.
- **Mocking:** `mocktail` is available but primarily used for repository tests (mocking the database).
- **Linting:** `very_good_analysis: ^7.0.0` for strict Dart analysis rules.

---

## 11. Build & Deploy

### 11.1 Build System

- **Framework:** Flutter (Dart SDK ^3.10.4)
- **Code generation:** `build_runner` for Riverpod generators (`riverpod_generator`), Drift schema generation (`drift_dev`), and Freezed/JSON serialisation (available but not actively used for models).
- **Build command:** `dart run build_runner build --delete-conflicting-outputs`
- **Analysis:** `flutter analyze`
- **Tests:** `flutter test`
- **Run:** `flutter run -d emulator-5554`

### 11.2 Assets

- `assets/data/` -- JSON seed data files (paint colours, quiz content, floor plans, retailer configs, palette families).
- `assets/images/` -- Image assets (currently empty, placeholder `.gitkeep`).

### 11.3 Key Dependencies

| Category | Package | Version | Purpose |
|---|---|---|---|
| State | `flutter_riverpod` | ^2.6.1 | State management |
| State | `riverpod_annotation` | ^2.6.1 | Codegen annotations |
| Routing | `go_router` | ^14.8.1 | Declarative routing |
| Database | `drift` | ^2.25.0 | SQLite ORM |
| Database | `sqlite3_flutter_libs` | ^0.5.32 | SQLite native bindings |
| Serialisation | `freezed_annotation` | ^2.4.4 | Immutable model annotations (scaffolded) |
| Serialisation | `json_annotation` | ^4.9.0 | JSON serialisation annotations (scaffolded) |
| UI | `google_fonts` | ^6.2.1 | Typography |
| UI | `flutter_svg` | ^2.0.17 | SVG rendering |
| UI | `smooth_page_indicator` | ^1.2.0+3 | Page indicators |
| Export | `pdf` | ^3.11.2 | PDF generation |
| Export | `printing` | ^5.13.5 | PDF printing/sharing |
| Sharing | `share_plus` | ^10.1.4 | Native share sheet |
| Hardware | `sensors_plus` | ^6.1.1 | Device sensors |
| Hardware | `flutter_compass` | ^0.8.0 | Compass for room direction |
| Backend | `supabase_flutter` | ^2.9.0 | Backend scaffold (not active) |
| Utilities | `url_launcher` | ^6.3.1 | Open retailer URLs |
| Utilities | `uuid` | ^4.5.1 | Generate unique IDs |
| Utilities | `intl` | ^0.20.2 | Internationalisation |
| Utilities | `collection` | ^1.19.1 | Collection utilities |
| Utilities | `path_provider` | ^2.1.5 | File system paths |

### 11.4 Partially Implemented / Scaffolded

- **Supabase backend:** Dependency present but not connected to any feature logic.
- **Freezed models:** Dev dependency installed but data models use manual Dart classes with `copyWith`.
- **Camera capture:** `CaptureScreen` exists but colour extraction from camera is not implemented.
- **Payment processing:** Subscription UI exists but actual payment integration is not implemented.
- **Partner mode:** Listed as a Pro feature but not implemented.
- **Image assets:** Asset directory exists but is empty (UI uses Material icons).
