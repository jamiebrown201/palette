# Project Spec: Palette v2

## Objective

Palette is an interior design companion that helps homeowners and renters decorate their homes with confidence. It uses colour science, design rules, and personalised recommendations to bridge the gap between "I don't know where to start" and "I'm confident enough to buy." It solves the visualisation gap, decision paralysis, knowledge deficit, and action gap that cause people to default to safe, soulless choices they later regret, or make expensive mistakes because they lack the structured knowledge that professional designers take for granted.

**Target users:** People in the UK (25-40) who care about making their home feel personal but lack the confidence, knowledge, or tools to translate taste into decisions. Primary: first-time homeowners. Secondary: long-term renters who want a personal space. Tertiary: partners dragged into decorating decisions.

**What success looks like:** A user goes from "I don't know where to start" to confidently choosing colours, furniture, lighting, and accessories for their whole home, purchasing products through the app, and feeling genuinely proud of how their home looks, without hiring an interior designer.

**Core repositioning (v2):** The app has shifted from "colour-first interior design companion" to "room decision engine powered by colour intelligence." Colour science remains the algorithmic foundation, but the user-facing product is organised around room outcomes and actionable recommendations, not colour tools. The question the app answers is not "what colours suit me?" but "what should I buy for this room, and why does it work?"

---

## The Problem (Validated by Research)

Seven interlocking problems consistently emerged across book research (Sowerby, Watson-Smyth), multi-model analysis, competitive review, and strategic feedback:

**1. The Visualisation Gap.** Most people cannot imagine a finished room from a paint chip. They need to see it. This is the single biggest source of renovation anxiety, partner conflict, and costly mistakes. (Sowerby, Watson-Smyth, Houzz UK data: 20% of homeowners cite this as a top challenge.)

**2. Decision Paralysis.** After 647 Pinterest pins, most people are more confused than when they started. They cannot separate what they genuinely like from what has been beautifully styled for a photograph. There is a massive gap between "inspiration" (infinite, free) and "decision" (what people desperately need and will pay for). (Watson-Smyth)

