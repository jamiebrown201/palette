# Colour DNA 2.0 -- Spec for AI-Assisted Development

> **Purpose:** This is the single source of truth for upgrading the Colour DNA feature. It is written for AI coding assistants (Claude Code, Cursor, Copilot) to consume as context when implementing changes. Every spec includes rationale, data model changes, algorithm logic, acceptance criteria, and integration points.
>
> **How to use this file:** Reference the relevant Epic when prompting your AI assistant. Each Epic is self-contained. Work through them in priority order. The AI assistant should read the full Epic before writing any code.

---

## Table of Contents

1. [AI-Assisted Development: Best Practices](#1-ai-assisted-development-best-practices)
2. [Current State Summary](#2-current-state-summary)
3. [Core Diagnosis](#3-core-diagnosis)
4. [Architecture Principles](#4-architecture-principles)
5. [Pre-requisite: Paint Database Enrichment](#5-pre-requisite-paint-database-enrichment)
6. [Epic A: Quiz Weight Normalisation and Confidence Score](#epic-a-quiz-weight-normalisation-and-confidence-score)
7. [Epic B: Undertone Temperature Axis](#epic-b-undertone-temperature-axis)
8. [Epic C: Saturation/Chroma Preference Axis](#epic-c-saturationchroma-preference-axis)
9. [Epic D: Role-Based System Palette](#epic-d-role-based-system-palette)
10. [Epic E: Colour Archetype Narrative System](#epic-e-colour-archetype-narrative-system)
11. [Epic F: Property Context Activation](#epic-f-property-context-activation)
12. [Epic G: DNA to 70/20/10 Planner Integration](#epic-g-dna-to-7020-10-planner-integration)
13. [Epic H: DNA to Red Thread Integration](#epic-h-dna-to-red-thread-integration)
14. [Epic I: DNA to Explore Tools Integration](#epic-i-dna-to-explore-tools-integration)
15. [Epic J: Quiz UX and Content Improvements](#epic-j-quiz-ux-and-content-improvements)
16. [Epic K: DNA Reveal Experience](#epic-k-dna-reveal-experience)
17. [Epic L: DNA Evolution -- Learn from User Behaviour](#epic-l-dna-evolution----learn-from-user-behaviour)
18. [Implementation Order and Dependencies](#implementation-order-and-dependencies)
19. [QA Strategy](#qa-strategy)
20. [Success Metrics](#success-metrics)

---

## 1. AI-Assisted Development: Best Practices

These guidelines apply to every Epic in this document. Share them with your AI coding assistant at the start of each session.

### 1.1 Spec-Driven Prompting

- **Always reference the spec.** When starting work on an Epic, paste or reference the full Epic section (not just the title). The AI needs the rationale, data model, algorithm, and acceptance criteria to produce correct code.
- **One Epic per session.** Avoid mixing Epics in a single prompt. Each Epic is designed as a coherent unit of work.
- **Include current file contents.** When modifying existing files (e.g., `palette_generator.dart`, `colour_suggestions.dart`), paste the current implementation so the AI can see what it is changing.
- **State constraints explicitly.** For example: "Do not delete the existing `colourHexes` field. Keep it for backward compatibility alongside the new `systemPalette`."

### 1.2 Code Quality Rules

- **Backward compatibility is mandatory.** Every change must keep existing features working. New fields are additive. Old fields are preserved until explicitly deprecated.
- **No randomness in algorithms.** Use deterministic selection (sorted candidates, reproducible tiebreakers) so that the same quiz inputs always produce the same DNA output. This makes testing possible.
- **Constants over database lookups.** Small, stable datasets (era affinities, archetype definitions, room colour psychology) should be Dart constants, not database entries.
- **Prefer composition over replacement.** Wrap the existing palette generator rather than rewriting it. The new system palette generation can call the old logic internally and then layer role assignment on top.

### 1.3 Testing Approach

- **Snapshot tests for algorithm changes.** For every algorithm change, create 5-10 representative quiz input fixtures and assert the output (primary family, secondary family, undertone, saturation, archetype, system palette roles). These snapshots catch regressions.
- **Golden path tests.** For each axis (family, undertone, saturation), create at least one "pure" test case where every quiz answer points the same direction, and verify the output reflects that clearly.
- **Boundary tests.** Test what happens with minimum input (only Stage 1, no Stage 2 selections), maximum input (all Stage 2 cards selected), and contradictory input (warm Stage 1 + cool Stage 2).
- **Delta-E assertions.** For system palette outputs, assert that all colours within the palette have consistent undertone (e.g., all warm-tagged or all neutral-tagged, with at most 1 exception for the surprise colour).

### 1.4 File Organisation

When creating new files, follow this structure:

```
lib/
  features/
    colour_dna/
      models/
        colour_dna_result.dart      // Updated data model
        colour_archetype.dart       // Archetype definitions
        system_palette.dart         // Role-based palette model
        dna_axes.dart               // Undertone, saturation, confidence types
      logic/
        palette_generator.dart      // Updated algorithm
        quiz_weight_calculator.dart // Normalisation logic (new)
        archetype_mapper.dart       // Quiz result to archetype (new)
        undertone_classifier.dart   // Paint undertone classification (new)
      data/
        era_affinities.dart         // Property era colour affinities (new)
        archetype_definitions.dart  // Archetype content (new)
        room_colour_psychology.dart // Room-type guidance (new)
```

---

## 2. Current State Summary

### What Exists

- **Quiz:** 3-stage onboarding. Stage 1 = 4 memory prompts (pick 1 of 6-8 cards each). Stage 2 = 8 room images (multi-select). Stage 3 = property context (optional metadata, never used).
- **Algorithm:** Sum all `familyWeights` from selected cards. Highest = primary family, second = secondary. Pull ~10 paints from DB matching families (60/40 split), selected via L\* lightness bucket spread. Add 1-2 surprise colours from the complementary family.
- **Output:** `ColourDnaResult` with `primaryFamily`, optional `secondaryFamily`, `colourHexes` (list of ~10 hex strings), property metadata.
- **Downstream usage:** Picker suggestions use `dnaHexes.first` as anchor. Home screen shows DNA card. Palette screen shows full palette with premium-gated editing.
- **Infrastructure:** 200+ UK paints (Farrow & Ball, Little Greene, Dulux Heritage, Crown). CIE Lab colour space. CIEDE2000 delta-E. Kelvin light simulation. 16-combo light recommendation matrix. Colour relationship classification.

### What DNA Does NOT Do (Current Gaps)

- Does not output role-based colours (which are walls, which are trim, which are accents)
- Does not capture or use undertone preference
- Does not capture or use saturation/chroma preference
- Does not use property context (era, tenure) in any algorithm
- Does not connect to 70/20/10 planner (planner ignores DNA)
- Does not pre-suggest Red Thread colours
- Does not provide a narrative/archetype (just a family name)
- Stage 2 multi-select has no normalisation (can overpower Stage 1)
- Downstream anchoring uses `dnaHexes.first` which is arbitrary
- Quiz room images are placeholder icons, not photographs

---

## 3. Core Diagnosis

Three independent research efforts converge on the same five findings:

1. **DNA should output a role-based palette system, not a flat list.** Professional interior design works with dominant walls + supporting walls + trim white + accent + grounding anchor. Users need to know which colour goes where, not just which colours to consider. Target: 6-8 colours with assigned roles.

2. **Undertone consistency is the foundation of palettes that "feel right."** Colours with matching undertones harmonise even across different hues. Colours with clashing undertones look wrong even when theoretically complementary. The current system has zero undertone awareness.

3. **Saturation preference is a missing dimension.** "Earth tones" could mean muted sage or vivid terracotta. Two users with identical family scores may need radically different palettes. The system cannot currently distinguish between them.

4. **Property context and light direction are not optional metadata.** Light direction is the single biggest environmental variable in colour selection. Property era shapes which colours work with architectural features. Both are collected and wasted.

5. **The DNA is a sidecar, not the centre of gravity.** It should feed the 70/20/10 planner, pre-suggest the Red Thread, filter the White Finder, and inform room mood scoring. Currently it only weakly influences picker suggestions.

---

## 4. Architecture Principles

These principles govern all implementation decisions:

1. **User preference always wins.** Era biasing, undertone matching, and room psychology inform and suggest. They never force. The user chose their answers; respect that.

2. **Soft constraints with clear explanation.** When the system detects a potential mismatch (e.g., cool palette in a north-facing room), surface a helpful note explaining why and what to consider. Do not silently override.

3. **Education is the product.** Every recommendation is an opportunity to explain _why_. "This blue has warm undertones that complement your north-facing room" teaches the user something they carry beyond the app.

4. **6-8 colours for a whole house, graduated in depth.** Vary the depth, not the undertone. Lighter and darker versions of the same temperature create a seamless flow room to room.

5. **Deterministic algorithms.** Same inputs produce same outputs. No randomness in palette generation. Use sorted candidates with reproducible tiebreakers.

6. **Additive, not destructive.** All integrations are suggestions the user can override. DNA pre-populates; it never locks.

---

## 5. Pre-requisite: Paint Database Enrichment

Before implementing Epics B, C, or D, enrich the paint database with computed properties. This is a one-time effort that unlocks multiple Epics.

### 5.1 Compute CIE Lab Chroma (Cab\*) for Every Paint

```
Cab* = sqrt(a*^2 + b*^2)
```

You already have Lab values for every paint. This is a straightforward computation. Store as a new field on the paint model.

### 5.2 Classify Undertone Temperature for Every Paint

Use the Lab `b*` axis (yellow-blue) as the primary signal and `a*` (red-green) as secondary:

```
if b* > 5 OR (b* > 0 AND a* > 5):
  undertone = warm
elif b* < -5 OR (b* < 0 AND a* < -5):
  undertone = cool
else:
  undertone = neutral
```

**Manual review required for:** whites, off-whites, and greys where undertone is most critical and most subtle. Cross-reference against Farrow & Ball's published neutral groupings where available.

### 5.3 Classify Chroma Band for Every Paint

Using the computed Cab\*:

```
if Cab* < 25:
  chromaBand = muted
elif Cab* <= 50:
  chromaBand = mid
else:
  chromaBand = bold
```

### 5.4 Data Model Addition

```dart
class PaintColour {
  // ... existing fields ...
  final double cabStar;                    // CIE Lab chroma
  final UndertoneTemperature undertone;    // warm, cool, neutral
  final ChromaBand chromaBand;             // muted, mid, bold
}

enum UndertoneTemperature { warm, cool, neutral }
enum ChromaBand { muted, mid, bold }
```

### Acceptance Criteria

- Every paint in the database has `cabStar`, `undertone`, and `chromaBand` values
- Automated classification covers 80%+ correctly; remaining edge cases are manually reviewed
- A spot-check of 20 well-known paints (e.g., Farrow & Ball Railings, Hague Blue, Elephant's Breath, Pointing) confirms classifications match professional consensus

---

## Epic A: Quiz Weight Normalisation and Confidence Score

**Priority:** P0 (no UI changes, immediate algorithm quality improvement)
**Dependencies:** None
**Estimated scope:** Small

### Problem

Stage 2 multi-select has unbounded impact. A user selecting 6 room cards gets 6x the Stage 2 weight contribution compared to someone selecting 1 card. This makes the DNA result sensitive to _how many images you tap_ rather than _what you prefer_. Stage 1's carefully designed memory prompts can be overridden by enthusiastic tapping in Stage 2.

### What to Build

#### A1: Normalise Stage 2 Contributions

After collecting all Stage 2 selections, normalise their combined contribution:

```
For each family in the combined Stage 2 weight map:
  normalisedWeight = rawWeight * (STAGE_2_BUDGET / numberOfCardsSelected)

where STAGE_2_BUDGET = 4 (matching Stage 1's 4 questions)
```

This means selecting 1 room card contributes 4x its raw weight (strong signal from a single choice), while selecting 8 room cards contributes 0.5x each (diluted signal from many choices). The total Stage 2 contribution stays roughly constant regardless of selection count.

#### A2: Apply Stage Weighting

After normalisation, apply stage multipliers to balance the overall signal:

```
Stage 1 (memory prompts):  50% of total signal
Stage 2 (room preferences): 40% of total signal
Stage 3 (property context):  10% of total signal (reserved for future use)
```

Implementation:

```
finalWeights[family] =
  (stage1Weights[family] * 0.50) +
  (normalisedStage2Weights[family] * 0.40) +
  (stage3Weights[family] * 0.10)  // currently always 0
```

#### A3: Consistency Bonus

If 3 or more of the 4 Stage 1 memory cards agree on the same primary family (i.e., the top family in the Stage 1 tally has weight from 3+ cards), add a consistency bonus of +2 to that family. This rewards clear, decisive preference patterns.

#### A4: DNA Confidence Score

Compute a confidence score based on how decisive the weight distribution is:

```dart
enum DnaConfidence { low, medium, high }
```

Computation:

```
sortedFamilies = sort families by finalWeight descending
topWeight = sortedFamilies[0].weight
secondWeight = sortedFamilies[1].weight
totalWeight = sum of all family weights

if topWeight / totalWeight < 0.25:
  confidence = low   // no clear winner
elif (topWeight - secondWeight) / totalWeight < 0.10:
  confidence = medium  // top two are very close
else:
  confidence = high   // clear primary family
```

Store `dnaConfidence` on `ColourDnaResult`.

**UX implication:** When confidence is `low`, the DNA reveal can frame the result as: "You have eclectic taste! We have started you with a flexible base palette. Refine it as you plan your first room."

### Acceptance Criteria

- Selecting 1 room vs 8 rooms in Stage 2 does not flip the primary family when Stage 1 clearly points one direction
- Same Stage 1 answers with varying Stage 2 selection counts yield a stable primary family (within defined bounds)
- `dnaConfidence` is `high` when all 4 memory prompts point to the same family
- `dnaConfidence` is `low` when memory prompts are evenly split across 3+ families
- 10 snapshot test fixtures covering: pure warm, pure cool, mixed, minimal Stage 2, maximal Stage 2

---

## Epic B: Undertone Temperature Axis

**Priority:** P1
**Dependencies:** Paint database enrichment (section 5)
**Estimated scope:** Medium

### Problem

The current system captures hue family preference but not undertone temperature. Two users with identical family scores may need fundamentally different palettes. A "cool neutrals" lover could need warm-leaning greys (greige) or blue-toned greys, and the system cannot distinguish.

Professional colour consultants describe undertone as the single most important factor in palettes that feel harmonious. Colours with mismatched undertones clash even within the same family.

### What to Build

#### B1: Tag Every Quiz Card with Undertone Temperature

Add an `undertoneTemp` value (warm/cool/neutral) to each quiz card's metadata, alongside the existing `familyWeights`:

**Stage 1 examples:**
| Card | Hex | Undertone |
|------|-----|-----------|
| Sun-warmed yellow | #E8CE78 | warm |
| Garden green | #7A8870 | neutral |
| Clear sky blue | #8ABED6 | cool |
| Terracotta warmth | #C87830 | warm |
| Berry picking | #533946 | cool |
| Creamy blanket | #F4EDDD | warm |

Apply the same tagging to all Stage 1 and Stage 2 cards.

#### B2: Track Undertone Tally

Maintain a running `Map<UndertoneTemperature, int>` alongside the family tally. Each card selection increments the relevant temperature bucket.

#### B3: Derive `undertoneTemperature` from Tally

```
sorted = sort temperature tally descending
if sorted[0].value - sorted[1].value <= 2:
  undertoneTemperature = neutral  // no clear winner, default to flexible
else:
  undertoneTemperature = sorted[0].key  // clear winner
```

#### B4: Filter Palette Generation by Undertone

In `palette_generator.dart`, after selecting paint candidates matching the primary family, apply an undertone preference filter:

```
if undertoneTemperature == warm:
  prefer paints where paint.undertone == warm (weight 70%)
  then paint.undertone == neutral (weight 20%)
  then paint.undertone == cool (weight 10%)

if undertoneTemperature == cool:
  prefer paints where paint.undertone == cool (weight 70%)
  then paint.undertone == neutral (weight 20%)
  then paint.undertone == warm (weight 10%)

if undertoneTemperature == neutral:
  no undertone filtering; accept all
```

**Relaxation:** If fewer than the required number of paints match both family AND preferred undertone, relax to include neutral, then the opposite temperature.

#### B5: Pass Undertone to Downstream Systems

Update `PickerContext` to include `undertoneTemp` so all picker suggestions respect temperature preference.

### Data Model Changes

```dart
// Add to ColourDnaResult
final UndertoneTemperature undertoneTemperature; // warm, cool, neutral

// Add to each quiz card definition
final UndertoneTemperature undertoneTemp;
```

### Acceptance Criteria

- A user who consistently picks warm cards gets a palette where all colours share warm undertones
- A user who picks mixed warm/cool gets `neutral` temperature and a broader palette
- No two paints with opposing undertones appear adjacent in the system palette (the surprise colour is the one allowed exception)
- The White Finder (when integrated in Epic I) respects undertone preference
- 5 snapshot tests covering pure warm, pure cool, neutral, mixed-leaning-warm, mixed-leaning-cool

---

## Epic C: Saturation/Chroma Preference Axis

**Priority:** P2
**Dependencies:** Paint database enrichment (section 5)
**Estimated scope:** Medium

### Problem

"Earth tones" could mean muted terracotta or vivid ochre. "Jewel tones" could mean dusty teal or saturated emerald. The quiz conflates these. A user who picks all muted options and a user who picks all saturated options can end up with the same primary family but need radically different palettes.

### What to Build

#### C1: Tag Every Quiz Card with Saturation

Compute chroma from each card's hex value (convert to Lab, compute `Cab* = sqrt(a*^2 + b*^2)`):

```
if Cab* < 25: saturation = muted
elif Cab* <= 50: saturation = mid
else: saturation = bold
```

Spot-check existing cards:

- "Creamy blanket" (#F4EDDD) -> low chroma -> `muted` ✓
- "Energetic pop" (#E64D42) -> high chroma -> `bold` ✓
- "Scandinavian cabin" (#C8BBA3) -> low chroma -> `muted` ✓
- "Moody & dramatic" (#3B3B35) -> low chroma -> `muted` (dark ≠ bold)

#### C2: Track Saturation Tally

Maintain `Map<ChromaBand, int>` alongside family, temperature, and confidence tallies.

#### C3: Derive `saturationPreference`

Highest tally wins. Store as `ChromaBand` on `ColourDnaResult`.

#### C4: Optional New Quiz Question for Explicit Saturation Signal

Add a 5th memory prompt question that directly targets saturation preference:

**Q5:** _"You are choosing fabric for your favourite armchair. Which feels right?"_

| Card                    | Saturation Weight  |
| ----------------------- | ------------------ |
| Soft, washed linen      | muted: +3          |
| Rich, deep velvet       | bold: +3           |
| Smooth, mid-tone cotton | mid: +3            |
| Faded vintage silk      | muted: +2, mid: +1 |
| Vibrant printed cotton  | bold: +2, mid: +1  |
| Tactile boucle wool     | mid: +2, muted: +1 |

This question carries NO family weights, only saturation weights. It isolates the saturation dimension.

#### C5: Filter Palette Generation by Saturation

When selecting paints from the primary/secondary family:

```
if saturationPreference == muted:
  sort candidates by Cab* ascending, prefer lower chroma
if saturationPreference == bold:
  sort candidates by Cab* descending, prefer higher chroma
if saturationPreference == mid:
  sort candidates by distance from Cab* = 37.5 (midpoint), prefer middle range
```

This is a soft preference (sort order), not a hard filter.

### Data Model Changes

```dart
// Add to ColourDnaResult
final ChromaBand saturationPreference; // muted, mid, bold

// Add to each quiz card definition
final ChromaBand saturation;
```

### Acceptance Criteria

- Two users with the same primary family but different saturation preferences get visibly different palettes (one muted, one vivid)
- The optional Q5 card produces a clear saturation signal when answers are unanimous
- Saturation preference is passed to picker suggestions downstream
- 5 snapshot tests covering muted earth tones vs bold earth tones, muted jewel tones vs bold jewel tones, mid-range

---

## Epic D: Role-Based System Palette

**Priority:** P0/P1 (core structural upgrade)
**Dependencies:** Epic A (normalisation). Benefits from B and C but can work without them using fallback logic.
**Estimated scope:** Medium-Large

### Problem

The current ~10 hex codes have no assigned function. Users get colours but not a plan. Professional designers work with roles: dominant wall, supporting walls, trim, accent, grounding anchor. The output should tell users which colours go where.

### What to Build

#### D1: System Palette Data Model

```dart
class SystemPalette {
  final PaintReference trimWhite;           // 1 undertone-matched white for ceilings/woodwork
  final List<PaintReference> dominantWalls;  // 1-2 main wall colour candidates
  final List<PaintReference> supportingWalls; // 2-3 supporting/secondary wall colours
  final PaintReference deepAnchor;           // 1 grounding dark colour (doors, feature walls, skirting)
  final List<PaintReference> accentPops;     // 0-2 accent colours (only if saturation pref is mid/bold)
  final PaintReference? spineColour;         // 1 candidate "flow" colour for hallways/landings
}

class PaintReference {
  final String paintId;
  final String hex;
  final String name;
  final String brand;
  final String role;       // "trimWhite", "dominantWall", "supportingWall", etc.
  final String? roleLabel; // Human-readable: "Your trim white", "Feature wall candidate"
}
```

#### D2: System Palette Generation Algorithm

The algorithm fills each role slot with specific selection criteria:

**Step 1: Trim White**

- Query all paints where `L* > 90` (true whites/off-whites)
- Compute the average `a*` and `b*` of all paints in the primary family
- Select the white with the lowest CIEDE2000 delta-E to that average `a*, b*` coordinate
- This ensures a warm palette gets a warm white and a cool palette gets a cool white
- If undertone axis is available (Epic B): additionally filter by matching `undertoneTemperature`

**Step 2: Dominant Walls (1-2 candidates)**

- Query paints from the primary family
- Filter to `L*` range 55-80 (appropriate wall colour lightness)
- If saturation pref available (Epic C): sort by chroma preference
- If undertone available (Epic B): filter by undertone
- Select top 1-2 by combined score (family match + lightness appropriateness + chroma fit)

**Step 3: Supporting Walls (2-3 colours)**

- Query paints from primary + secondary families
- Filter to `L*` range 45-75
- Ensure minimum delta-E of 10 from each dominant wall (enough visual distinction)
- Ensure shared undertone with dominant walls
- Select 2-3 with best spread across the L\* range

**Step 4: Deep Anchor (1 colour)**

- Query paints from primary or secondary family
- Filter to `L*` < 45 (noticeably darker)
- If era bias available (Epic F): adjust L\* threshold per era
- Select the candidate with lowest delta-E to the dominant wall (harmonious dark companion)

**Step 5: Accent Pops (0-2 colours)**

- Only generate if saturation preference is `mid` or `bold` (muted users get 0 accents)
- Query paints from the complementary or analogous family
- Must have `Cab* > 30` (needs to actually "pop")
- Must share undertone with the rest of the palette
- Select by maximum hue angle contrast to the dominant wall (visual pop)

**Step 6: Spine Colour (1 candidate)**

- Candidate pool: neutrals + muted mid-tones from dominant/supporting families
- `L*` range 60-80, `Cab*` < 30 (subtle enough for hallways)
- Select the paint minimising summed delta-E distance to all dominant + supporting walls
- This is the most harmonious "bridge" colour in the palette

#### D3: Backward Compatibility

Keep the existing `colourHexes` field populated by extracting all hex values from the system palette:

```dart
colourHexes = [
  systemPalette.trimWhite.hex,
  ...systemPalette.dominantWalls.map((p) => p.hex),
  ...systemPalette.supportingWalls.map((p) => p.hex),
  systemPalette.deepAnchor.hex,
  ...systemPalette.accentPops.map((p) => p.hex),
  if (systemPalette.spineColour != null) systemPalette.spineColour!.hex,
];
```

Existing UI renders from `colourHexes` until screens are upgraded to use `systemPalette`.

#### D4: Update Picker Anchors

Replace the current "anchor on `dnaHexes.first`" with role-based anchors:

```dart
class DnaAnchors {
  final PaintReference? dominantWall;   // for Slot 1: "From your Colour DNA"
  final PaintReference? deepAnchor;     // for Slot 4: "Grounding shade"
  final PaintReference? trimWhite;      // for trim/woodwork picker context
  final PaintReference? accentPop;      // for accent/surprise suggestions
}
```

Update `PickerContext` to accept `DnaAnchors` instead of raw `dnaHexes`.

### Acceptance Criteria

- System palette contains 6-8 paints with distinct roles
- Trim white shares undertone with dominant walls (verify via Lab `b*` sign alignment)
- All palette colours (except accent pops) share undertone temperature
- Deep anchor is noticeably darker than dominant walls (delta-L\* > 15)
- Spine colour has the lowest average delta-E to all other palette members
- Existing `colourHexes` field still populated for backward compatibility
- Picker suggestions use role-based anchors instead of arbitrary first hex
- 10 snapshot tests covering all 7 primary families

---

## Epic E: Colour Archetype Narrative System

**Priority:** P0 (high impact, no algorithm dependency)
**Dependencies:** None for basic version. Enhanced version benefits from Epics B and C.
**Estimated scope:** Medium (content creation + UI + mapping logic)

### Problem

The DNA result shows "Warm Neutrals" and 10 swatches. No personality, no narrative, no confidence-building explanation. The quiz asks deeply personal, emotionally-framed questions but delivers results as a data dump. This is the single biggest missed opportunity for user confidence.

### What to Build

#### E1: Define Archetypes

Create 12-16 archetypes by combining the primary family with saturation preference (if available) or a bold/subtle split. Each archetype needs:

| Field                | Description                                               |
| -------------------- | --------------------------------------------------------- |
| `name`               | Evocative, aspirational, memorable (e.g., "The Cocooner") |
| `headline`           | One-line hook (e.g., "Warmth without fuss")               |
| `description`        | 2-3 sentences capturing the aesthetic personality         |
| `whyItWorks`         | 1-2 sentences explaining the colour theory (educational)  |
| `styleTips`          | 3 practical, specific tips for the archetype              |
| `watchOutFor`        | 1 common pitfall and how to avoid it                      |
| `suggestedRooms`     | Which rooms this palette shines in first                  |
| `suggestedRedThread` | Which palette role makes the best thread colour           |

**Archetype Table (starting set -- expand to 14 with refined axes):**

| Archetype                | Primary Family | Saturation | Description                                        |
| ------------------------ | -------------- | ---------- | -------------------------------------------------- |
| The Cocooner             | warmNeutrals   | muted      | Soft linens, weathered wood, golden-hour light     |
| The Golden Hour          | warmNeutrals   | bold       | Rich caramels, deep honeys, amber glow             |
| The Curator              | coolNeutrals   | muted      | Gallery-like calm, considered restraint            |
| The Monochrome Modernist | coolNeutrals   | bold       | Dramatic charcoals, crisp contrasts                |
| The Romantic             | pastels        | muted      | Gentle blush, powder blue, whispered colour        |
| The Colour Optimist      | pastels        | bold       | Confident lilacs, cheerful mint, playful pink      |
| The Nature Lover         | earthTones     | muted      | Muted olive, stone, quiet clay                     |
| The Storyteller          | earthTones     | bold       | Deep terracotta, burnished ochre, spiced cinnamon  |
| The Velvet Whisper       | jewelTones     | muted      | Dusty teal, muted plum, soft emerald               |
| The Maximalist           | jewelTones     | bold       | Deep sapphire, rich emerald, dramatic ruby         |
| The Brightener           | brights        | any        | Vivid yellows, corals, teals that make rooms alive |
| The Dramatist            | darks          | muted      | Charcoal wraps, deep navy comfort, quiet drama     |
| The Midnight Architect   | darks          | bold       | Jet black statements, inky depth, bold contrast    |
| The Minimalist           | warmNeutrals   | neutral    | Warm whites, pale oak, one perfect accent          |

#### E2: Archetype Mapping Logic

```dart
ColourArchetype mapToArchetype({
  required PaletteFamily primaryFamily,
  required ChromaBand saturationPreference,  // from Epic C, or inferred
}) {
  // If Epic C is not yet implemented, infer saturation from the
  // average Cab* of the generated palette colours:
  //   avgCab < 25 -> muted, 25-50 -> mid (map to nearest), 50+ -> bold

  // Look up in the archetype definitions constant map
  return archetypeMap[primaryFamily]?[saturationPreference]
      ?? archetypeMap[primaryFamily]?[ChromaBand.mid]  // fallback
      ?? defaultArchetype;
}
```

#### E3: Store on DNA Result

```dart
class ColourDnaResult {
  // ... existing fields ...
  final ColourArchetype archetype;
}
```

#### E4: UI Integration Points

- **DNA reveal screen:** Archetype name as hero headline, description below, palette swatches below that
- **Home screen DNA card:** Show archetype name (e.g., "The Cocooner") instead of bare family name
- **Profile screen:** Full archetype card with tips
- **Share card:** Archetype name + palette swatches + Palette watermark (future growth hook)

### Acceptance Criteria

- Every valid combination of primary family + saturation maps to exactly one archetype
- No two archetypes share the same name
- Archetype descriptions are written in second person ("You are drawn to..."), warm but not patronising
- Style tips are specific and actionable (not generic "use colour!")
- A user who retakes the quiz and changes answers gets a different archetype if axes change
- Archetype text has been reviewed by someone with interior design knowledge

---

## Epic F: Property Context Activation

**Priority:** P2
**Dependencies:** Epics B and C (benefits from undertone and saturation axes)
**Estimated scope:** Medium

### Problem

Property type, era, tenure, and light direction are collected but completely ignored. Era and light direction are among the most actionable inputs for UK homes.

### What to Build

#### F1: Add Room Orientation Question

Add one new optional question to Stage 3:

_"Which way does your main living room window face?"_

Options: North / East / South / West / Not sure

Tip text: "Stand at your window and check with your phone's compass app, or think about when you get direct sunlight."

Store as `mainRoomOrientation: Orientation?` on `ColourDnaResult`.

#### F2: Era Colour Affinity Map

Define as a Dart constant:

```dart
const eraAffinities = {
  PropertyEra.victorian: EraAffinity(
    affinityFamilies: [PaletteFamily.jewelTones, PaletteFamily.darks, PaletteFamily.earthTones],
    chromaModifier: 0.15,       // nudge saturation up
    suggestedLRange: (30, 65),  // favour mid-to-dark
    description: "Victorian homes were designed for rich, deep colour. High ceilings, ornate cornicing, and generous proportions carry bold choices beautifully.",
  ),
  PropertyEra.edwardian: EraAffinity(
    affinityFamilies: [PaletteFamily.earthTones, PaletteFamily.warmNeutrals, PaletteFamily.pastels],
    chromaModifier: -0.10,      // nudge saturation down
    suggestedLRange: (50, 85),  // favour lighter
    description: "Edwardian homes suit warm, natural palettes inspired by the Arts & Crafts movement.",
  ),
  PropertyEra.thirties_fifties: EraAffinity(
    affinityFamilies: [PaletteFamily.pastels, PaletteFamily.coolNeutrals],
    chromaModifier: 0.0,
    suggestedLRange: (50, 85),
    description: "Mid-century homes shine with softer, lighter palettes.",
  ),
  PropertyEra.modern: EraAffinity(
    affinityFamilies: null,     // no era bias
    chromaModifier: 0.0,
    suggestedLRange: null,
    description: "Modern homes are a blank canvas.",
  ),
  // ... postwar, newBuild
};
```

#### F3: Apply Era Bias in Palette Generation (Soft)

- If user's primary family aligns with era affinity families: no change.
- If it conflicts (e.g., pastels in a Victorian house): proceed with user preference but:
  - Adjust the L\* spread to be more sympathetic (slightly deeper pastels for Victorian)
  - Apply the `chromaModifier` to nudge saturation
  - Surface an educational note on the DNA reveal: "Your pastel palette in a Victorian home works beautifully when you lean into slightly deeper tones that complement the period features."

#### F4: Orientation-Aware Undertone Bias

When orientation is known, adjust undertone filtering in palette generation:

```
North-facing: increase warm undertone preference by +0.2 weight
  (warm undertones combat the cool, blue-toned north light)
South-facing: permit cooler undertones, increase cool weight by +0.1
  (cool tones balance strong warm daylight)
East/West: no adjustment
Not sure: no adjustment
```

#### F5: Renter Mode Integration

If tenure == renter AND landlord wall presets exist:

- After generating the system palette, compute delta-E between each DNA colour and the landlord wall colour
- If delta-E > 40 for most palette colours, suggest 1-2 "bridge" colours that sit between the DNA palette and the landlord wall
- Label them distinctly: "Bridge colours to work with your existing walls"

#### F6: Contextual Insight on DNA Reveal

Combine era + family + undertone + orientation into a personalised paragraph on the result screen:

_"Your Warm Neutrals palette is a natural fit for your Edwardian semi. With your warm undertone preference and north-facing living room, look for paints with golden or pink bases rather than grey. This will keep your rooms feeling inviting even on overcast days."_

### Acceptance Criteria

- Victorian users see subtly deeper palettes than new-build users with the same quiz answers
- North-facing users get warmer undertone bias (measurable via average `b*` of palette)
- Era bias is soft: user preference always wins, era adjusts depth/saturation at the margins
- Renters with landlord wall presets get bridge colour suggestions
- DNA reveal shows a contextual insight paragraph when property context is available
- All 7 era options produce distinct, accurate affinity data

---

## Epic G: DNA to 70/20/10 Planner Integration

**Priority:** P1 (closes the biggest feature gap)
**Dependencies:** Epic D (role-based palette)
**Estimated scope:** Medium

### Problem

The 70/20/10 planner is the app's core room-level planning feature, but it operates independently of DNA. The user must manually choose a hero colour from the entire paint database with no guidance from their personalised palette. This disconnect means the onboarding work leads nowhere.

### What to Build

#### G1: Pre-populate Hero Picker with DNA Suggestions

When the user opens the 70/20/10 planner:

- Default the hero picker to a "From Your DNA" tab showing:
  - `systemPalette.dominantWalls` as primary hero candidates
  - `systemPalette.supportingWalls` as secondary hero candidates
  - Each labelled with role context: "Main wall colour from your [Archetype Name] palette"
- Second tab: "Explore All" (current full database behaviour)

#### G2: Constrain Beta/Surprise Generation with DNA Axes

When generating the 20% (beta) and 10% (surprise) colours:

- Beta colour must share the user's undertone temperature (from Epic B)
- Surprise colour can contrast on hue but must respect saturation preference (muted users get muted surprises, bold users get saturated ones)
- Both should have low delta-E to at least one DNA palette member (< 20)

#### G3: Room-Type Colour Psychology Tips

When the user selects a room type in the planner, show a contextual tip drawing from colour psychology research and their DNA:

```dart
const roomColourGuidance = {
  RoomType.bedroom: RoomGuidance(
    insight: "Blues and greens support better sleep quality.",
    avoid: "Bright reds and purples can stimulate brain activity and disrupt rest.",
  ),
  RoomType.kitchen: RoomGuidance(
    insight: "Warm tones stimulate appetite and energy.",
    avoid: "Full blue or green walls can suppress appetite.",
  ),
  RoomType.livingRoom: RoomGuidance(
    insight: "Warm neutrals and greens balance sociability with relaxation.",
    avoid: "Highly saturated single-colour schemes can feel overwhelming over time.",
  ),
  RoomType.homeOffice: RoomGuidance(
    insight: "Blues and greens enhance focus and productivity.",
    avoid: "Full red can increase stress over extended periods.",
  ),
  RoomType.diningRoom: RoomGuidance(
    insight: "Reds and oranges encourage appetite and social engagement.",
    avoid: "Cool blues can suppress appetite.",
  ),
  RoomType.bathroom: RoomGuidance(
    insight: "Whites, blues, and greens create spa-like tranquility.",
    avoid: "Very dark colours in small windowless bathrooms can feel oppressive.",
  ),
  RoomType.hallway: RoomGuidance(
    insight: "Light neutrals and bridging tones expand perceived space.",
    avoid: "Bold colours that clash with adjacent rooms.",
  ),
};
```

Dynamically fill in the specific DNA colour that best matches the guidance: "Your palette includes [Sage Green], which would be a great bedroom choice."

#### G4: Default Trim White

Pre-populate the ceiling/trim colour with `systemPalette.trimWhite` as the default. This saves the user a decision and ensures trim consistency (a common expensive mistake for novice decorators).

### Acceptance Criteria

- User who completed DNA sees their palette colours as the default hero options in the planner
- Beta/surprise colours respect DNA undertone and saturation preferences
- Room-type tips reference specific DNA colours by name
- Trim white pre-populates from DNA
- User can override everything (DNA is suggestion, not constraint)
- Planner output is visually coherent with DNA palette when DNA colours are used

---

## Epic H: DNA to Red Thread Integration

**Priority:** P2
**Dependencies:** Epic D (role-based palette)
**Estimated scope:** Small-Medium

### Problem

The Red Thread feature requires manual colour selection with no DNA input. The DNA should pre-suggest the ideal thread colour, eliminating the cold-start problem.

### What to Build

#### H1: Pre-suggest Thread Candidates

When the user first opens Red Thread, show 2-3 suggestions:

1. **Spine suggestion:** `systemPalette.spineColour` -- "This colour connects naturally to your whole palette. Great for hallways and landings."
2. **Deep anchor suggestion:** `systemPalette.deepAnchor` -- "A bolder thread colour that adds depth. Works as an accent across rooms."
3. **Archetype suggestion:** The colour named in `archetype.suggestedRedThread`

#### H2: Coherence Check Against DNA Undertone

When the user manually selects a thread colour, check it against the DNA undertone:

- If the thread's undertone clashes with the DNA temperature, surface a gentle note: "This thread has cool undertones, but your palette leans warm. They might feel disconnected. Consider [alternative with matching undertone]."

#### H3: One-Tap Thread Setting from DNA Screen

On the DNA reveal/palette screen, add a CTA: "Set your thread colour" with the spine colour pre-selected. One tap writes `redThreadColourId = spineColour.id`.

### Acceptance Criteria

- User who completed DNA sees thread suggestions immediately (no cold start)
- Thread suggestions visually relate to the DNA palette
- Coherence warnings appear when undertone clashes
- One-tap thread setting works from DNA screen
- User can still pick any colour as their thread

---

## Epic I: DNA to Explore Tools Integration

**Priority:** P3
**Dependencies:** Epic D (role-based palette), Epic B (undertone)
**Estimated scope:** Medium

### What to Build

#### I1: White Finder Integration

- Pre-filter by DNA undertone temperature: warm DNA -> show warm-undertone whites first
- Label: "Whites matched to your Colour DNA"
- Still allow browsing all whites

#### I2: Colour Wheel Integration

- Highlight user's DNA colours as pins/markers on the wheel
- Add a "Your palette" overlay toggle showing where DNA colours sit

#### I3: Colour Relationships Integration

- Default starting colours to DNA palette members (instead of "pick any colour")
- "See what is complementary to [your dominant wall colour]"

### Acceptance Criteria

- White Finder defaults to DNA-temperature-matched whites
- Colour Wheel shows DNA colour positions
- Colour Relationships uses DNA colours as default starting points
- All integrations are additive; users can browse freely

---

## Epic J: Quiz UX and Content Improvements

**Priority:** P0 for photography, P3 for rebalancing
**Dependencies:** None
**Estimated scope:** Medium (photography sourcing is the bottleneck)

### What to Build

#### J1: Replace Placeholder Images (P0)

Source 8+ high-quality room photographs matching the existing room card descriptions. Requirements:

- Clearly show the described colour palette
- UK-appropriate homes (not American McMansions)
- Consistent photographic style (aspect ratio, lighting quality)
- Optimised for mobile (max 200KB each, progressive JPEG or WebP)
- Aspirational but achievable

#### J2: Expand Room Cards from 8 to 12 (P3)

Add 4 new room cards to improve coverage:

| Room                                               | Weights                                    |
| -------------------------------------------------- | ------------------------------------------ |
| Modern white kitchen with sage green accents       | coolNeutrals: 2, earthTones: 1, pastels: 1 |
| Moody dark hallway with gallery wall               | darks: 3, coolNeutrals: 1                  |
| Spa-like bathroom with blue-green tiles            | coolNeutrals: 2, pastels: 1, jewelTones: 1 |
| Warm home office with wooden desk and green plants | earthTones: 2, warmNeutrals: 1, brights: 1 |

#### J3: Audit and Rebalance Family Weight Distribution (P3)

Current issue: `warmNeutrals` appears in 16+ cards (over-represented). `coolNeutrals` appears in ~8 (could be stronger).

Actions:

- Add 1 card to Q1 and Q2 with stronger `coolNeutrals` signal (e.g., "Coastal mist", "Morning fog")
- Adjust over-weighted cards: e.g., "Candlelit warm glow" from `warmNeutrals: 2, earthTones: 1` to `warmNeutrals: 1, earthTones: 2`
- Verify every family has a viable path to being primary with a pure-path test

#### J4: Stage 1 Card Visual Enhancement (P3)

Replace flat colour swatches with:

- Full-bleed colour background with subtle texture overlay
- Evocative micro-illustration (sun for "Sun-warmed yellow", blanket for "Creamy blanket")

### Acceptance Criteria

- All room cards display real photography
- New room cards cover kitchen, bathroom, hallway, home office
- Every family can be selected as primary through a plausible quiz path
- `warmNeutrals` and `earthTones` over-representation is reduced

---

## Epic K: DNA Reveal Experience

**Priority:** P2
**Dependencies:** Epic E (archetypes)
**Estimated scope:** Medium

### What to Build

#### K1: Progress Indicator

Show a step counter throughout the quiz: "Step 2 of 4" (or 5 if Q5 is added).

#### K2: Reveal Sequence

1. Brief "analysing your choices" animation (1-2 seconds, builds anticipation)
2. Archetype name reveals with prominent typography
3. Palette colours cascade in with a stagger animation
4. Description fades in below
5. Three-section result screen:

**Section 1: Your Archetype**

- Name, description, palette swatches

**Section 2: Why These Colours Work Together (educational)**

- 2-sentence explanation of undertone harmony
- Visual showing palette grouped by undertone with connecting lines

**Section 3: Your Next Steps (actionable)**

- "Start with one room" -> link to 70/20/10 planner
- "Set your thread colour" -> link to Red Thread with pre-suggested thread
- "Find your white" -> link to White Finder pre-filtered by temperature

#### K3: Share Card

Generate a shareable image card: archetype name + palette swatches + Palette watermark. Serves viral growth and the "partner dragged into decisions" use case.

### Acceptance Criteria

- Reveal feels like a "moment" (users want to screenshot/share)
- Full sequence takes 3-5 seconds
- Quick-win suggestion uses real paint names from the palette
- Share card renders correctly on common social platforms

---

## Epic L: DNA Evolution -- Learn from User Behaviour

**Priority:** P3 (long-term retention)
**Dependencies:** All previous Epics
**Estimated scope:** Large

### What to Build

#### L1: Track Preference Signals

Log every meaningful colour interaction:

- Colours selected as hero/beta/surprise in the planner
- Colours swapped out (what was replaced, what replaced it)
- Colours saved to favourites
- Time spent viewing specific colours
- Colours removed from DNA palette (premium)

#### L2: Compute Drift Score

Compare actual selections against DNA profile across three dimensions:

- **Family drift:** are they gravitating toward a different family?
- **Chroma drift:** consistently choosing higher/lower saturation?
- **Undertone drift:** preferring warmer/cooler than quiz indicated?

#### L3: Prompt Palette Refresh

When drift exceeds threshold (>60% of recent selections diverge):

- Prompt: "Your style seems to be evolving! Would you like to refresh your Colour DNA?"
- Option 1: Retake quiz (existing)
- Option 2: Auto-adjust based on observed drift (new)

Auto-adjust modifies weights proportionally to observed drift. Apply exponential decay so onboarding still matters but does not trap users forever.

### Acceptance Criteria

- After 20+ interactions, system detects meaningful drift
- Refresh prompt shown at most once per month
- Auto-adjust preserves family identity but corrects flagged dimension
- Drift tracking does not impact app performance

---

## Implementation Order and Dependencies

```
Phase 0 (Ship First -- No Algorithm Changes)
├── Epic J1: Replace placeholder images
├── Epic E: Archetype narrative system (basic version using family only)
└── Epic A: Quiz weight normalisation + confidence score

Phase 1 (Core Algorithm Upgrade)
├── Pre-req: Paint database enrichment (Section 5)
├── Epic B: Undertone temperature axis
├── Epic D: Role-based system palette
└── Epic G: DNA to 70/20/10 planner integration

Phase 2 (Refinement + Integration)
├── Epic C: Saturation/chroma preference axis
├── Epic E: Enhanced archetypes (family + saturation)
├── Epic F: Property context activation
├── Epic H: DNA to Red Thread integration
└── Epic K: DNA reveal experience

Phase 3 (Polish + Long-term)
├── Epic I: DNA to explore tools integration
├── Epic J2-4: Quiz expansion + rebalancing
└── Epic L: DNA evolution / learning loop
```

**Dependency graph:**

```
Section 5 (DB enrichment) ──> Epic B (undertone)
                          ──> Epic C (saturation)
                          ──> Epic D (system palette)

Epic A (normalisation)   ──> Epic D (system palette)

Epic D (system palette)  ──> Epic G (planner integration)
                         ──> Epic H (red thread integration)
                         ──> Epic I (explore tools)

Epic E (archetypes)      ──> Epic K (reveal experience)

Epic B (undertone)       ──> Epic F (property context)
                         ──> Epic I (white finder)
```

---

## QA Strategy

### Snapshot Testing

For every algorithm change, maintain a set of deterministic test fixtures:

```dart
// Example fixture
final fixture = QuizFixture(
  name: 'pure_warm_neutrals',
  stage1Answers: [
    'sun_warmed_yellow',   // warmNeutrals: 2, earthTones: 1, pastels: 1
    'scandinavian_cabin',  // warmNeutrals: 2, coolNeutrals: 1
    'candlelit_warm_glow', // warmNeutrals: 2, earthTones: 1
    'comforting_warmth',   // warmNeutrals: 3
  ],
  stage2Selections: ['bright_airy_living_room', 'elegant_blush_bedroom'],
  expectedPrimaryFamily: PaletteFamily.warmNeutrals,
  expectedUndertone: UndertoneTemperature.warm,
  expectedConfidence: DnaConfidence.high,
);
```

**Required fixture set (minimum 10):**

| Fixture                      | Tests                                                 |
| ---------------------------- | ----------------------------------------------------- |
| Pure warm neutrals           | All warm cards, clear primary                         |
| Pure cool neutrals           | All cool cards, clear primary                         |
| Pure jewel tones             | All jewel cards, bold saturation                      |
| Mixed warm/cool              | Split answers, expect neutral undertone               |
| Stage 2 domination (pre-fix) | 1 Stage 1 family + 8 Stage 2 cards pointing elsewhere |
| Minimal Stage 2              | 4 Stage 1 answers + 1 Stage 2 selection               |
| Maximal Stage 2              | 4 Stage 1 answers + all 8 Stage 2 selections          |
| Earth tones muted            | Earth family + muted saturation signals               |
| Earth tones bold             | Earth family + bold saturation signals                |
| Low confidence               | Stage 1 answers evenly split across 4 families        |

### Integration Testing

For each downstream integration (planner, Red Thread, White Finder):

- Verify that DNA data flows through correctly
- Verify that suggestions change based on DNA (compare with/without DNA)
- Verify that user overrides work (DNA suggests, user picks something else, system accepts)

### Visual QA

For system palette outputs:

- Generate palettes for all 7 primary families
- Render as a swatch grid and visually verify: do the colours feel harmonious? Is there undertone consistency? Does the trim white "belong"?
- Test under simulated lighting using existing Kelvin infrastructure

### Regression Checklist

After every Epic:

- [ ] Existing onboarding flow completes without errors
- [ ] `colourHexes` backward-compatible field is populated
- [ ] Home screen DNA card renders correctly
- [ ] Picker suggestions still appear (even if anchors changed)
- [ ] Premium gating still works on palette editing
- [ ] Retake quiz produces new results

---

## Success Metrics

Track these to confirm improvements are working:

| Metric                                          | What It Measures                 | Target Direction                          |
| ----------------------------------------------- | -------------------------------- | ----------------------------------------- |
| Onboarding completion -> first saved room plan  | Does DNA lead to action?         | Increase                                  |
| Quiz retake rate                                | Is DNA accurate first time?      | Small decrease (some retakes are healthy) |
| Picker "accept suggestion" rate (Slot 1)        | Are role-based anchors better?   | Increase                                  |
| Palette churn (swaps/removals after DNA reveal) | Does the palette feel right?     | Decrease                                  |
| Time from DNA reveal to first room plan         | Does the flow connect?           | Decrease                                  |
| "Looks wrong in my light" feedback              | Does orientation bias help?      | Decrease                                  |
| Share card generation count                     | Is the reveal moment compelling? | Track (new metric)                        |
| Red Thread adoption rate                        | Does pre-suggestion drive usage? | Increase                                  |
