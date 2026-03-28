# Palette Brand Identity Document

> **App name:** Palette (internal codename: "Diva Boots")
> **Last updated:** 2026-03-26
> **Source of truth:** Extracted from codebase (`lib/core/theme/`) and SPEC.md

---

## 1. Brand Overview

### Purpose

Palette is an interior design companion app for homeowners and renters in the UK (ages 25-40). It helps users discover their colour personality, plan room palettes using professional design rules (70/20/10), find real UK paint matches, and build whole-home coherence through the "Red Thread" concept. The app bridges the gap between "I don't know where to start" and "I'm confident enough to buy" -- without hiring an interior designer.

### Core Repositioning

The app is positioned as a **"room decision engine powered by colour intelligence."** Colour science is the algorithmic backbone, but the user-facing product is organised around room outcomes and actionable recommendations.

### Design Philosophy (Five Principles)

1. **Emotion first, colour second.** The app never starts with a colour chart. It starts with who you are, what you love, and why. Palettes emerge from memories, wardrobe, and personality.
2. **Teach the why, not just the what.** Every recommendation comes with an explanation. Education embedded in the tool builds confidence and trust.
3. **The whole house, not just one room.** Every feature considers how choices flow from space to space through the "Red Thread."
4. **Rooms are the product, colour is the engine.** Users think "help me decorate my living room." The algorithm thinks colour compatibility, undertone harmony, light direction, texture balance, and budget fit.
5. **Discover free, decide premium.** Free users explore their taste; the tools that move them from "I have ideas" to "I'm confident enough to spend money" sit behind the paywall. The upgrade moment is buying certainty, not buying features.

### Brand Personality

The app should feel like **"a calm, literate interior designer who knows your room and explains herself"** (SPEC, Phase 2 principle). It should never feel like a pastel affiliate storefront. The product diagnoses first, recommends second, and monetises third.

---

## 2. Colour System

All values extracted from `lib/core/theme/palette_colours.dart` (`PaletteColours` class). These are the **app UI colours**, not the paint colours in the database.

### Backgrounds

| Token             | Hex         | Usage                                |
| ----------------- | ----------- | ------------------------------------ |
| `warmWhite`       | `#FAF8F5`   | Scaffold background, main surface    |
| `softCream`       | `#F5F0E8`   | Chip backgrounds, secondary surface  |
| `warmGrey`        | `#E8E4DE`   | Divider, outline, inactive progress  |

### Primary Accent: Sage Green

| Token             | Hex         | Usage                                                    |
| ----------------- | ----------- | -------------------------------------------------------- |
| `sageGreen`       | `#8FAE8B`   | Primary CTA, nav selection, focused input border, FAB    |
| `sageGreenLight`  | `#B5CDB2`   | Primary container, selected chip, nav indicator          |
| `sageGreenDark`   | `#6B8A67`   | Not explicitly defined in theme; available for emphasis   |

### Secondary Accent: Soft Gold

| Token             | Hex         | Usage                                        |
| ----------------- | ----------- | -------------------------------------------- |
| `softGold`        | `#C9A96E`   | Secondary colour, status warning, premium gradient start |
| `softGoldLight`   | `#DCC799`   | Secondary container                          |
| `softGoldDark`    | `#A88B4A`   | Not explicitly defined in theme; available    |

### Colour Blind Mode Accent: Accessible Blue

| Token                  | Hex         | Usage                                            |
| ---------------------- | ----------- | ------------------------------------------------ |
| `accessibleBlue`       | `#5B8DB8`   | Replaces sage green as primary in CB mode        |
| `accessibleBlueLight`  | `#89B4D4`   | Replaces sage green light as primaryContainer    |
| `accessibleBlueDark`   | `#3A6E96`   | Available for emphasis in CB mode                |

### Text