**3. Light Direction Ignorance.** People do not understand that the direction a room faces fundamentally changes how every colour appears. A beautiful green in a south-facing showroom can look cold and dingy in a north-facing living room. This is expert knowledge that consumers simply do not have access to in a structured form. (Sowerby's single most practical insight)

**4. Undertone Blindness.** Every colour, including whites, has an undertone (blue, red, yellow, grey) that determines how it behaves in a space. Choosing the wrong white can undermine an entire colour scheme. People do not know this, and no consumer tool teaches it. (Sowerby dedicates an entire chapter to whites alone)

**5. The Trend Trap.** People default to fashionable colours (grey, white, whatever Instagram is pushing) out of anxiety about getting it wrong, rather than choosing colours they actually love. This leads to soulless homes and eventual dissatisfaction. (Both books identify this as the root cause of bad interiors)

**6. Room-by-Room Thinking.** People decorate one room at a time with no unifying thread. The result is a house that feels disjointed rather than cohesive. The "red thread" principle (a limited palette that creates subconscious harmony room-to-room) is professional knowledge that consumers never encounter. (Sowerby)

**7. The Action Gap (new in v2).** Even users who have good taste and a colour plan still do not know what to buy next. They browse endlessly, buy things that do not work together, choose rugs that are too small, pick lighting that is wrong for the room, and end up with a collection of individually nice objects that feel incoherent as a room. The gap between "I have a plan" and "I know exactly what to buy" is where most people stall, and where the biggest spending happens. No consumer tool bridges this gap algorithmically.

---

## Core Philosophy

Five principles that guide every feature decision:

**Emotion first, colour second.** The app never starts with a colour chart. It starts with who you are, what you love, and why. Your palette emerges from your memories, your wardrobe, your personality. This is the central thesis of both Sowerby and Watson-Smyth, and it is the primary differentiator from every existing tool.

**Teach the why, not just the what.** Every recommendation comes with an explanation. "This rug works because it grounds your sofa and introduces needed texture without fighting your warm undertones." Education embedded in the tool builds confidence and trust, and confident users buy more, share more, and churn less.

**The whole house, not just one room.** Every feature considers how choices flow from space to space. The "red thread" runs through the entire experience. This is the feature gap no competitor fills.

**Rooms are the product, colour is the engine.** Colour science, undertone matching, and light direction intelligence power the recommendations, but the user-facing experience is organised around rooms, goals, and actions. The user thinks "help me decorate my living room." The algorithm thinks "colour compatibility + undertone harmony + light direction + texture balance + budget fit."

**Discover free, decide premium.** Free users can explore their taste and fall in love with the app. But the tools that move them from "I have ideas" to "I'm confident enough to spend money" are where the paywall sits. The upgrade moment is buying certainty, not buying features.

---

## Design Rules Engine

The app encodes professional interior design knowledge into algorithmic rules. These rules power recommendations across colour, furniture, textiles, lighting, and accessories. Each rule has a plain-language explanation that surfaces in the UI as "why this works" context.

### Colour Rules (implemented in Phase 1A)

- **70/20/10 Colour Balance:** 70% dominant (walls/large furniture), 20% secondary (upholstery/rugs), 10% accent (cushions/art/plants). Auto-generated from a single hero colour pick.
- **Undertone Harmony:** All recommended items should share compatible undertones (warm with warm, cool with cool) unless deliberate contrast is intended.
- **Light Direction Adaptation:** North-facing rooms get warm undertone recommendations; south-facing rooms can handle cooler tones. Cross-referenced with usage time.
- **The Red Thread:** 2-4 unifying colours that appear in some form in every room, creating subconscious whole-home coherence.
- **White Undertone Matching:** Whites are matched to room light direction and existing palette undertones. Wrong whites undermine the entire scheme.

### Design Rules (to implement in Phase 2)

- **The Rule of Odd Numbers (3-5-7):** Objects grouped in odd numbers are more visually appealing. When recommending accessories (cushions, candles, vases), always suggest 3 or 5, not 2 or 4.
- **Triangle Rule for Accent Placement:** Repeat accent colours in at least 3 places in a room, forming a visual triangle. If someone picks a rust accent, suggest a rust cushion, a rust candle, and rust-toned artwork placed in different parts of the room.
- **Texture Layering:** A room with all smooth surfaces feels flat. Recommendations should span at least 3-4 textures. If the sofa is smooth leather, recommend a chunky knit throw and a woven basket to balance.
- **The Wood Tone Rule:** Never match all wood perfectly. Pick a dominant wood tone and an accent, ensuring their undertones (warm/cool) do not clash.
- **Scale and Proportion:** Do not recommend a tiny rug for a big room. Use room dimensions (if captured) to recommend appropriately sized items. The #1 amateur mistake is buying rugs too small.
- **Layered Lighting (Ambient / Task / Accent):** Every room needs 3 types of light. Recommend specific products for each layer.
- **Visual Weight Distribution:** Balance heavy/dark items with lighter ones across the room. Do not cluster all visual weight on one side.
- **Material Balance:** Mix warm and cool materials. If a room has a lot of wood (warm), introduce some metal or glass (cool) for contrast.
- **Something Old, Something New, Something Black, Something Gold:** Watson-Smyth's checklist for a room that feels layered and intentional. Codified as a gentle nudge, not a hard rule.

### Scoring Dimensions (for the Recommendation Engine, Phase 2)

When recommending any product, score it across these dimensions:

- Colour compatibility (delta-E to palette)
- Undertone compatibility (warm/cool alignment)
- Style fit (matches Colour DNA aesthetic)
- Scale fit (appropriate for room size)
- Material balance (adds missing texture/material)
- Contrast contribution (adds needed visual contrast or calm)
- Warmth/coolness correction (compensates for light direction)
- Budget fit (within room's budget bracket)
- Renter suitability (removable/freestanding if in Renter Mode)
- Whole-home coherence (contains Red Thread colour or compatible material)
- Room function fit (appropriate for room type and usage)

Each recommendation surfaces a plain-language "why this works" explanation referencing the top 2-3 scoring dimensions.

---

## Phased Feature Plan

The app ships in four phases. Each phase is a complete, usable product. The phasing has been restructured from the original spec to reflect the strategic pivot toward room outcomes and product recommendations.

---

### Phase 1A: Colour Confidence (COMPLETE)

**Theme:** Help people discover their personal palette, understand how to use it in their specific home, and reach the point where they are ready to act.

**Status: ~95% complete. All core features shipped and functional.**

#### Feature 1.1: Colour DNA Onboarding [COMPLETE]

The onboarding is the product's signature moment. It replaces the standard "pick a style" quiz with an emotionally-driven discovery process.

**What shipped:**

The onboarding has three stages, completing in under 3 minutes for engaged users or under 90 seconds for quick tappers. A visible progress bar drives momentum throughout.

_Stage 1: Memory Prompts (Emotional Anchoring)_
Three to four prompts that mine the user's happiest colour associations. These are not "pick your favourite colour" questions. They surface genuine emotional connections:

- "Think of a place where you felt completely at peace. What colours do you remember?"
- "What colour is the item of clothing you reach for when you want to feel most like yourself?"
- "Close your eyes and picture your ideal Saturday morning. What colours surround you?"

Each prompt offers 6-8 colour-mood cards (atmospheric images paired with colour families). Users can tap multiple cards per prompt.

_Stage 2: Visual Preference (Style Calibration)_
Six to eight room photographs. Users swipe or tap to indicate which feel right. Images represent Sowerby's seven palette families (pastels, brights, jewel tones, earth tones, darks, warm neutrals, cool neutrals) without labelling them.

_Stage 3: Property Context_
Four quick selections: property type, property era, current stage, and tenure (Owner or Renter, which activates Renter Mode).

**Output:** A "Colour DNA" result screen showing the user's archetype, primary palette family (and secondary leanings), personal palette of 8-12 colours, and a short explanation of why these colours resonate.

**Colour Archetypes (implemented):**
The engine maps quiz responses to one of 14 colour archetypes, each a personality-driven identity with a name, description, and curated colour set:

- The Cocooner, The Earthkeeper, The Golden Hour, The Northern Light, The Curator, The Romantic, The Rewild, The Signal Fire, The Patina, The Mineral, The Bloomsbury, The Archive, The Prism, The Bohemian

Each archetype defines a structured "system palette" with functional roles: trimWhite, dominantWalls, supportingWalls, deepAnchor, accentPops, and spineColour. This role-based structure ensures every generated palette has the right balance for real-room application.

The archetype engine uses weighted scoring across palette family affinity, undertone temperature, and saturation preference, with secondary family blending.

**DNA Drift Detection (implemented):**
The app tracks all colour interactions (additions, removals, swaps, captures) via a `ColourInteractions` table. A drift detection algorithm periodically compares recent interaction patterns against the original Colour DNA result. When the user's behaviour indicates a meaningful shift, the app surfaces a gentle prompt: "Your taste seems to be evolving. Want to retake the quiz?"

**Shareable card:** The result is shareable as a designed card (Instagram Stories and WhatsApp format). Every shared card should link back to the web-based quiz (see Phase 1C: Web Acquisition Funnel). Currently the card shares as a static image; deep-link integration depends on the web quiz shipping.

**Remaining work:**

- Skip option at every stage (verify implemented)
- Colour DNA result generation from partial completion (minimum: one memory prompt answered)
- User can retake quiz from Profile settings (implemented, visible in screenshot)
- No account required for onboarding; account gated behind saving results

---

#### Feature 1.2: My Palette [COMPLETE]

The user's personal colour palette, always accessible. Viewing is free; editing is premium.

**What shipped:**

The palette screen shows 8-12 colours in a visually pleasing layout (see screenshot 02). Each colour is tappable to reveal its palette family, undertone, colour wheel relationships, and matched paint colours from UK brands with names, codes, and approximate prices per litre.

**Palette Feedback Engine (implemented):**
Three interconnected feedback systems:

- _Impact feedback_: When a colour is added or swapped, a snackbar describes how it relates to the existing palette using colour science translated into natural language.
- _Role descriptions_: When removing a colour, the confirmation dialog shows what role that colour plays and what the palette would lose.
- _Palette health analysis_: A summary engine (`analysePaletteHealth`) evaluates the overall palette and produces a verdict, explanation, and structured observations about tonal range, chroma diversity, undertone balance, and colour family coherence.

**Palette Story (implemented):**
A magazine-style review experience. A compact "story card" on the palette screen shows mini swatches, a one-line verdict, and a teaser. Tapping opens a `DraggableScrollableSheet` with staggered reveal animations containing strengths, clashes, insights, suggestion CTAs, and an explore strip of all palette colours.

**Paint name display (implemented):**
Throughout the app, hex codes have been replaced with paint names wherever possible. The `_buildNameMap` helper matches palette hexes to their closest paint match (exact hex match first, then delta-E < 10 fallback).

**"Buy This Paint" deep links:** Every paint colour swatch displays a "Buy This Paint" button with a fallback ladder: exact product SKU link > brand product page with colour code > brand search page > brand homepage with "Copy colour code to clipboard" CTA. Retailer config layer (JSON per brand) specifies which fallback level is currently working. Re-verify quarterly.

**Cross-brand price comparison:** Shown where delta-E match is 92%+ (configurable threshold), with disclaimer: "Paint finishes and pigments vary between brands. A close colour match is not identical. Always compare physical samples side by side."

**Indicative pricing:** All price-per-litre data labelled "Prices approximate, last checked [date]" rather than live pricing. Updated periodically (monthly or quarterly).

---

#### Feature 1.4: Room Profiles [COMPLETE]

The room-by-room planning hub. This is where colour theory meets reality.

**What shipped:**

Users create unlimited rooms (free and premium). For each room (see screenshots 03, 04):

- Room name (preset list or custom)
- Direction the main window faces (N/S/E/W, or compass detection)
- Primary usage time (morning, afternoon, evening, all day)
- Desired mood (calm, energising, cocooning, elegant, fresh, grounded, dramatic, playful)
- Budget bracket per room (affordable / mid-range / investment)

**Light Direction Recommendations (Premium):**
Cross-references room's light direction and usage time against the user's palette to generate tailored colour recommendations. North-facing evening rooms get different suggestions than south-facing morning rooms. This is the primary conversion trigger.

_Free user experience:_ Free users enter compass direction (data stored for upgrade). They see a personalised educational message about their room's light characteristics. **Remaining gap:** The blurred preview of premium recommendations below the educational message is not yet implemented. Currently the light recommendations are fully gated rather than showing a blurred preview with upgrade CTA. This should be implemented to strengthen the conversion trigger.

_Premium user experience:_ Full light-matched recommendations with specific colour suggestions tailored to direction, usage time, and mood.

**70/20/10 Planner (Premium, Progressive Entry):**
The user picks one hero colour. The app auto-generates:

- 70% Hero: walls, curtains, largest furniture
- 20% Beta: one large piece plus 1-2 smaller touches (analogous or complementary, filtered by light direction)
- 10% Surprise: something unexpected (complementary or split-complementary from a different palette family)
- Dash: connecting colours from other rooms (the red thread)

The algorithm is deterministic (rule-based colour theory, not ML).

**Existing Furniture Lock (implemented):**
Users "lock" items they are keeping. The algorithm adjusts remaining tiers to accommodate locked items. Furniture conflict detection warns when multiple locked items have conflicting undertones/saturation.

**Room Colour Psychology (implemented):**
Structured mapping from room moods to colour recommendations based on colour science. Each mood maps to recommended palette families, undertone preferences, and saturation ranges.

**Renter Mode (implemented, basic):**
If "Renter" was selected during onboarding, the 70/20/10 planner shifts focus. Walls locked to landlord's existing colour. Planner concentrates on the 30% the renter controls: furniture (20%) and accessories/textiles/art (10%).

**Light Simulation Preview (implemented):**
Three swatches side by side: morning, midday, evening. Kelvin lookup + RGB blend overlay at 10-20% opacity. LRV data adds brightness indicator. Phrased as "helpful preview" not "photorealistic simulation."

**Compass UX:** "Point your phone toward this room's main window and hold still." Only N/S/E/W classification needed (90-degree buckets).

---

#### Feature 1.5: Interactive Colour Wheel and White Finder [COMPLETE]

**What shipped (see screenshots 06, 07):**

A zoomable, tappable colour wheel. Selecting any colour highlights complementary, analogous, triadic, and split-complementary relationships. Each has a one-sentence explanation. Undertone layer toggleable. DNA overlay shows where the user's palette colours sit on the wheel.

**White Finder:** Spectrum of whites organised by undertone (blue, pink, yellow, grey) with Sowerby's "Paper Test" tutorial. When accessed from a room profile, pre-filters to whites that suit the room's light direction. DNA Match badges indicate which undertone families harmonise with the user's Colour DNA (see screenshot 07).

**Context improvement needed (v2):** When opening the Colour Wheel, pre-select the user's hero colour and show relationships relative to their palette rather than starting from a blank slate. This connects the tool to the user's actual rooms rather than feeling like a standalone utility.

---

#### Feature 1.6: The Red Thread (Whole-House Flow) [COMPLETE]

**What shipped (see screenshot 11):**

Users select a floor plan template based on property type (Victorian Terrace, 1930s Semi-Detached, Post-War Estate, Modern Flat, New Build). Each template has predefined tappable room zones. Users assign rooms to zones.

For property types not covered by templates, users build an adjacency list: add rooms, declare connections.

Red thread defined at the top: 2-4 colours that appear in some form in every room. The app highlights where threads appear and flags rooms with no thread colour present. Coherence check is set intersection.

Thread colours show brand attributions and role descriptions (e.g., "Burlywood, Dulux: Connects naturally to your whole palette"). Room Transitions section allows defining connections between rooms.

**Remaining gaps:**

- Red Thread flow visualisation: Currently thread colours are listed and rooms connected, but there is no visual diagram showing how colour flows through the house (e.g., Living Room [Savage Ground] > Hallway [Burlywood thread] > Bedroom [Dark Buff accent]). This visual would make the concept much more tangible.
- Adjacent room comparison (tapping two rooms to see palettes side by side) needs verification.
- Whole-house view exportable as image and PDF (premium).
- Free users see blurred preview after creating 3+ rooms (verify implementation).

---

### Phase 1B: Connect the Dots (NEW PRIORITY)

**Theme:** Transform the existing colour toolkit into a connected, guided experience. Make the app feel like it knows your home and tells you what to do next, rather than presenting isolated tools.

This phase was restructured based on strategic feedback. The original Phase 1B (Colour Capture, Moodboards, Sample Ordering, Notifications) is deferred to Phase 1D. The new Phase 1B focuses on the connective tissue that makes Phase 1A features feel like one guided system.

---

#### Feature 1B.1: Home Screen Redesign ("Your Design Plan")

The Home screen currently shows Colour DNA and a room list (screenshot 01). It is passive. It should answer three questions immediately when opened.

**User Stories:**

- As a user, I want to see what I should do next when I open the app so that I always have a clear next step.
- As a user, I want to see my progress across all rooms so that I feel motivated to continue.
- As a user, I want to understand whether my home feels cohesive so that I can fix problems before buying.

**How it works:**

The Home screen becomes "Your Design Plan" with three sections:

_1. Next Recommended Action (top, most prominent):_
A single, contextual card recommending the user's most impactful next step. The card changes based on project state:

- "Set up your bedroom" (if rooms are incomplete)
- "Choose a warm white for the kitchen" (if room has hero but no white)
- "Your living room needs a grounding rug to anchor the sofa" (Phase 2, when product recs are live)
- "Test your paint samples this weekend. Morning light is best for your east-facing kitchen" (after sample ordering)
- "Define your Red Thread to connect your 3 rooms" (after 3+ rooms created)

The logic for determining the next action follows a priority hierarchy:

1. Complete room setup (rooms with missing direction, mood, or hero colour)
2. Define Red Thread (after 3+ rooms exist)
3. Resolve coherence issues (rooms flagged by Red Thread)
4. Find the right white (rooms with hero but no white selected)
5. Lock existing furniture (rooms with empty furniture lock)
6. Product recommendations (Phase 2, rooms with no "Shop this room" activity)

_2. Project Progress (middle):_
Room cards with visual progress indicators. Each room shows:

- Hero colour swatch
- Completion score: direction set, mood set, hero colour chosen, 70/20/10 planned, white selected, furniture locked, Red Thread connected
- Status: "3 of 6 steps complete"
- One-line summary: "South-facing, Evening, Cocooning"

Progress tracking is gamified: small animations at milestones ("You've planned 3 of 5 rooms!").

_3. Whole-Home Coherence (bottom):_
A compact Red Thread summary showing:

- Thread colours as small swatches
- One-line coherence verdict: "Your warm neutral scheme flows well across 3 rooms" or "Your kitchen is drifting cooler than the rest of the home"
- Tap to open Red Thread detail

**Explore tools strip:** The current Explore cards (Colour Wheel, White Finder, Paint Library, Red Thread) move to the Explore tab exclusively. They no longer appear on the Home screen. Instead, these tools are surfaced contextually from within room profiles and recommendations (e.g., "Find the right white" button in room detail links directly to the White Finder pre-filtered for that room).

**Acceptance Criteria:**

- Next action card is contextual and changes based on project state
- Room cards show visual completion scores
- Coherence summary updates in real time as rooms are edited
- Home screen loads in under 1 second
- Tapping any room card navigates to room detail
- Tapping the coherence summary navigates to Red Thread

---

#### Feature 1B.2: Room Detail Enhancement ("Room Decision Board")

The Room Detail screen (screenshot 04) is the most promising screen in the app. It already captures light direction, mood, hero colour, furniture lock, and 70/20/10 plan. The next step is to make it feel like a complete decision board rather than a colour configuration page.

**User Stories:**

- As a user, I want to understand why my room's configuration works (or doesn't) so that I feel confident before spending money.
- As a user, I want to see what my room still needs so that I know what to do next.
- As a user, I want contextual guidance tied to my specific room so that I do not need to visit separate tools.

**How it works:**

Add the following modules below the existing 70/20/10 plan:

_"Why This Room Works" card:_
A 2-3 sentence explanation connecting the room's tags to its colour plan. Example: "Because your living room faces south and you prefer evenings, Savage Ground's warm undertone will glow beautifully in golden-hour light. The cool green accent creates contrast without fighting the warmth."

This card updates dynamically when any room setting changes. It uses the room's direction, usage time, mood, hero colour, and locked furniture as inputs.

_"Room Checklist" module:_
Visual checklist showing what is configured and what is missing:

- Direction set (checkmark)
- Mood selected (checkmark)
- Hero colour chosen (checkmark)
- 70/20/10 plan complete (checkmark or "Beta colour needed")
- White selected (empty circle with "Find the right white" link)
- Existing furniture locked (empty circle with "Lock items" link)
- Red Thread connected (checkmark or "Not yet connected")

Each incomplete item is tappable and navigates to the relevant configuration step.

_Contextual tool links:_
Replace standalone tool navigation with in-context links:

- "Find the right white" button (already present in screenshot 04) navigates to White Finder pre-filtered for this room's direction
- "See how colours change through the day" links to light simulation for this room's hero colour
- "Check whole-home coherence" links to Red Thread with this room highlighted

**Acceptance Criteria:**

- "Why This Room Works" card appears for any room with hero colour + direction set
- Room Checklist shows accurate completion state
- All checklist items are tappable and navigate to the correct configuration step
- Contextual links pass room context (direction, palette) to the target tool

---

#### Feature 1B.3: Explore Tab Reorganisation

The Explore tab (screenshot 05) currently lists four tools: Colour Wheel, White Finder, Paint Library, Red Thread. This feels like a disconnected toolbox.

**Restructure into three sections:**

_1. Tools:_

- Colour Wheel (with contextual note: "See where your palette sits")
- White Finder (with contextual note: "Find the right white for your rooms and light")
- Paint Library (with contextual note: "Browse colours from UK paint brands")

_2. Learn:_
Educational content that builds confidence:

- "Why undertones matter" (short article or card-based walkthrough)
- "How light direction changes colour" (with diagrams)
- "The 70/20/10 rule explained"
- "What is a Red Thread?"
- "Choosing the right white" (Sowerby's Paper Test, expanded)

Each educational item is a card that expands into a short, image-rich walkthrough. Content should be written in plain language with real examples. These are evergreen and can be created as static content.

_3. Your Palette:_

- Red Thread (with contextual note: "Plan colour flow across your whole home")
- Colour DNA summary (quick access to archetype and palette)

**Acceptance Criteria:**

- Explore tab has three clearly labelled sections
- Educational content is readable without scrolling excessively
- Tools pass user context where relevant (e.g., Colour Wheel pre-loads palette colours)
- Paint Library adds a "Matches your palette" filter badge on compatible colours

---

#### Feature 1B.4: Paint Library Personalisation

The Paint Library (screenshot 08) is currently a browse-only catalogue. It shows brand, hex, price, and undertone badge, but has no connection to the user's palette or rooms.

**Enhancements:**

_"Works with my palette" filter:_
A toggle filter that shows only paints compatible with the user's Colour DNA (delta-E < 25 from any palette colour, or matching undertone family). When active, each paint shows a small badge explaining the match: "Harmonises with your warm earth tones" or "Complements your Cocooner palette."

_"Recommended for [room name]" badges:_
When browsing, paints that suit a specific room's light direction show a room badge: "Good for your north-facing kitchen."

_Sorting by relevance:_
Default sort should prioritise paints that match the user's palette and room contexts, not alphabetical or brand-first.

**Acceptance Criteria:**

- "Works with my palette" toggle filters the library
- Room-specific badges appear where applicable
- At least one filter combination returns results for any Colour DNA archetype
- Performance: filter applies in under 500ms

---

#### Feature 1B.5: Colour DNA Expansion ("Your Design Identity")

The Colour DNA result (screenshot 02) is memorable and beautiful but currently abstract. "The Cocooner: Warmth without fuss" is a great identity, but users need to know what it means for their actual decisions.

**Enhancements:**

Below the existing palette display and "Why these colours work" section, add a "Your Design Identity" card with practical guidance:

- **Best materials:** "Warm oak, linen, antique brass, textured ceramics"
- **Best moods:** "Cocooning, elegant, grounded"
- **What to avoid:** "Stark cool whites, chrome-heavy finishes, high-gloss surfaces"
- **Best wood tones:** "Honey oak, walnut, weathered pine"
- **Best metal finishes:** "Antique brass, brushed gold, matte black"

This guidance is generated from the archetype definition. Each archetype should have these practical attributes defined in its data model alongside the existing colour roles.

**Data model addition per archetype:**

```
recommendedMaterials: [String]
recommendedMoods: [String]
avoidMaterials: [String]
bestWoodTones: [String]
bestMetalFinishes: [String]
bestFabrics: [String]
contrastLevel: "low" | "medium" | "high"
idealAccentSaturation: "muted" | "moderate" | "bold"
```

**Acceptance Criteria:**

- Every archetype has practical guidance defined
- Guidance appears on the Colour DNA screen below existing content
- Guidance uses plain language with no jargon
- Guidance is consistent with the archetype's colour palette

---

#### Feature 1B.6: Paywall Restructure

The current paywall (screenshot 10) gates features that feel like "more tools." The tier differentiation between Plus and Pro is weak (Pro adds Partner Mode, Priority Support, Early Access).

**Restructured tiers:**

**Free:**

- Colour DNA quiz and shareable result
- Personal palette (view only, no edits)
- Unlimited room creation (invest effort before paywall)
- Basic room setup (direction, mood, hero colour)
- Colour Wheel and White Finder (browse only)
- 1 moodboard (Phase 1D)
- Colour Capture (view results, save to moodboard, not palette) (Phase 1D)
- Educational content
- "Buy This Paint" affiliate links on all swatches (live from day one)
- Personalised educational message for light direction (not blurred preview, but explaining what light direction means for their room)

**Palette Plus (£3.99/month or £29.99/year):**

- Everything in Free, plus:
- Palette editing (add, remove, swap)
- Light direction recommendations per room (full, not blurred)
- 70/20/10 planner with auto-generation and furniture lock
- Red Thread whole-house flow with coherence checking
- "Why This Room Works" explanations on all recommendations
- Unlimited moodboards with share and export (Phase 1D)
- Colour Capture save to palette with clash warnings (Phase 1D)
- Sample ordering flow with testing reminders (Phase 1D)
- Room Checklist and progress tracking
- PDF export of room plans and Red Thread
- 5 AI Visualiser credits/month (Phase 3)

**Palette Pro (£7.99/month or £59.99/year):**

- Everything in Plus, plus:
- 25 AI Visualiser credits/month (Phase 3)
- "Complete the Room" product recommendations per room (Phase 2)
- Room shopping lists with affiliate links (Phase 2)
- Paint & Finish Recommender with quantities (Phase 2)
- Partner Mode with shared palette and budget alignment (Phase 2)
- Seasonal refresh suggestions (Phase 2)
- AI design assistant (Phase 3)

**Project Pass (£24.99 one-time):**

- 6 months of full Palette Pro access
- For users who prefer a one-time purchase for a defined project
- **Expiry behaviour:** When the 6 months end, the user downgrades to Free. All data preserved. They retain view access to everything they created but lose premium features. Gentle re-conversion prompt 2 weeks before expiry and on expiry day. No data ever deleted.

**AI Visualiser Credit Top-ups:**

- 10 credits for £1.99 (in-app purchase, available to any tier)

**Paywall copy restructure:**
The upgrade screen should lead with outcomes, not features. Instead of "Edit & customise palette" lead with "Avoid expensive colour mistakes" or "Get personalised recommendations for every room." Show a blurred preview of what the premium output looks like (blurred Red Thread, blurred room recommendations) before the paywall.

**Conversion triggers (contextual upgrade prompts):**

- After creating second room: "Unlock light-matched recommendations for all your rooms"
- When tapping Red Thread with 3+ rooms: blurred preview + "See how your rooms connect"
- When tapping Export: "Save your room plan as a PDF"
- When trying to edit palette: "Customise your palette to match your evolving taste"
- When tapping "Save to Palette" in Colour Capture: "Add colours to your palette with clash warnings"
- Phase 2: When viewing "Complete the Room": "Get personalised product recommendations"

**Annual pricing framing:** "Less than a Farrow & Ball sample pot per month."

**Acceptance Criteria:**

- Paywall screen leads with outcome-focused copy
- Blurred previews shown for at least 2 premium features before paywall
- Conversion triggers fire at contextually appropriate moments
- Tier differentiation is immediately clear
- Price is visible on the upgrade screen (currently not visible in screenshot 10)

---

#### Feature 1B.7: Renter Mode Enhancement

Renter Mode currently shifts the 70/20/10 planner to lock walls and focus on furniture/accessories. This needs to be expanded into a first-class experience that makes renters feel the app was built for them.

**Renter onboarding expansion:**
When "Renter" is selected during onboarding or room setup, ask additional constraint questions:

- Can you paint? (Some landlords allow it)
- Can you drill or mount things on walls?
- Are you keeping existing flooring?
- Is this a temporary home or long-term rental?
- Do you want reversible changes only?

These answers are stored per-home (not per-room) and filter all subsequent recommendations.

**Renter Mode adaptations:**

| Feature                           | Owner Mode                         | Renter Mode                                                            |
| --------------------------------- | ---------------------------------- | ---------------------------------------------------------------------- |
| 70/20/10 Hero (70%)               | Wall paint colour                  | Largest furniture piece or rug                                         |
| 70/20/10 focus                    | Walls, ceilings, woodwork          | Furniture, textiles, accessories                                       |
| Red Thread                        | Colour through paint + furnishings | Colour through furnishings + textiles only                             |
| Product recommendations (Phase 2) | Full range                         | Filtered to freestanding, removable, renter-safe items                 |
| White Finder                      | Active (paint focus)               | Replaced with "Neutral Finder" for textiles/furniture (if can't paint) |
| Room Checklist                    | Includes "Paint colour"            | Replaces with "Key textile colour"                                     |
| Wall modifications                | Shelving, art hanging, wallpaper   | Leaning art, peel-and-stick, command strips                            |
| Educational content               | Full paint guidance                | "Style Without Painting" guides                                        |

**Landlord palette detection:**
If renters cannot paint, prompt them to identify their existing wall colour: photograph the wall, or select from common landlord colours (Magnolia, Builder's White, Cool Grey, Off-White). The app identifies the undertone and recommends complementary furnishings that work with those fixed walls.

**Dynamic algorithm restructuring (Gemini's insight):**
For renters who cannot paint, the entire 70/20/10 algorithm restructures. Instead of walls being the Hero, the Hero shifts to the rug (to define the floor) and the sofa/bed (the largest visual items). The algorithm recalculates from these anchors outward. This is not just "hiding paint features" but a fundamentally different design canvas.

**Move-out portability:**
Since renters move more often, their Colour DNA and design preferences should travel with them. When setting up a new home, the app should offer: "Moving to a new place? Here's how to adapt your palette to your new rooms."

**Renter-specific product categories (Phase 2):**

- Removable wallpaper and wall decals
- Peel-and-stick tiles (bathroom/kitchen backsplash)
- Freestanding furniture (no built-ins)
- Soft furnishing layers (rugs over existing flooring, throws over existing sofas)
- Lighting (plug-in pendants, floor lamps, table lamps, LED strips)
- Leaning art and mirrors (no drilling)
- Renter-safe hardware swaps (drawer pulls, showerheads)
- Portable storage and shelving

**Important UX principle:** Renter Mode must feel additive, not restrictive. Label adaptations as "Renter Edition" or "Designed for renters" rather than "Limited Mode." The messaging should be: "Make this place feel like yours without risking your deposit."

**Acceptance Criteria:**

- Renter constraint questions appear during onboarding or room setup
- Constraints are stored per-home and filter all recommendations
- 70/20/10 algorithm dynamically restructures for renters who cannot paint
- Landlord palette detection identifies undertone from common wall colours
- Renter Mode feels like a tailored experience, not a stripped-down one
- All renter adaptations are reversible if the user later buys a property

---

### Phase 1C: Web Acquisition Funnel (PARALLEL EFFORT)

**Theme:** Turn the Colour DNA quiz into a viral acquisition channel. This is a separate web project that ships alongside or shortly after Phase 1B.

**Status: Not started.**

#### Feature 1C.1: Web Colour DNA Quiz

The Colour DNA quiz as a standalone web page (no app install required). The web version delivers a teaser result (palette family, archetype name, top 3 colours, shareable card). The full detailed result (complete palette, paint matches, room recommendations) is gated behind app download.

**Tech stack:** Astro (ships zero JS by default, hydrates only interactive islands). Hosted on Vercel or Cloudflare Pages (free tier).

**Shared colour logic:** JSON configuration files (`palette_families.json`, `colour_mappings.json`) consumed by both the Dart app and the Astro site. CIE Lab computation happens app-side only.

**Quiz result storage:** Supabase (same instance as app backend). One `quiz_results` table: `id`, `email` (nullable), `palette_family`, `archetype`, `colours_json`, `property_context`, `created_at`, `claimed_by_user_id` (nullable).

**API endpoints:** Supabase Edge Functions:

- `POST /quiz-result` (saves result, returns `result_id`)
- `GET /quiz-result/:id` (retrieves for app import)

**Shareable card:** Server-rendered OG image via Supabase Edge Function so shared links have a beautiful preview on Instagram/WhatsApp without client-side rendering.

#### Feature 1C.2: Web-to-App Handover

**Primary mechanism: Campaign URL parameters.**
When the user finishes the web quiz, the result is saved to Supabase with a unique `result_id`. The "Download App" button links to App Store / Play Store with the `result_id` encoded in the campaign URL (iOS: `ct` parameter; Android: `referrer` parameter). On first app launch, the app checks for the campaign parameter and fetches the result from Supabase.

**Secondary mechanism: Email save.**
Prominently offered on the web result screen (not buried). User enters email, result stored server-side keyed to that email, app prompts "Enter the email you used for the web quiz" on first launch.

**Tertiary: Browser cookie** as a bonus for users who download quickly (within 7 days, before Safari ITP purges).

**Universal Links and App Links:** Host `apple-app-site-association` and `assetlinks.json` on the domain so `palette.app/quiz/[result_id]` opens the app if installed. Free platform features, no third-party provider needed.

**Acceptance Criteria:**

- Web quiz completable in under 3 minutes without app install
- Teaser result shows archetype name, top 3 colours, shareable card
- Full result gated behind app download
- Campaign URL handover works on iOS and Android
- Email save is prominent and functional
- Shared links render a beautiful OG image preview

---

### Phase 1D: Retention and Deepening (ORIGINAL PHASE 1B)

**Theme:** Features that make the product stickier but do not drive the initial "aha" moment. Build after validating Phase 1B conversions.

---

#### Feature 1D.1: Colour Capture (Camera Extraction)

Users point their camera at any surface and capture its colour.

**How it works:**

Camera viewfinder with reticle/target. Tap to capture. App samples pixels, averages to dominant colour (k-means for patterns), converts to CIE L*a*b\* for matching.

**Important:** Phone cameras auto-adjust white balance and exposure. The captured colour is the perceived colour under current lighting, not the true surface colour. The app matches the captured colour to closest paints in the database and reports the undertone/palette family of those paint matches. This is more reliable and useful than trying to classify the physical surface.

Capture screen displays:

- Captured colour swatch with "For best results, capture in natural daylight" tip
- 3 closest paint matches (brand, name, code, price, undertone)
- Palette fit indicator (delta-E thresholds: < 25 green, 25-40 amber, > 40 gentle warning)
- "Nudge warmer/cooler" slider for manual adjustment

**Free/premium boundary:** Free users can capture, view results, save to moodboard. Premium gate on "save to palette with clash warnings."

**Acceptance Criteria:**

- Colour extraction works in real time
- At least 3 paint matches displayed sorted by delta-E proximity
- Palette fit uses defined thresholds
- "Capture in natural daylight" guidance in viewfinder

---

#### Feature 1D.2: Digital Moodboards

Room-specific moodboards. Free: 1 moodboard (build only, no share/export). Premium: unlimited with share and export.

Users add colour swatches (auto-populated from 70/20/10), web images via share extension, camera photos, and products from curated catalogue (Phase 2).

Auto-generated colour summary shows alignment with room's planned palette.

Share link works without app (premium). PDF export includes colour summary and all items (premium). Image-heavy moodboards (10+ images) may need server-side PDF generation.

---

#### Feature 1D.3: Sample Ordering Flow

From any room or palette, users add colours to a "Sample List." App aggregates across rooms, groups by brand, links to each brand's sample ordering page.

Follow-up prompt 3-5 days later: "Have your samples arrived? Here's how to test them properly." Links to guide based on Sowerby's moveable-card method.

---

#### Feature 1D.4: Re-engagement and Notification Strategy

Notifications OFF by default. Opt-in prompt after first room profile completion. Users who decline still see in-app prompts on Home Dashboard.

_Project-based prompts:_

- Saturday morning "weekend project" nudge
- Progress celebrations
- Sample follow-up

_Life-event prompts:_

- Moving day countdown (user enters completion date)
- "First Christmas in your new home" (October)
- Spring textile refresh
- Clocks change reminder

All dismissible. Frequency configurable (daily/weekly/off).

---

### Phase 2: The Recommendation Engine

**Theme:** Move users from planning to purchasing with confidence. This is the biggest leap in usefulness and the primary monetisation unlock.

**Ship order:** Furniture Lock expansion first (data capture), then product recommendations, then shopping lists, then seasonal refresh.

---

#### Feature 2.1: Expanded Furniture Lock ("What You Already Own")

The current furniture lock is a placeholder (screenshot 04 shows "+ Lock existing furniture" button). This needs to become a rich data capture system because it is the data that makes all recommendations personal and defensible.

**User Stories:**

- As a user, I want to photograph my existing furniture and have the app understand its colour, material, and style so that recommendations work around what I already own.
- As a user, I want to mark items as "keeping" or "replacing" so that the app knows what to recommend.

**How it works:**

For each locked item, the user provides:

- Photo (optional but encouraged)
- Category (sofa, bed, table, rug, chair, shelving, lighting, storage, other)
- Primary colour (extracted from photo via Colour Capture, or manually selected)
- Primary material (wood, metal, fabric, leather, glass, stone, wicker/rattan, plastic)
- Status: keeping, might replace, replacing
- Assigned 70/20/10 tier (which tier does this item occupy?)

The app extracts colour from the photo and auto-assigns undertone. Locked items with "keeping" status become hard constraints. "Might replace" items are soft constraints (recommendations may suggest upgrades). "Replacing" items generate active recommendations.

**Why this matters:** Once the app knows the user has a warm brown leather sofa (keeping), a light oak coffee table (keeping), and wants to replace their rug, the recommendation engine can suggest a specific rug that grounds those two items, matches the room's undertones, and fits the budget bracket.

**Acceptance Criteria:**

- Users can lock multiple items per room
- Photo capture extracts dominant colour and suggests material
- Each item has keep/might-replace/replacing status
- Locked items visually appear in the room's 70/20/10 plan
- Algorithm adjusts recommendations around kept items

---

#### Feature 2.2: "Complete the Room" Product Recommendations (Pro)

The core commercial feature. Based on the room's 70/20/10 plan, light direction, mood, locked furniture, and budget bracket, the app generates curated product recommendations organised by what the room still needs.

**User Stories:**

- As a Pro user, I want to see 3-4 product recommendations for what my room needs next so that I can buy with confidence.
- As a user, I want to understand why each product was recommended so that I trust the suggestion.
- As a user, I want to see options at different price points so that I can choose what fits my budget.

**How it works:**

Below the 70/20/10 plan in room detail, a "Complete the Room" section shows:

_Missing layers analysis:_
The app identifies what the room is missing based on the Design Rules Engine:

- "Your room needs a grounding rug" (no rug locked in 70% tier)
- "Add layered lighting" (no task or accent lighting)
- "Introduce texture contrast" (all locked items are smooth surfaces)
- "Add your accent colour" (10% tier empty)

_Product recommendations per gap:_
For each identified gap, show 3-4 product options:

- Product image, name, brand, price
- "Why this works" explanation (2 sentences max, referencing Design Rules)
- "Buy" button with affiliate link
- At least one affordable alternative in every set
- Budget bracket filter applied before results shown

_Commission disclosure:_ "We may earn a commission on purchases" visible on the recommendations section.

**Product data model:**

```
category: String (sofa, rug, lamp, cushion, throw, vase, mirror, art, table, chair, shelving, curtain, blind)
style: String[] (modern, traditional, scandi, mid-century, industrial, bohemian, minimalist)
primaryColour: Lab colour
undertone: warm | cool | neutral
materials: String[] (wood-oak, wood-walnut, metal-brass, metal-chrome, fabric-linen, fabric-velvet, leather, glass, ceramic, rattan)
priceGBP: Number
retailer: String
affiliateUrl: String
imageUrl: String
dimensions: { width, height, depth } (for scale checking)
renterSafe: Boolean
removable: Boolean
```

**Phase 2A launch scope:** Start with 3 categories: paint, rugs, lighting. These have the highest combination of emotional importance, affiliate commission rates, and purchase frequency. Expand to furniture, soft furnishings, and accessories in Phase 2B.

**Product sourcing approach:** Begin with a manually curated catalogue of 50-100 items per category, selected for colour variety, price range, and affiliate availability. The curation ensures quality recommendations while the catalogue is small. Scale to automated sourcing via affiliate network APIs as volume grows.

**Acceptance Criteria:**

- Missing layers analysis identifies at least one gap for rooms with incomplete 70/20/10
- 3-4 product options per gap, sorted by relevance score
- Every recommendation has a "Why this works" explanation
- At least one affordable option per set
- Budget bracket filter applied
- Commission disclosure visible
- "Buy" buttons use affiliate links where available, plain links where not
- Renter Mode filters to renter-safe products only

---

#### Feature 2.3: Paint & Finish Recommender with Shopping List

Finish recommendations based on Sowerby's guide (matt for living rooms/bedrooms, eggshell for woodwork, satin for bathrooms/kitchens). Paint calculator estimates quantity from room dimensions. Shopping list aggregates all paint across rooms with brand, colour, code, finish, quantity, price, and "Buy This Paint" deep links.

---

#### Feature 2.4: Seasonal Refresh Suggestions

Quarterly prompts suggesting small changes within the existing palette:

- "Spring refresh: swap your accent cushions to dusty rose. It brings warmth to your east-facing bedroom's morning light."
- "Autumn: add a chunky knit throw in your deepAnchor colour to cosy up the living room."

Each suggestion links to shoppable products. Drives repeat engagement and affiliate revenue.

---

#### Feature 2.5: Partner Mode

Partner invited via link or email. Partner completes their own Colour DNA (free, via web if no app). Shared Palette shows overlap and divergence. Both partners react to choices (love, like, unsure, not for me). Budget alignment indicator on product recommendations.

---

### Phase 3: Visual Confidence

**Theme:** Show people how choices will look before they commit.

---

#### Feature 3.1: AI Room Visualiser

Users photograph their room. The app uses Decor8 AI's `/change_wall_color` endpoint with a hex colour code. Scope at launch: wall colour only (ceiling/trim not targetable). Time-of-day light simulation is local post-processing (Palette's proprietary differentiator, zero API cost).

Comparison mode: two colour options side by side (2 credits).

**Privacy:** "Your room photo is processed by our AI partner and is not stored after the visualisation is generated." Negotiate DPA with Decor8 before Phase 3 development.

**Credit-based pricing:**

- Pro: 25 credits/month
- Plus: 5 credits/month
- Top-up: 10 credits for £1.99
- Non-subscribers: 10 for £2.99

---

#### Feature 3.2: AI Design Assistant

Conversational interface where users ask "What colour should I paint my hallway?" and get an answer grounded in their Colour DNA, Red Thread, and room data. This is the "pocket interior designer" experience. Powered by the Design Rules Engine.

---

### Phase 4: Full Home Companion

**Theme:** Extend beyond colour and furnishings into complete interior design.

- **Lighting Planner:** Three-layer lighting recommendations (ambient/task/accent) per room.
- **Room Audit Checklist:** Watson-Smyth's design rules codified with visual scoring.
- **Renovation Sequencing:** Lightweight guide adapted to property type.
- **Seasonal Refresh Prompts:** Ongoing textile/accessory swap suggestions.
- **Before & After Sharing:** Photo journey sharing for organic growth.

---

## Screen Architecture (Updated)

**Tab 1: Home ("Your Design Plan")**
Next recommended action card, room progress cards with completion scores, whole-home coherence summary (Red Thread compact view), curated "Recommended for you" section (Phase 2, pulling from Colour DNA and rooms).

**Tab 2: Rooms**
Room list with hero colours and completion indicators visible. Room profiles (direction, mood, 70/20/10, furniture lock, "Why This Room Works", room checklist, "Complete the Room" product recs). Red Thread accessible from top of list (premium, blurred preview for free).

**Tab 3: Capture**
Camera colour extraction. One-tap save to palette or moodboard. Recently captured colour history.

**Tab 4: Explore**
Three sections: Tools (Colour Wheel, White Finder, Paint Library), Learn (educational content), Your Palette (Red Thread, Colour DNA summary).

**Tab 5: Profile & Settings**
Colour DNA summary with design identity guidance, account, preferences, partner management, subscription status, notification settings, Colour Blind Mode toggle, Renter/Owner toggle, sample order history.

---

## Monetisation Model

### Revenue Streams (Priority Order)

**Primary: Affiliate Commerce (product recommendations)**
When users buy recommended products through in-app links, Palette earns commission. This is the biggest long-term revenue opportunity and aligns incentives (good recommendations drive revenue).

| Category                                    | Typical Commission | Average Order Value | Revenue per conversion |
| ------------------------------------------- | ------------------ | ------------------- | ---------------------- |
| Paint (Farrow & Ball, Little Greene, Dulux) | 5-10%              | £50-80              | £2.50-8                |
| Furniture (sofa, bed, dining)               | 5-12%              | £500-2,000          | £25-240                |
| Lighting                                    | Up to 21%          | £100-500            | £21-105                |
| Rugs                                        | 5-10%              | £200-800            | £10-80                 |
| Soft furnishings (curtains, cushions)       | 8-10%              | £30-200             | £2.40-20               |
| Accessories                                 | 8-14%              | £20-100             | £1.60-14               |

**Key principle:** Recommendation first, commission second. Commerce should feel like the result of good advice, not the reason for it.

**Secondary: Subscriptions (Plus, Pro, Project Pass)**
The design tools tier (Plus) and the recommendation tier (Pro) create a clear value ladder. Project Pass captures high-intent users who prefer one-time purchase.

**Tertiary: AI credit top-ups**
Visualiser credits for Phase 3.

**Future: Sponsored brand collections**
Branded collections that feel editorial: "Curated by Farrow & Ball for North-Facing Rooms." Maximum one sponsored collection visible at any time. Charged as flat fee to brand.

### Biggest Purchases to Optimise Around

**For owners:** Sofas (£1,000-3,000), beds/mattresses (£500-2,000), dining tables (£400-1,500), large rugs (£200-800), curtains/blinds (£200-600), lighting (£100-500), paint (£150-500), accent furniture (£200-1,000).

**For renters:** Rugs (define the floor), curtains (frame windows), lighting (floor/table lamps), bedding, throws/cushions, art, mirrors, side tables, shelving/storage, peel-and-stick decor.

First-time buyers spend over £15,500 furnishing a new home. The UK home decor market is approximately £25.7 billion (2026). Furniture accounts for over 55% of spending.

### Affiliate Programmes

| Brand         | Network               | Commission                 | Cookie  | Notes                       |
| ------------- | --------------------- | -------------------------- | ------- | --------------------------- |
| Farrow & Ball | Awin (UK: ID 20199)   | Up to 5% content, 3% base  | 30 days | Apply via Awin              |
| Dulux         | Awin (ID 12009)       | 5% base                    | 30 days | UK-only, same Awin account  |
| Little Greene | Sovrn Commerce        | Varies (auto-monetisation) | Varies  | Product mentions auto-link  |
| Lick          | CJ Affiliate / direct | ~1%                        | Unknown | Low rate. Also sold via B&Q |
| B&Q           | Impact                | 2% delivery + C&C          | Unknown | Sells Lick, Dulux, Crown    |
| Freshlick     | Awin (ID 101923)      | 2% opening                 | 30 days | Multi-brand fallback        |
| COAT          | Direct negotiation    | TBD                        | TBD     | Club COAT loyalty model     |

**Implementation:** Build deep-link fallback ladder and "Buy This Paint" flow with plain product links. Affiliate tracking is a pluggable config layer (link resolver + attribution params per brand). When Awin approves, prepend tracking URL to existing database URLs.

---

## User Personas (Updated)

**Persona 1: "The Overwhelmed First-Timer" (Primary)**
Mia, 31. Just bought a 1930s semi in Essex with partner Tom. 400+ Pinterest pins, no plan. Loves green but terrified of mistakes. Bringing a brown leather sofa and IKEA pieces from rented flat. Never heard of undertones or 70/20/10.
_Needs:_ Confidence, education, framework, "what to buy next" for each room, furniture lock to work around what she's keeping. Likely Plus subscriber converting to Pro when product recs launch.

**Persona 2: "The Taste-Confident Upgrader" (Secondary)**
Raj, 37. Moving from rented flat to Victorian terrace in south London. Strong style opinions (jewel tones, mid-century). Great individual purchases that don't cohere. Frustrated by rooms that look good in photos but feel "off."
_Needs:_ Red Thread, light direction, curated product recommendations that create coherence. Likely Pro subscriber or Project Pass buyer.

**Persona 3: "The Long-Term Renter" (Secondary)**
Priya, 28. Renting a 2-bed flat in Manchester. Cannot paint but wants personal space. Spends on cushions, throws, and prints that never quite come together. Frustrated that most design apps assume she can renovate.
_Needs:_ Renter Mode as a first-class experience. 70/20/10 restructured around furniture and textiles. Recommendations filtered to removable/renter-safe items. "Style Without Painting" guidance. Likely Plus subscriber.

**Persona 4: "The Reluctant Partner" (Tertiary)**
Sam, 34. Partner of someone deep in decorating decisions. Does not care much about interiors but wants an opinion without studying colour theory. Defaults to "whatever you think" or vetoes without explanation.
_Needs:_ Partner Mode. May never install the app; interacts via web links.

---

## Competitive Positioning (Updated)

| Competitor                    | What They Do                        | What They Miss                                                  | Palette's Edge                                              |
| ----------------------------- | ----------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------- |
| Dulux Visualizer              | AR paint preview                    | No palette planning, no education, no whole-house, single-brand | Multi-brand, education-first, whole-house, product recs     |
| Lick                          | Curated paint collections           | Walled garden, no personalisation, no light direction           | Brand-agnostic, personalised to emotional palette and light |
| Houzz                         | Inspiration library + pro directory | US-centric, bloated, no guided decisions                        | UK-focused, algorithmic decisions, no human designer needed |
| Pinterest                     | Infinite inspiration                | Zero structure, causes decision paralysis                       | Solves inspiration-to-decision-to-purchase gap              |
| HomeDesignsAI / ReimagineHome | AI room restyling                   | No persistent home model, no whole-house, no education          | Persistent home model, ongoing relationship, teaches why    |
| Havenly / Decorilla           | Human designer per room             | £100-300+ per room, US-focused, one-off                         | Algorithmic, continuous, affordable, UK-focused             |
| Planner 5D / Homestyler       | 3D floor plans and layout           | Complex, not colour-focused, not recommendation-driven          | Simpler, outcome-focused, shoppable                         |

**Positioning:** Palette is the first interior design app that starts with who you are, knows your home, and tells you exactly what to buy for each room and why it works.

**Moat:** Persistent whole-home data model (hard to retrofit). Red Thread requires whole-house context from day one. Brand-agnostic positioning (paint brands cannot replicate). Education-first approach builds trust that shopping apps cannot match. Curated paint colour database (5,000+ colours normalised to CIE Lab) has standalone value. Algorithmic Design Rules Engine creates defensible recommendation quality.

---

## Design Principles (UX)

**1. The app should feel like a well-designed room, not a tech product.**
Warm whites, soft creams, muted earth tones as the base palette. A single warm accent (sage green) for interactive elements (blue alternative in Colour Blind Mode). Clean sans-serif body type with an editorial serif for headings. Full-bleed imagery. No neon gradients, no heavy shadows, no "startup" aesthetic.

**2. Progressive disclosure, always.**
Show summary views first. Reveal complexity gradually. Surface the 3 most relevant actions at any stage. Use bottom sheets and overlays, not new screens.

**3. Rooms are the centre, tools are secondary.**
Every screen should answer at least one of: What suits my room? What should I buy next? Why does this work? How does this connect to the rest of my home? What can I do within my constraints? If a feature does not clearly answer one of these, it is secondary.

**4. Every recommendation teaches.**
No recommendation appears without a "why this works" explanation. The app is a trusted advisor, not a shopping catalogue.

**5. Image-first layouts.**
Colour swatches, room photos, product images, and moodboards are the heroes. Text supports images.

**6. Celebrate progress.**
Small animations at milestones. Skeleton loading states. Spring physics for transitions. Room completion scores drive engagement.

**7. Card-based UI with generous breathing room.**
Status indicators use icons as primary signal (checkmark, clock, empty circle) with colour supplementary. Generous padding. State changes must be obvious. Buttons must feel tappable. Labels must be legible. Soft palette should not sacrifice clarity on key actions.

**8. Context-aware navigation.**
Adapts emphasis based on journey stage: discovery, planning, acting, maintaining.

**9. Accessible by default.**
Dynamic Type (iOS) and font scaling (Android) from day one. Never rely on colour alone. Every swatch shows its name. WCAG AA contrast ratios throughout. Colour Blind Mode as settings toggle.

**10. Colour disclaimer always visible.**
"Colours on screens are approximations. Always test physical samples before committing." Present in onboarding, on swatch detail views, and in exports.

**11. Branded terms have plain-English support.**
Every branded term (Colour DNA, Red Thread, Hero colour) should have a plain-English subtitle underneath to aid mainstream understanding. Examples:

- Red Thread: "Keep your whole home feeling connected"
- Colour DNA: "Your personal design identity"
- Hero colour: "The main colour for this room"

---

## Resolved Decisions

### 1. Paint Colour Database

**Decision: Build our own local database. No paid API at launch.**

Data sources, per-brand effort estimates, and pipeline approach unchanged from original spec. See original spec section for full detail.

**Phase 1A shipped with:** ~500-1,500 colours across initial brands. Paint names display throughout the app. Delta-E matching and undertone classification operational.

**Internal data model:** CIE L*a*b\* as primary colour space (sRGB/D65). Schema: brand, name, code, Lab, RGB, hex, LRV, undertone, palette family, collection, approximate price per litre (indicative, with "last checked" date).

**The data pipeline is a first-class deliverable.** Versioned, repeatable process (script + versioned JSON). Ingest > convert to Lab > auto-classify undertone > assign palette family > output versioned JSON bundled at build time.

### 2. AI Room Visualiser

**Decision: Decor8 AI at ~£0.16/image ($0.20), Phase 3 only. Credit-based pricing.**

Privacy/data handling requires DPA negotiation before development. See original spec for full detail.

### 3. Light Simulation

**Decision: Kelvin lookup + RGB blend overlay at 10-20% opacity. Local computation. Zero cost.**

### 4. Product Catalogue Scope

**Decision: Phase 2 launch with paint, rugs, lighting. Expand to furniture and soft furnishings in Phase 2B. All affiliate-based, zero upfront cost.**

### 5. Offline Capability

**Decision: Offline-first. Local database is source of truth.**

Offline: Palette, rooms, wheel, moodboards (viewing), paint library, Red Thread, light simulation, Colour Capture.
Online: AI Visualiser, product recommendations, web image saving, share/export, Partner Mode sync, sample ordering, web quiz result retrieval, "Complete the Room" product data.

### 6. Colour Blind Accessibility

**Decision: First-class from day one.** Named swatches, icon-first status, WCAG AA, shape-based indicators, Dynamic Type. Colour Blind Mode toggle adds pattern overlays, W/C badges, blue accent alternative.

### 7. Tech Stack

**Decision: Flutter.** Impeller rendering for 60fps animations. CustomPainter for colour wheel and light overlays. Decor8 AI Dart SDK. Offline-first via SQLite/Hive. PowerSync for Supabase sync.

### 8. Backend

**Decision: Supabase + PowerSync.** Auth, real-time sync (Partner Mode), row-level security, PostgreSQL. PowerSync for offline-first sync layer.

### 9. App Store Colour Accuracy

**Decision: No specific policy exists. Ship the disclaimer.** See original spec.

### 10. Affiliate Programmes

**Decision: Apply to Awin. Launch with plain links. Add tracking when approved.** See affiliate table above.

### 11. Web Quiz Infrastructure

**Decision: Astro + Supabase Edge Function + shared JSON config.** See Phase 1C.

### 12. Web-to-App Handover

**Decision: Build lightweight handoff. No paid deep link provider at MVP.** Campaign URL parameters (primary), email save (secondary), cookie (tertiary). See Phase 1C.

---

## Implementation Status

_Updated March 2026 after strategic review._

### Phase 1A: ~95% complete (native app)

| Feature                         | Status | Notes                                                                                   |
| ------------------------------- | ------ | --------------------------------------------------------------------------------------- |
| 1.1 Colour DNA Onboarding (app) | Done   | 14 archetypes, system palette roles, DNA drift detection                                |
| 1.2 My Palette                  | Done   | Palette Story, feedback engine, paint name display throughout                           |
| 1.4 Room Profiles               | Done   | 70/20/10, furniture lock (placeholder), renter mode (basic), light sim, room psychology |
| 1.5 Colour Wheel & White Finder | Done   | Zoomable wheel, undertone toggle, DNA overlay, context-aware whites                     |
| 1.6 The Red Thread              | Done   | Templates, adjacency list, coherence check, PDF export                                  |

**Phase 1A remaining gaps:**

- Free user blurred preview for light direction recs (currently fully gated, should show blurred preview with upgrade CTA)
- Red Thread flow visualisation (diagram showing colour flow through rooms)
- Shareable Colour DNA card deep-linking to web quiz (depends on Phase 1C)

### Phase 1B: Not started (NEW PRIORITY)

| Feature                            | Status      | Priority |
| ---------------------------------- | ----------- | -------- |
| 1B.1 Home Screen Redesign          | Not started | Highest  |
| 1B.2 Room Detail Enhancement       | Not started | Highest  |
| 1B.3 Explore Tab Reorganisation    | Not started | High     |
| 1B.4 Paint Library Personalisation | Not started | High     |
| 1B.5 Colour DNA Expansion          | Not started | Medium   |
| 1B.6 Paywall Restructure           | Not started | High     |
| 1B.7 Renter Mode Enhancement       | Not started | High     |

### Phase 1C: Not started (PARALLEL)

| Feature                  | Status      | Notes                            |
| ------------------------ | ----------- | -------------------------------- |
| 1C.1 Web Colour DNA Quiz | Not started | Separate Astro project           |
| 1C.2 Web-to-App Handover | Not started | Requires Supabase Edge Functions |

### Phase 1D: Not started (DEFERRED)

| Feature                            | Status           | Notes                                           |
| ---------------------------------- | ---------------- | ----------------------------------------------- |
| 1D.1 Colour Capture                | Placeholder only | Route exists at `/capture`, shows "Coming Soon" |
| 1D.2 Digital Moodboards            | Not started      |                                                 |
| 1D.3 Sample Ordering               | Not started      |                                                 |
| 1D.4 Re-engagement & Notifications | Not started      |                                                 |

### Phase 2: Not started

| Feature                              | Status      | Notes                          |
| ------------------------------------ | ----------- | ------------------------------ |
| 2.1 Expanded Furniture Lock          | Not started | Prerequisite for product recs  |
| 2.2 "Complete the Room" Product Recs | Not started | Core commercial feature        |
| 2.3 Paint & Finish Recommender       | Not started |                                |
| 2.4 Seasonal Refresh                 | Not started |                                |
| 2.5 Partner Mode                     | Not started | Enums exist, no implementation |

### Phase 3: Not started

| Feature                 | Status      | Notes                                |
| ----------------------- | ----------- | ------------------------------------ |
| 3.1 AI Room Visualiser  | Not started | Decor8 AI integration, credit system |
| 3.2 AI Design Assistant | Not started | Conversational interface             |

### Features added beyond original spec

These emerged during Phase 1A implementation and strengthen the core product:

- **Colour Archetypes** (14 personality-driven identities with system palette roles)
- **DNA Drift Detection** (tracks preference evolution, prompts re-engagement)
- **Palette Feedback Engine** (contextual natural-language impact descriptions)
- **Palette Story/Review Sheet** (magazine-style visual analysis with colour swatches)
- **Paint Name Display** (hex codes replaced with real paint names throughout)
- **Room Colour Psychology** (mood-to-colour recommendation mapping)
- **Locked Furniture Conflict Detection** (warns when constraints contradict)
- **QA Mode** (debug-only developer tools at `/dev` route)

---

## Success Metrics (Updated)

### Phase 1A + 1B (Current + Connective Tissue):

- Quiz completion rate: 70%+
- Quiz share rate: 15%+
- Rooms per user: 3+
- Room completion score: average 4+ of 6 steps per room
- Home screen "Next action" tap-through rate: 30%+
- Free-to-Plus conversion: 5%+
- Free-to-Pro conversion: 2%+ (combined paid: 7%+)
- Project Pass as % of paid: 15%+
- "Buy This Paint" CTR (all users including free): 3%+
- W4 retention: 25%+
- App Store rating: 4.5+

### Phase 1C (Web Funnel):

- Web quiz completion rate: 60%+
- Web quiz to app download: 25%+
- Web quiz share rate: 20%+

### Phase 2 (Recommendation Engine):

- "Complete the Room" engagement: 60%+ of Pro users interact
- Product recommendation CTR: 8%+
- Affiliate conversion: 2%+
- "Buy This Paint" CTR: 5%+ (increase from Phase 1)
- Partner Mode adoption: 20% of Pro users
- Sample order conversion: 15% of users with 3+ rooms
- Days from first room to first purchase: target under 14 days

### Phase 3 (Visual Confidence):

- Visualiser usage: 4+ per month per credit holder
- Credit top-up rate: 10% of visualiser users

### Long-term:

- MAU retention at 12 months: 15%
- ARPU (paying users): £5/month
- Project Pass renewal/conversion: 30%+
- NPS: 50+

---

## Boundaries (For AI Agent Development)

**Always do:**

- Run tests before committing code
- Follow naming conventions and code style
- Handle errors with user-friendly messages
- Plain language only in UI text
- Test colour displays on light and dark backgrounds
- Validate colour calculations produce visually correct results
- Support Dynamic Type (iOS) and font scaling (Android)
- Include colour disclaimer on paint colour screens
- Pair colour with icon/label/pattern (never colour alone)
- Include "Why this works" explanation with every recommendation
- Apply Renter Mode constraints to all recommendation logic
- Use British English spellings throughout

**Ask first:**

- Before adding any new dependency
- Before modifying data model or schema
- Before changing navigation or adding screens
- Before integrating any external API
- Before architectural decisions affecting multiple features
- Before implementing notification/push logic
- Before adding a new product category to recommendations
- Before changing the Design Rules Engine scoring weights

**Never do:**

- Never commit API keys, secrets, or credentials
- Never remove a failing test without approval
- Never auto-generate palette algorithms without visual review
- Never hardcode brand-specific data that should come from a data layer
- Never skip accessibility (contrast ratios, screen reader, Dynamic Type)
- Never use em dashes in any user-facing text or documentation
- Never use colour alone to convey information
- Never use red/green pairings in UI status indicators
- Never show a product recommendation without a "why this works" explanation
- Never present Renter Mode as a "limited" or stripped-down experience
- Never show affiliate links without commission disclosure

---

## Remaining Open Questions

### 1. Paint data: brand responses

**Action:** Email Lick, COAT, and e-paint.co.uk. Sign up for Encycolorpedia Pro. **Deadline:** Responses within 1-2 weeks. Manual curation in parallel. **Fallback:** Manual curation from websites (small ranges ~1 day each). **Resolved when:** 500+ colours across 2+ brands confirmed.

### 2. Decor8 AI: privacy and data processing

**Action:** Email privacy@decor8.ai before Phase 3 development. Negotiate DPA. **Deadline:** Before Phase 3 starts. **Fallback:** Alternative providers or prominent consent screen.

### 3. COAT Paints affiliate structure

**Action:** Clarify during colour data outreach. **Fallback:** Plain links without tracking.

### 4. Product recommendation catalogue sourcing (NEW)

**Action:** Determine initial product sourcing approach for Phase 2. Options: (a) manually curate 50-100 items per category from affiliate retailers, (b) use Awin product feeds for automated sourcing, (c) hybrid: manual curation for launch, API feeds for scale. **Deadline:** Before Phase 2 development begins. **Key decision:** Manual curation ensures quality but does not scale. API feeds scale but require filtering logic to maintain recommendation quality. Recommend hybrid: manual v1, API v2.

### 5. Renter Mode depth (NEW)

**Action:** Validate whether the full algorithmic restructuring (shifting 70% Hero from walls to rug/sofa) resonates with renters through user testing. Simpler constraint toggling may be sufficient for v1. **Deadline:** During Phase 1B development. **Fallback:** Ship constraint toggling first, restructure algorithm based on feedback.

### 6. Seasonal refresh content cadence (NEW)

**Action:** Determine who creates seasonal refresh content and product selections. Options: (a) manually curated quarterly by Jamie, (b) algorithmically generated from palette + season + available products, (c) sponsored collections from brand partners. **Deadline:** Before Phase 2.4 development.

---

## Cost Summary

| Item                 | Phase 1                                | Phase 2                | Phase 3         |
| -------------------- | -------------------------------------- | ---------------------- | --------------- |
| Paint database       | Zero (or $29.99/yr Encycolorpedia Pro) | Zero                   | Zero            |
| Product catalogue    | Zero                                   | Zero (affiliate-based) | Zero            |
| AI Visualiser        | Zero                                   | Zero                   | ~£0.16/vis      |
| Light simulation     | Zero                                   | Zero                   | Zero            |
| Offline storage      | Zero                                   | Zero                   | Zero            |
| Accessibility        | Zero                                   | Zero                   | Zero            |
| Web quiz hosting     | Minimal (free tier)                    | Minimal                | Minimal         |
| Backend (Supabase)   | Free tier                              | Free tier              | Scale as needed |
| Deep linking         | Zero (platform-native)                 | Zero                   | Zero            |
| **Total fixed cost** | **~Zero**                              | **~Zero**              | **~Zero**       |

Variable cost from AI API only (Phase 3), offset by credit pricing.

---

_This is a living document. Update it as decisions are made, requirements change, or new insights emerge from building._

_Last updated: March 2026_
_Author: Jamie_