| Token             | Hex         | Usage                                            |
| ----------------- | ----------- | ------------------------------------------------ |
| `textPrimary`     | `#2C2C2C`   | Primary body and heading text                    |
| `textSecondary`   | `#6B6B6B`   | Secondary descriptions, bodySmall default, unselected nav |
| `textTertiary`    | `#9B9B9B`   | Disclaimer text, fine print                      |
| `textOnAccent`    | `#FFFFFF`   | Text on primary/secondary accent backgrounds     |

### Status

| Token             | Hex         | Usage                                            |
| ----------------- | ----------- | ------------------------------------------------ |
| `statusPositive`  | `#5B8DB8`   | Positive/success states (blue, not green -- accessible) |
| `statusWarning`   | `#C9A96E`   | Warning states (gold)                            |
| `statusInfo`      | `#8FAE8B`   | Informational states (sage green)                |
| `statusNeutral`   | `#E8E4DE`   | Neutral/inactive states                          |

**Note:** The status palette deliberately avoids red/green pairings for accessibility.

### Surfaces

| Token             | Hex                 | Usage                                |
| ----------------- | ------------------- | ------------------------------------ |
| `cardBackground`  | `#FFFFFF`           | Card fills, input fills, nav bar bg  |
| `divider`         | `#E8E4DE`           | Card borders, swatch borders, divider lines |
| `overlay`         | `#000000` at 50%    | Modal overlay                        |

### Premium

| Token                    | Hex         | Usage                                    |
| ------------------------ | ----------- | ---------------------------------------- |
| `premiumGold`            | `#CBA135`   | Lock icon on premium gates               |
| `premiumGradientStart`   | `#C9A96E`   | Premium gradient start (soft gold)       |
| `premiumGradientEnd`     | `#8FAE8B`   | Premium gradient end (sage green)        |

### Colour Scheme (Material 3)

Defined in `lib/core/theme/palette_theme.dart`. The app uses `ColorScheme.light()`:

| Role                 | Mapped to                     |
| -------------------- | ----------------------------- |
| `primary`            | `sageGreen` (#8FAE8B)         |
| `onPrimary`          | `textOnAccent` (#FFFFFF)      |
| `primaryContainer`   | `sageGreenLight` (#B5CDB2)    |
| `secondary`          | `softGold` (#C9A96E)          |
| `onSecondary`        | `textOnAccent` (#FFFFFF)      |
| `secondaryContainer` | `softGoldLight` (#DCC799)     |
| `surface`            | `warmWhite` (#FAF8F5)         |
| `onSurface`          | `textPrimary` (#2C2C2C)       |
| `onSurfaceVariant`   | `textSecondary` (#6B6B6B)     |
| `outline`            | `warmGrey` (#E8E4DE)          |
| `outlineVariant`     | `divider` (#E8E4DE)           |

---

## 3. Typography

Defined in `lib/core/theme/palette_typography.dart` (`PaletteTypography` class). Uses Google Fonts via the `google_fonts` package.

### Font Families

| Role      | Family      | Character                                      |
| --------- | ----------- | ---------------------------------------------- |
| Headings  | **Lora**    | Editorial serif; warmth, authority, personality |
| Body      | **DM Sans** | Clean geometric sans-serif; readability         |

### Type Scale

#### Display (Lora -- Serif)

| Style           | Size | Weight  | Line Height | Colour        |
| --------------- | ---- | ------- | ----------- | ------------- |
| `displayLarge`  | 32px | w700    | 1.2         | textPrimary   |
| `displayMedium` | 28px | w700    | 1.2         | textPrimary   |
| `displaySmall`  | 24px | w600    | 1.3         | textPrimary   |

#### Headline (Lora -- Serif)

| Style             | Size | Weight  | Line Height | Colour        |
| ----------------- | ---- | ------- | ----------- | ------------- |
| `headlineLarge`   | 22px | w600    | 1.3         | textPrimary   |
| `headlineMedium`  | 20px | w600    | 1.3         | textPrimary   |
| `headlineSmall`   | 18px | w500    | 1.4         | textPrimary   |

#### Title (DM Sans -- Sans-Serif)

| Style          | Size | Weight  | Line Height | Colour        |
| -------------- | ---- | ------- | ----------- | ------------- |
| `titleLarge`   | 18px | w600    | 1.4         | textPrimary   |
| `titleMedium`  | 16px | w600    | 1.4         | textPrimary   |
| `titleSmall`   | 14px | w600    | 1.4         | textPrimary   |

#### Body (DM Sans -- Sans-Serif)

| Style         | Size | Weight  | Line Height | Colour          |
| ------------- | ---- | ------- | ----------- | --------------- |
| `bodyLarge`   | 16px | w400    | 1.5         | textPrimary     |
| `bodyMedium`  | 14px | w400    | 1.5         | textPrimary     |
| `bodySmall`   | 12px | w400    | 1.5         | textSecondary   |

#### Label (DM Sans -- Sans-Serif)

| Style          | Size | Weight  | Line Height | Colour          |
| -------------- | ---- | ------- | ----------- | --------------- |
| `labelLarge`   | 14px | w500    | 1.4         | textPrimary     |
| `labelMedium`  | 12px | w500    | 1.4         | textPrimary     |
| `labelSmall`   | 11px | w500    | 1.4         | textSecondary   |

### Weight Scale (Used)

| Weight | Name        | Where Used                    |
| ------ | ----------- | ----------------------------- |
| w400   | Regular     | Body text                     |
| w500   | Medium      | Labels, headlineSmall         |
| w600   | SemiBold    | Titles, headlines, displaySmall |
| w700   | Bold        | Display large/medium          |

### Typography Hierarchy (from SPEC 1E.5)

The SPEC prescribes this intent (partially implemented):

- **Display weight:** Screen titles (e.g., "Your Design Plan")
- **Section headings:** Card group labels (e.g., "Light & Direction")
- **Card titles:** Individual card headers
- **Body text:** Descriptions, explanations
- **Caption:** Metadata, badges, timestamps

---

## 4. Spacing & Layout

Spacing is not defined as a standalone token system. Values are embedded directly in theme and widget code. The following are the recurring values extracted from `lib/core/theme/palette_theme.dart` and `lib/core/widgets/`.

### Common Spacing Values

| Value  | Usage                                                        |
| ------ | ------------------------------------------------------------ |
| 4px    | Progress bar segment gap, swatch-to-label gap                |
| 6px    | Inline icon-to-text gap (disclaimers, badges)                |
| 8px    | Section header vertical padding, chip vertical padding, vertical gaps between small elements |
| 12px   | Card title-to-content gap, premium gate internal spacing, chip horizontal padding |
| 14px   | Button vertical padding, input vertical padding              |
| 16px   | Card default internal padding (all sides), screen horizontal padding, input horizontal padding, bottom sheet header padding, vertical gaps between sections |
| 20px   | Larger section separators (between home screen sections)     |
| 24px   | Button horizontal padding, bottom sheet horizontal padding   |
| 28px   | Larger vertical separators (paywall sections)                |
| 32px   | Bottom scroll padding                                        |

### Screen-Level Padding

- Main scrollable screens use `EdgeInsets.fromLTRB(16, 8, 16, 32)` (home screen pattern)
- Full-width screens use `EdgeInsets.all(16)` (paywall, settings)

### Border Radius

| Value  | Usage                                                        |
| ------ | ------------------------------------------------------------ |
| 2px    | Progress bar segments, bottom sheet drag handle              |
| 4px    | Undertone badge corner radius on colour swatches             |
| 8px    | Chips, colour swatch squares                                 |
| 12px   | Cards, buttons (elevated, outlined), input fields, premium gate overlay, InkWell tap areas |
| 16px   | Bottom sheet top corners                                     |

### Elevation

| Level | Value | Usage                                              |
| ----- | ----- | -------------------------------------------------- |
| 0     | 0     | AppBar, cards, elevated buttons (flat design)      |
| 0.5   | 0.5   | AppBar scrolled-under state                        |
| 4     | 4     | Floating action button                             |
| 8     | 8     | Legacy `bottomNavigationBarTheme` (not used; app uses `NavigationBar`) |

### SPEC-Defined Card Depth System (Planned, from 1E.5)

Not yet implemented in code. The SPEC envisions:

- **Level 0 (flush):** Backgrounds
- **Level 1 (subtle shadow):** Content cards, informational panels
- **Level 2 (elevated shadow):** Interactive cards, CTAs, "Next Action" card

---

## 5. Component Patterns

### Cards (`PaletteCard`)

- **Background:** White (`#FFFFFF`)
- **Border:** 1px solid `divider` (`#E8E4DE`)
- **Border radius:** 12px
- **Elevation:** 0 (flat)
- **Padding:** 16px all sides (default, configurable)
- **Title style:** `headlineSmall` (Lora 18px w500)
- **Title-to-content gap:** 12px

### Buttons

**Elevated (Primary CTA):**
- Background: `sageGreen` (#8FAE8B)
- Text: white (#FFFFFF)
- Elevation: 0
- Padding: 24px horizontal, 14px vertical
- Border radius: 12px

**Outlined (Secondary):**
- Border: 1px solid `sageGreen`
- Text: `sageGreen`
- Padding: 24px horizontal, 14px vertical
- Border radius: 12px

**Text:**
- Text: `sageGreen`
- No border or background

### Input Fields

- Fill: white (`#FFFFFF`)
- Border: 1px solid `warmGrey` (#E8E4DE)
- Focused border: 2px solid `sageGreen` (#8FAE8B)
- Border radius: 12px
- Content padding: 16px horizontal, 14px vertical

### Chips

- Background: `softCream` (#F5F0E8)
- Selected: `sageGreenLight` (#B5CDB2)
- Border radius: 8px
- Border: none
- Padding: 12px horizontal, 8px vertical

### Bottom Sheets

- Background: `warmWhite` (#FAF8F5)
- Top border radius: 16px
- Drag handle: shown (`showDragHandle: true`)
- Custom drag handle: 40px wide, 4px tall, `divider` colour, 2px radius

### Navigation Bar (Material 3 `NavigationBar`)

The app uses a Material 3 `NavigationBar` widget (not the legacy `BottomNavigationBar`). The widget is configured directly in `app_shell.dart`, overriding the `bottomNavigationBarTheme` in `palette_theme.dart`.

- Background: `cardBackground` (#FFFFFF) -- set inline in `app_shell.dart`
- Indicator: `sageGreenLight` (#B5CDB2) at 40% opacity
- Selected item colour: inherited from `colorScheme.primary` (`sageGreen`)
- Unselected item colour: inherited from `colorScheme.onSurfaceVariant` (`textSecondary`)

**Note:** The `bottomNavigationBarTheme` in `palette_theme.dart` configures the legacy `BottomNavigationBar` (background: `warmWhite`, elevation: 8), but this theme data does not apply to the `NavigationBar` widget actually used.

### Navigation Destinations (5 tabs)

| Tab     | Icon (outlined)          | Icon (selected)      |
| ------- | ------------------------ | -------------------- |
| Home    | `home_outlined`          | `home`               |
| Rooms   | `meeting_room_outlined`  | `meeting_room`       |
| Capture | `camera_alt_outlined`    | `camera_alt`         |
| Explore | `explore_outlined`       | `explore`            |
| Profile | `person_outlined`        | `person`             |

### Progress Bar (`SteppedProgressBar`)

- Height: 5px per segment
- Border radius: 2px
- Active colour: `sageGreen` (configurable per context)
- Inactive colour: `warmGrey` (#E8E4DE)
- Gap between segments: 4px
- Animation: 300ms ease-in-out

### Colour Swatches (`ColourSwatchWidget`)

- Default size: 48x48px
- Border radius: 8px
- Border (default): 1px solid `divider`
- Border (selected): 3px solid `sageGreen`
- Label: `labelSmall` (DM Sans 11px w500), centered, max 2 lines
- Undertone badge: 9px bold text, 2px padding, white bg at 90% opacity, 4px radius
- Swatch-to-label gap: 4px

### Section Headers (`SectionHeader`)

- Title: `headlineSmall` (Lora 18px w500)
- Action link: `labelMedium` (DM Sans 12px w500) in `sageGreen`
- Vertical padding: 8px

### Colour Disclaimer (`ColourDisclaimer`)

- Icon: `info_outline`, 14px, `textTertiary` colour
- Text: 11px, `textTertiary` colour
- Vertical padding: 8px
- Icon-to-text gap: 6px
- Default text: "Colours on screens are approximations. Always test physical samples before committing."

### Premium Gate (`PremiumGate`)

- Blur: sigma 8x8
- Minimum height: 160px
- Overlay: `cardBackground` at 70% opacity, 12px radius
- Lock icon: `lock_outline`, 32px, `premiumGold` (#CBA135)
- CTA: `FilledButton` navigating to `/paywall`

### Divider

- Colour: `warmGrey` (#E8E4DE)
- Thickness: 1px
- Space: 1px

### Floating Action Button

- Background: `sageGreen` (#8FAE8B)
- Icon: white (#FFFFFF)
- Elevation: 4

---

## 6. Iconography

### Icon Library

The app uses **Material Icons** (Flutter's built-in `Icons` class). No custom icon set or third-party icon library is used.

### Icon Style

- **Outlined** variants for unselected/default states
- **Filled** variants for selected/active states
- Default colour: `textPrimary` (#2C2C2C) in app bar
- Active nav colour: `sageGreen` (#8FAE8B)
- Inactive nav colour: `textSecondary` (#6B6B6B)

### Key Icons Used

| Context              | Icon                     |
| -------------------- | ------------------------ |
| Palette access       | `palette_outlined`       |
| Premium lock         | `lock_outline`           |
| Sparkle / Premium    | `auto_awesome`           |
| Info / Disclaimer    | `info_outline`           |
| Navigation close     | `close`                  |
| Colour wheel (learn) | `palette_outlined`       |
| Light (learn)        | `wb_sunny_outlined`      |
| 70/20/10 (learn)     | `pie_chart_outline`      |

### Image Assets

- `assets/images/` exists but is currently empty (`.gitkeep` only)
- `assets/data/` contains JSON data files: paint colours, palette families, quiz content, floor plan templates, retailer configs

---

## 7. Tone of Voice

Derived from SPEC.md and in-app copy patterns.

### Core Voice Attributes

- **Warm and reassuring**, not clinical or cold
- **Educational but never condescending** -- the user is smart but lacks specialist knowledge
- **Outcome-led, not feature-led** -- language focuses on what the user achieves, not what the tool does
- **Conversational British English** -- UK spelling ("colour" not "color"), natural phrasing
- **Confident without being prescriptive** -- recommendations explain "why", not just "what"

### Copy Principles

1. **Use outcome language on all surfaces.** "Connect your 3 rooms so the house feels cohesive" not "Define your Red Thread." "Choose the right white for the kitchen before buying samples" not "White selection missing."
2. **Every branded term gets a plain-English subtitle.** Always. Not just on first encounter.

   | Branded Term      | Plain-English Subtitle                 |
   | ----------------- | -------------------------------------- |
   | Colour DNA        | Your personal design identity          |
   | Red Thread        | Keep your whole home feeling connected |
   | Hero colour       | The main colour for this room          |
   | 70/20/10          | Your room's colour balance             |
   | Palette Story     | How your colours work together         |
   | Colour Archetypes | Your design personality                |
   | DNA Match         | Suits your personal palette            |

3. **Explain the "why" in every recommendation.** Structure: [Rule reference] + [Specific room context]. Example: "This rug grounds your seating area (Scale Rule) and its warm gold undertone harmonises with your south-facing evening light."
4. **Renter Mode feels additive, not restrictive.** "Make this place feel like yours without risking your deposit." Not "Limited Mode."
5. **Paywall copy sells certainty, not features.** "Avoid expensive colour mistakes" not "Access premium features." Price anchored to real-world reference: "Less than a Farrow & Ball sample pot per month."
6. **Disclaimers are honest and brief.** "Colours on screens are approximations. Always test physical samples before committing."

### Examples from Codebase

- Quiz prompt: "Think of a place where you felt completely at peace. What colours do you remember?"
- Home screen CTA (no DNA): "Discover Your Colour DNA -- Take a quick quiz to unlock your personal palette"
- Home screen title: "Your Design Plan"
- Paywall headline: "Avoid expensive colour mistakes"
- Paywall subtitle: "Get personalised recommendations for every room in your home"
- Learn article voice: "Every paint colour has an undertone -- a subtle base of warm, cool, or neutral that you might not notice on a swatch card but becomes obvious on a full wall."

---

## 8. Dark / Light Mode

### Current State

The app is **light mode only**. There is no dark theme defined in the codebase.

- `PaletteTheme.light` is the sole theme (set in `app.dart`)
- `brightness: Brightness.light` is explicitly set
- No `PaletteTheme.dark` exists

### Colour Blind Mode

A **Colour Blind Mode** variant exists (`PaletteTheme.colourBlindLight`). It swaps the sage green primary accent for accessible blue (`#5B8DB8`) across:

- `primary` colour scheme role
- `primaryContainer` colour scheme role
- Bottom navigation selected item
- Floating action button background

The toggle is managed via `colourBlindModeProvider` (Riverpod) and applied in `app.dart`.

---

## 9. Design Tokens Summary (Quick Reference)

### Colour Palette at a Glance

```
Primary:     #8FAE8B  (Sage Green)
Secondary:   #C9A96E  (Soft Gold)
Background:  #FAF8F5  (Warm White)
Surface:     #FFFFFF  (Card White)
Text:        #2C2C2C  (Near Black)
Accent CB:   #5B8DB8  (Accessible Blue)
Premium:     #CBA135  (Premium Gold)
```

### Typography at a Glance

```
Headings:  Lora (serif)     -- 18-32px, w500-w700
Body:      DM Sans (sans)   -- 12-16px, w400
Labels:    DM Sans (sans)   -- 11-14px, w500
Titles:    DM Sans (sans)   -- 14-18px, w600
```

### Radius at a Glance

```
Small:   4-8px   (badges, chips, swatches)
Medium:  12px    (cards, buttons, inputs)
Large:   16px    (bottom sheets)
```

### Key Spacers

```
Tight:   4px
Small:   8px
Medium:  12-16px
Large:   24px
XLarge:  32px
```

---

## 10. App Identity

| Attribute             | Value                                              |
| --------------------- | -------------------------------------------------- |
| App name              | Palette                                            |
| Internal codename     | Diva Boots                                         |
| Tagline (from pubspec)| "A colour-first interior design companion"         |
| Version               | 0.1.0+1                                            |
| Platform              | Android (Flutter)                                  |
| Target market          | UK, ages 25-40                                     |
| Framework             | Flutter + Dart                                     |
| State management      | Riverpod                                           |
| Design system         | Material 3 (`useMaterial3: true`)                  |
| Icon library          | Material Icons (built-in)                          |
| Font delivery         | Google Fonts (runtime)                             |

---

*This document was generated by extracting actual values from the Palette codebase and SPEC. Values marked "not explicitly defined" or "planned" reflect the current state of implementation. All hex values, font sizes, weights, and spacing values are taken directly from source code.*
