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

### Paint Finish Rules (to implement in Phase 2)

Every paint recommendation includes a finish recommendation, not just a colour. The wrong finish undermines the right colour. These rules are encoded as a structured mapping in JSON configuration, not hardcoded logic.

**Surface-to-finish mapping:**

| Room Type       | Surface                          | Recommended Finish    | Why                                                                                            |
| --------------- | -------------------------------- | --------------------- | ---------------------------------------------------------------------------------------------- |
| Living room     | Walls                            | Matt / Flat           | Absorbs light evenly across large surfaces, hides imperfections, creates a calm backdrop       |
| Living room     | Woodwork (skirting, architraves) | Eggshell              | More durable than matt, easier to clean, subtle sheen creates definition between wall and trim |
| Living room     | Ceiling                          | Matt / Flat           | Reduces glare from overhead light, recedes visually to make the room feel taller               |
| Bedroom         | Walls                            | Matt / Flat           | Soft, restful quality, no reflective glare from bedside lighting                               |
| Bedroom         | Woodwork                         | Eggshell              | Same durability logic as living room                                                           |
| Kitchen         | Walls                            | Satin / Soft Sheen    | Wipeable, resists moisture and grease, holds up to daily wear                                  |
| Kitchen         | Woodwork                         | Satin                 | Maximum durability in high-traffic, high-moisture environment                                  |
| Kitchen         | Ceiling                          | Matt / Flat           | Hides condensation marks better than sheen finishes                                            |
| Bathroom        | Walls                            | Satin / Soft Sheen    | Essential for moisture resistance, prevents peeling and mould                                  |
| Bathroom        | Woodwork                         | Satin or Gloss        | Maximum moisture protection                                                                    |
| Bathroom        | Ceiling                          | Satin / Soft Sheen    | Moisture resistance on the surface most exposed to steam                                       |
| Hallway         | Walls (lower half)               | Eggshell / Satin      | High-traffic area, needs to withstand scuffs and be wipeable                                   |
| Hallway         | Walls (upper half)               | Matt / Flat           | Less exposed to contact, softer finish visually balances the sheen below                       |
| Hallway         | Woodwork                         | Eggshell              | Durability for high-traffic                                                                    |
| Children's room | Walls                            | Eggshell / Soft Sheen | Wipeable for inevitable handprints and marks                                                   |
| Children's room | Woodwork                         | Satin                 | Maximum durability                                                                             |
| Home office     | Walls                            | Matt / Flat           | Reduces screen glare, calm visual environment for focus                                        |

**Finish interaction with light direction:**

- North-facing rooms: matt finishes absorb already-limited light. Consider soft sheen on one feature wall to gently bounce light back into the room. The recommendation explains: "A soft sheen on your feature wall will help bounce the limited northern light around the room."
- South-facing rooms: matt works beautifully because there is plenty of natural light. Sheen finishes can create uncomfortable glare in bright southern light. The recommendation explains: "Matt is ideal here because your generous southern light means you don't need the finish to do any work reflecting light."
- East-facing rooms (morning light): matt is generally fine; the strong morning light compensates.
- West-facing rooms (evening light): same logic as east, but if the room is primarily used in the morning (when west-facing rooms are darker), consider soft sheen.

**Finish interaction with colour:**

- Dark colours in matt finish absorb more light and look deeper and richer, which is desirable for feature walls but can make a small room feel cave-like.
- Light colours in satin finish can look plasticky and cheap. Light colours almost always look best in matt or flat.
- The recommendation engine cross-references the chosen colour's LRV (Light Reflectance Value) with the finish recommendation: low-LRV colours in small rooms trigger a note: "This deep colour in matt will absorb a lot of light. Consider using it on a single feature wall rather than all four walls."

**Output format in recommendations:**
When recommending paint, the output includes colour + finish + surface + quantity + explanation:
"Use Savage Ground in Matt Emulsion for your living room walls (2.5L for two coats), and Savage Ground in Eggshell for the skirting boards (1L). Matt absorbs light evenly across large surfaces, while eggshell on your woodwork is more durable and easier to clean."

### Finish and Material Harmony Rules (to implement in Phase 2)

Products are not just colours. A brass lamp, a chrome tap, an oak table, and a velvet cushion each bring a material character that affects how the room feels. The Design Rules Engine scores product recommendations not just on colour compatibility but on whether the product's finish and material harmonise with what is already in the room and with the user's design identity.

**Archetype-to-finish mapping:**
Each Colour DNA archetype defines preferred finishes and materials (already captured in the archetype data model's `bestMetalFinishes`, `bestWoodTones`, `bestFabrics` fields). The recommendation engine explicitly cross-references these when scoring products:

| Archetype Family                                     | Preferred Metals                             | Preferred Woods                    | Preferred Fabrics                      | Avoid                            |
| ---------------------------------------------------- | -------------------------------------------- | ---------------------------------- | -------------------------------------- | -------------------------------- |
| Warm archetypes (Cocooner, Golden Hour, Velvet Whisper) | Antique brass, brushed gold, matte black     | Honey oak, walnut, weathered pine  | Linen, bouclé, chunky knit, velvet     | Chrome, high-gloss, acrylic      |
| Cool archetypes (Monochrome Modernist, Minimalist, Midnight Architect) | Brushed nickel, polished chrome, matte black | White oak, ash, light birch | Cotton, smooth linen, light wool | Brass, copper, dark stained wood |
| Rich archetypes (Curator, Storyteller, Dramatist)       | Aged brass, dark bronze, matte black         | Dark walnut, mahogany, ebony stain | Velvet, heavy linen, tapestry, leather | Chrome, plastic, light pine      |
| Nature archetypes (Nature Lover, Romantic)               | Matte black, copper, aged brass              | Reclaimed wood, teak, bamboo       | Jute, rattan, raw linen, cotton        | Chrome, high-gloss, synthetic    |
| Bold archetypes (Brightener, Colour Optimist, Maximalist) | Polished brass, chrome, copper             | Any with strong grain contrast     | Velvet, silk, bold-pattern cotton      | Muted finishes, weathered looks  |
| Soft archetypes (Romantic)                           | Rose gold, brushed gold, antique brass       | Light oak, painted white wood      | Velvet, silk, sheer linen              | Industrial metals, raw concrete  |

**The Wood Tone Harmony Check:**
When a user has locked furniture with a specific wood tone, the recommendation engine checks new product recommendations against it:

- Same wood tone family: strong match, but flag if it creates monotony ("Both your table and this shelf are honey oak, which is harmonious but consider a darker accent piece for contrast")
- Compatible undertone, different tone: ideal ("Your honey oak table pairs beautifully with this walnut shelf because both have warm undertones but the contrast adds depth")
- Clashing undertone: warning ("This ash shelf has cool undertones that may clash with your warm honey oak table. Consider walnut or teak instead")

**The Metal Finish Consistency Check:**
A room should have a dominant metal finish with at most one accent metal. The recommendation engine tracks which metals are already present (from locked furniture and previous recommendations):

- Same metal as existing: safe, consistent
- Complementary metal (e.g., brass + matte black): good contrast, encouraged
- Clashing metal (e.g., brushed nickel + antique brass): flagged with explanation ("Your room already has chrome lighting. This brass lamp would introduce a second warm metal that competes. Consider a matte black option that bridges warm and cool.")

**The Fabric Texture Balance Check:**
The recommendation engine tracks the texture profile of locked items and fills gaps:

- All smooth surfaces (leather, glass, polished wood): aggressively recommend high-texture items (chunky knit throw, woven rug, rattan basket)
- All soft/plush surfaces (velvet, carpet, upholstered everything): recommend harder textures (glass, metal, smooth ceramic) for contrast
- Good mix already: recommend items that maintain the balance

**Sheen coherence:**
Products with visible sheen (polished metal, high-gloss ceramic, lacquered wood) are tracked. Too many high-sheen items in one room creates visual noise. The engine flags when sheen saturation is high: "Your room already has several reflective surfaces. This matte ceramic vase adds visual calm."

### Multi-Colour Product Handling

Many products (rugs, cushions, curtains, patterned ceramics) contain multiple colours. The product data model captures `primaryColour` and `secondaryColour` (both as Lab values), plus an optional `patternColours` array for products with three or more significant colours.

**Scoring logic for multi-colour products:**

- Primary colour is scored at full weight against the room's palette (delta-E, undertone compatibility)
- Secondary colour is checked for clashes: if the secondary colour's undertone conflicts with the room's dominant undertone, the product is penalised. If the secondary colour matches a Red Thread colour or an accent tier colour, the product is boosted.
- Pattern colours (if present) are checked for any strong clashes (delta-E > 40 against any locked item). One clash is acceptable for accent pieces; multiple clashes disqualify.

**Explanation for multi-colour products:**
The "why this works" copy acknowledges the secondary colours: "The warm ochre base harmonises with your Cocooner palette, and the cream pattern picks up your trim white, tying the rug to your woodwork." Or: "The dominant teal complements your accent tier, while the gold thread connects to your antique brass lighting."

### Scoring Dimensions (for the Recommendation Engine, Phase 2)

When recommending any product, score it across these dimensions with explicit weights:

| Dimension                                                                                                      | Weight | Rationale                                                                                 |
| -------------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------- |
| Colour compatibility (delta-E to palette, including secondary/pattern colour checks for multi-colour products) | 22%    | Core product promise                                                                      |
| Undertone compatibility (warm/cool alignment)                                                                  | 15%    | The subtle expertise users cannot do themselves                                           |
| Finish and material harmony (metal/wood/fabric compatibility with locked items and archetype preferences)      | 13%    | The dimension no other app scores; connects products to each other and to design identity |
| Budget fit (within room's bracket)                                                                             | 13%    | Hard constraint; violating this breaks trust                                              |
| Style fit (matches Colour DNA archetype aesthetic)                                                             | 12%    | Personalisation differentiator                                                            |
| Material balance (adds missing texture/material to the room's texture profile)                                 | 10%    | Design rule application: texture layering, fabric balance, sheen coherence                |
| Scale fit (appropriate for room size)                                                                          | 10%    | Prevents the "rug too small" problem                                                      |
| Renter suitability (removable/freestanding if Renter Mode)                                                     | 5%     | Binary filter for renters                                                                 |

Additional soft scoring factors applied after primary ranking: warmth/coolness correction (compensates for light direction), whole-home coherence (contains Red Thread colour or compatible material), room function fit (appropriate for room type and usage), contrast contribution (adds needed visual contrast or calm), wood tone harmony (compatible with existing locked wood items), metal finish consistency (no more than one dominant + one accent metal per room).

Weights are stored in a JSON configuration file, not hardcoded. This allows tuning based on aggregate engagement data (click-through rates, dismiss reasons) without code changes.

Each recommendation surfaces a plain-language "why this works" explanation referencing the top 2-3 scoring dimensions and the specific room context that informed the recommendation. Structure: [Rule reference] + [Specific room context]. Example: "This rug grounds your seating area (Scale Rule) and its warm gold undertone harmonises with your south-facing evening light (Light Direction)."

---

## Phased Feature Plan

The app ships in five phases. Each phase is a complete, usable product. The phasing reflects the strategic pivot toward room outcomes and product recommendations, with a new Phase 1E added to address conversion, polish, and instrumentation gaps identified through expert review.

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

- The Cocooner, The Golden Hour, The Curator, The Monochrome Modernist, The Romantic, The Colour Optimist, The Nature Lover, The Storyteller, The Velvet Whisper, The Maximalist, The Brightener, The Dramatist, The Midnight Architect, The Minimalist

Each archetype defines a structured "system palette" with functional roles: trimWhite, dominantWalls, supportingWalls, deepAnchor, accentPops, and spineColour. This role-based structure ensures every generated palette has the right balance for real-room application.

The archetype engine uses weighted scoring across palette family affinity, undertone temperature, and saturation preference, with secondary family blending.

**Archetype practical guidance (implemented in Phase 1B.5):**

Each archetype includes practical design attributes:

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

The palette screen shows 8-12 colours in a visually pleasing layout. Each colour is tappable to reveal its palette family, undertone, colour wheel relationships, and matched paint colours from UK brands with names, codes, and approximate prices per litre.

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

Users create rooms (free: up to 2 rooms; premium: unlimited). For each room:

- Room name (preset list or custom)
- Direction the main window faces (N/S/E/W, or compass detection)
- Primary usage time (morning, afternoon, evening, all day)
- Desired mood (calm, energising, cocooning, elegant, fresh, grounded, dramatic, playful)
- Budget bracket per room (affordable / mid-range / investment)

**Room Dimensions (added in Phase 1E):**
Each room captures approximate dimensions for sizing recommendations:

- Room size: small / medium / large (quick picker, default)
- Optional manual entry: length x width in metres (override)
- Property type defaults used as fallback ("A typical 1930s semi-detached living room is approximately 4m x 5m")

**Light Direction Recommendations (Premium):**
Cross-references room's light direction and usage time against the user's palette to generate tailored colour recommendations. North-facing evening rooms get different suggestions than south-facing morning rooms. This is the primary conversion trigger.

_Free user experience:_ Free users enter compass direction (data stored for upgrade). They see a personalised educational message about their room's light characteristics. Below the educational message, a blurred preview of the premium recommendations is shown with an upgrade CTA.

_Premium user experience:_ Full light-matched recommendations with specific colour suggestions tailored to direction, usage time, and mood.

**70/20/10 Planner (Premium, Progressive Entry):**
The user picks one hero colour. The app auto-generates:

- 70% Hero: walls, curtains, largest furniture
- 20% Beta: one large piece plus 1-2 smaller touches (analogous or complementary, filtered by light direction)
- 10% Surprise: something unexpected (complementary or split-complementary from a different palette family)
- Dash: connecting colours from other rooms (the red thread)

The algorithm is deterministic (rule-based colour theory, not ML).

**Existing Furniture Lock (implemented, basic):**
Users "lock" items they are keeping. The algorithm adjusts remaining tiers to accommodate locked items. Furniture conflict detection warns when multiple locked items have conflicting undertones/saturation. See Phase 2A for the expanded Furniture Lock.

**Room Colour Psychology (implemented):**
Structured mapping from room moods to colour recommendations based on colour science. Each mood maps to recommended palette families, undertone preferences, and saturation ranges.

**Renter Mode (implemented):**
If "Renter" was selected during onboarding, the 70/20/10 planner shifts focus. Walls locked to landlord's existing colour. Planner concentrates on the 30% the renter controls: furniture (20%) and accessories/textiles/art (10%). See Phase 1B.7 for full Renter Mode details.

**Light Simulation Preview (implemented):**
Three swatches side by side: morning, midday, evening. Kelvin lookup + RGB blend overlay at 10-20% opacity. LRV data adds brightness indicator. Phrased as "helpful preview" not "photorealistic simulation."

**Compass UX:** "Point your phone toward this room's main window and hold still." Only N/S/E/W classification needed (90-degree buckets).

---

#### Feature 1.5: Interactive Colour Wheel and White Finder [COMPLETE]

**What shipped:**

A zoomable, tappable colour wheel. Selecting any colour highlights complementary, analogous, triadic, and split-complementary relationships. Each has a one-sentence explanation. Undertone layer toggleable. DNA overlay shows where the user's palette colours sit on the wheel.

**Contextual entry (implemented in Phase 1E):** When opened from a room profile, the wheel pre-selects the user's hero colour and shows relationships relative to their palette rather than starting from a blank slate.

**White Finder:** Spectrum of whites organised by undertone (blue, pink, yellow, grey) with Sowerby's "Paper Test" tutorial. When accessed from a room profile, pre-filters to whites that suit the room's light direction. DNA Match badges indicate which undertone families harmonise with the user's Colour DNA.

**Badge legend:** On first view, a small legend tooltip explains the badge labels (W = Warm undertone, C = Cool undertone, N = Neutral undertone). The legend is dismissible and accessible from a small info icon thereafter.

**Room context header:** When accessed from a room, the White Finder shows "Finding whites for your south-facing Living Room" at the top, reinforcing that this is not an abstract tool.

---

#### Feature 1.6: The Red Thread (Whole-House Flow) [COMPLETE]

**What shipped:**

Users select a floor plan template based on property type (Victorian Terrace, 1930s Semi-Detached, Post-War Estate, Modern Flat, New Build). Each template has predefined tappable room zones. Users assign rooms to zones.

For property types not covered by templates, users build an adjacency list: add rooms, declare connections.

Red thread defined at the top: 2-4 colours that appear in some form in every room. The app highlights where threads appear and flags rooms with no thread colour present. Coherence check is set intersection.

Thread colours show brand attributions and role descriptions (e.g., "Burlywood, Dulux: Connects naturally to your whole palette"). Room Transitions section allows defining connections between rooms.

**Red Thread Flow Visualisation (implemented in Phase 1E):**
A visual node-and-edge diagram showing how colour flows through the house. Each room is a node showing its hero colour swatch and name. Edges connect adjacent rooms, coloured with the thread colour(s) they share. Rooms missing a thread colour are highlighted with a gentle warning state. Example: Living Room [Savage Ground] > Hallway [Burlywood thread] > Bedroom [Dark Buff accent]. The diagram is tappable; tapping a room node navigates to its room detail. The diagram is exportable as an image (premium).

**Adjacent room comparison:** Tapping two connected rooms shows their palettes side by side.

**Whole-house view:** Exportable as image and PDF (premium).

**Free user experience:** Blurred preview of the flow visualisation shown after creating 3+ rooms, with upgrade CTA.

---

### Phase 1B: Connect the Dots (COMPLETE)

**Theme:** Transform the existing colour toolkit into a connected, guided experience. Make the app feel like it knows your home and tells you what to do next, rather than presenting isolated tools.

---

#### Feature 1B.1: Home Screen Redesign ("Your Design Plan") [COMPLETE]

The Home screen becomes "Your Design Plan" with three sections:

_1. Next Recommended Action (top, most prominent):_
A single, contextual card recommending the user's most impactful next step. The card uses outcome-led language, not feature-led:

- "Connect your 3 rooms so the house feels cohesive" (not "Define your Red Thread")
- "Choose the right white for the kitchen before buying samples" (not "White selection missing")
- "Your bedroom still needs a grounding colour" (not "Hero colour not set")
- "Your living room needs a grounding rug to anchor the sofa" (Phase 2, when product recs are live)
- "Test your paint samples this weekend. Morning light is best for your east-facing kitchen" (after sample ordering)

The logic for determining the next action follows a priority hierarchy:

1. Complete room setup (rooms with missing direction, mood, or hero colour)
2. Define Red Thread (after 3+ rooms exist)
3. Resolve coherence issues (rooms flagged by Red Thread)
4. Find the right white (rooms with hero but no white selected)
5. Lock existing furniture (rooms with empty furniture lock)
6. Product recommendations (Phase 2, rooms with no "Shop this room" activity)

_2. Project Progress (middle):_
Room cards with visual progress indicators. Each room shows:

- Hero colour swatch (used to fill progress segments instead of generic green)
- Completion score: direction set, mood set, hero colour chosen, 70/20/10 planned, white selected, furniture locked, Red Thread connected
- Status: "3 of 7 steps complete"
- One-line summary: "South-facing, Evening, Cocooning"

Progress tracking is gamified: small animations at milestones ("You've planned 3 of 5 rooms!").

_3. Whole-Home Coherence (bottom):_
A compact Red Thread summary showing:

- Thread colours as small swatches
- One-line coherence verdict: "Your warm neutral scheme flows well across 3 rooms" or "Your kitchen is drifting cooler than the rest of the home"
- Tap to open Red Thread detail

_4. Mini palette strip (top, below greeting):_
A small row of the user's Colour DNA swatches above the main content. This provides emotional context ("look what you're building") alongside the functional next-action card.

**Explore tools strip:** The Explore cards (Colour Wheel, White Finder, Paint Library, Red Thread) live in the Explore tab exclusively. They do not appear on the Home screen. Instead, these tools are surfaced contextually from within room profiles and recommendations (e.g., "Find the right white" button in room detail links directly to the White Finder pre-filtered for that room).

---

#### Feature 1B.2: Room Detail Enhancement ("Room Decision Board") [COMPLETE]

The Room Detail screen is the most important screen in the app. It is where colour theory meets reality and where users build purchase confidence.

**Screen structure (ordered by importance):**

1. **Room header with tags** (South-facing, Evening, Cocooning)
2. **"Why This Room Works" card** (the emotional payoff, 2-3 sentences connecting room context to colour plan)
3. **Hero colour with 70/20/10 visual**
4. **Room Checklist** (collapsed by default once 4+ items complete, expandable)
5. **Room Preview** (colour-blocked mockup, see below)
6. **Action buttons** (Find white, Lock furniture, Connect thread)

**"Why This Room Works" card:**
A 2-3 sentence explanation connecting the room's tags to its colour plan. Example: "Because your living room faces south and you prefer evenings, Savage Ground's warm undertone will glow beautifully in golden-hour light. The cool green accent creates contrast without fighting the warmth."

This card updates dynamically when any room setting changes. It references the specific inputs used: direction, usage time, mood, hero colour, locked furniture, and Red Thread status.

**Room Preview (colour-blocked mockup):**
Even before AI visualisation (Phase 3), a simple colour-blocked representation of the room shows the 70/20/10 proportions using the actual selected colours. Three rectangles showing proportional areas with the hero, beta, and surprise colours. This addresses the Visualisation Gap (Problem #1) at zero API cost and creates a tangible "wow" moment when the hero colour is chosen.

**Room Checklist:**
Visual checklist showing what is configured and what is missing. Each incomplete item is tappable and navigates to the relevant configuration step with explicit action copy:

- Direction set (checkmark or "Set direction")
- Mood selected (checkmark or "Choose mood")
- Hero colour chosen (checkmark or "Pick hero colour")
- 70/20/10 plan complete (checkmark or "Complete colour plan")
- White selected (empty circle with "Choose white")
- Existing furniture locked (empty circle with "Add furniture")
- Red Thread connected (checkmark or "Connect this room")

Each incomplete item uses pill-shaped buttons with chevrons to make interactivity obvious.

**Contextual tool links:**
Replace standalone tool navigation with in-context links:

- "Choose white" navigates to White Finder pre-filtered for this room's direction
- "See how colours change through the day" links to light simulation for this room's hero colour
- "Check whole-home coherence" links to Red Thread with this room highlighted

---

#### Feature 1B.3: Explore Tab Reorganisation [COMPLETE]

Three sections:

_1. Tools:_

- Colour Wheel (contextual note: "See where your palette sits")
- White Finder (contextual note: "Find the right white for your rooms and light")
- Paint Library (contextual note: "Browse colours from UK paint brands")

When room context exists, tool entries show personalised notes: "Recommended paints for your south-facing Living Room" instead of generic "Browse colours from UK paint brands."

_2. Learn:_
Educational content that builds confidence. Each is personalised to the user's context where possible:

- "Why undertones matter" (personalised: "Why your warm undertones work best with yellow-based whites")
- "How light direction changes colour" (personalised: "How your south-facing living room changes Savage Ground through the day")
- "The 70/20/10 rule explained"
- "What is a Red Thread?" (subtitle: "Keep your whole home feeling connected")
- "Choosing the right white" (Sowerby's Paper Test, expanded)

Each educational item is a card that expands into a short, image-rich walkthrough. Content is written in plain language with real examples. These are evergreen and created as static content. Format: illustrated card-based walkthroughs (not video at launch).

_3. Your Palette:_

- Red Thread (contextual note: "Plan colour flow across your whole home")
- Colour DNA summary (quick access to archetype and palette)

---

#### Feature 1B.4: Paint Library Personalisation [COMPLETE]

**Enhancements:**

_"Works with my palette" filter:_
A toggle filter that shows only paints compatible with the user's Colour DNA (delta-E < 25 from any palette colour, or matching undertone family). When active, each paint shows a small badge explaining the match: "Harmonises with your warm earth tones" or "Complements your Cocooner palette."

_"Recommended for [room name]" badges:_
When browsing, paints that suit a specific room's light direction show a room badge: "Good for your north-facing kitchen."

_Price bracket filter:_
A primary filter alongside existing "My palette" / "Brand" / "Family" options. Three tiers: £ (under £25/L), ££ (£25-50/L), £££ (over £50/L). First-time homeowners (primary persona) are price-conscious; seeing Benjamin Moore at £72/L alongside Crown at £16/L without context creates sticker shock.

_Sorting by relevance:_
Default sort prioritises paints that match the user's palette and room contexts, not alphabetical or brand-first.

---

#### Feature 1B.5: Colour DNA Expansion ("Your Design Identity") [COMPLETE]

Below the existing palette display and "Why these colours work" section, a "Your Design Identity" card with practical guidance:

- **Best materials:** "Warm oak, linen, antique brass, textured ceramics"
- **Best moods:** "Cocooning, elegant, grounded"
- **What to avoid:** "Stark cool whites, chrome-heavy finishes, high-gloss surfaces"
- **Best wood tones:** "Honey oak, walnut, weathered pine"
- **Best metal finishes:** "Antique brass, brushed gold, matte black"

---

#### Feature 1B.6: Paywall Restructure [COMPLETE, updated in Phase 1E]

**Restructured tiers:**

**Free:**

- Colour DNA quiz and shareable result
- Personal palette (view only, no edits)
- Up to 2 rooms (enough to experience the product, not enough to complete a home)
- Basic room setup (direction, mood, hero colour)
- Colour Wheel and White Finder (browse only)
- 1 moodboard (Phase 1D)
- Colour Capture (view results, save to moodboard, not palette) (Phase 1D)
- Educational content
- "Buy This Paint" affiliate links on all swatches (live from day one)
- Personalised educational message for light direction
- Blurred preview of premium recommendations (light direction, 70/20/10, Red Thread) with upgrade CTA
- Room Preview (colour-blocked mockup)

**Palette Plus (£3.99/month or £29.99/year):**

- Everything in Free, plus:
- Unlimited rooms
- Palette editing (add, remove, swap)
- Light direction recommendations per room (full, not blurred)
- 70/20/10 planner with auto-generation and furniture lock
- Red Thread whole-house flow with coherence checking and flow visualisation
- "Why This Room Works" explanations on all rooms
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
- Seasonal refresh suggestions (Phase 2)
- AI design assistant (Phase 3)

**Project Pass (£24.99 one-time):**

- 6 months of full Palette Pro access
- For users who prefer a one-time purchase for a defined project
- **Trigger:** Surfaced specifically when a user creates 4+ rooms within the first week, signalling active renovation mode. Copy: "Looks like you're decorating your whole home. Get 6 months of everything for less than one hour with an interior designer."
- **Expiry behaviour:** When the 6 months end, the user downgrades to Free. All data preserved. They retain view access to everything they created but lose premium features. Gentle re-conversion prompt 2 weeks before expiry and on expiry day. No data ever deleted.

**14-Day Free Trial of Palette Plus:**
Triggered after the user creates their second room. The user has invested effort (room setup data) that creates switching cost, and the trial lets them experience light direction recommendations and 70/20/10 planning before committing. Trial converts to annual billing by default (with clear disclosure). Trial users who do not convert retain all their data in view-only mode.

**AI Visualiser Credit Top-ups:**

- 10 credits for £1.99 (in-app purchase, available to any tier)

**Paywall design principles (updated in Phase 1E):**

The upgrade screen leads with visual outcomes, not feature lists:

- Show the user's own room data in a blurred preview: "See how Savage Ground will look in your south-facing living room at sunset"
- Use outcome-led headlines: "Avoid expensive colour mistakes" not "Edit & customise palette"
- Show a before/after: blurred premium output (Red Thread flow, room recommendations) above the paywall
- Price visible and anchored: "Less than a Farrow & Ball sample pot per month"
- Primary CTA button uses a warm accent colour that stands out from the sage green palette, making it the most prominent element on the screen

**Conversion triggers (contextual upgrade prompts):**

- After creating second room: "Unlock light-matched recommendations for all your rooms"
- Attempting to create third room (free limit): "Your home has more than 2 rooms. Unlock your full design plan"
- When tapping Red Thread with 3+ rooms: blurred preview + "See how your rooms connect"
- When tapping Export: "Save your room plan as a PDF"
- When trying to edit palette: "Customise your palette to match your evolving taste"
- When tapping "Save to Palette" in Colour Capture: "Add colours to your palette with clash warnings"
- Phase 2: When viewing "Complete the Room": "Get personalised product recommendations"

---

#### Feature 1B.7: Renter Mode Enhancement [COMPLETE]

Renter Mode currently shifts the 70/20/10 planner to lock walls and focus on furniture/accessories. This is expanded into a first-class experience that makes renters feel the app was built for them.

**Renter onboarding expansion:**
When "Renter" is selected during onboarding or room setup, additional constraint questions:

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

**Dynamic algorithm restructuring:**
For renters who cannot paint, the entire 70/20/10 algorithm restructures. Instead of walls being the Hero, the Hero shifts to the rug (to define the floor) and the sofa/bed (the largest visual items). The algorithm recalculates from these anchors outward. This is not just "hiding paint features" but a fundamentally different design canvas.

**RoomModeConfig strategy pattern (implemented):**
A single configuration object replaces scattered if/else renter branches. The config drives labels, available features, checklist items, and recommendation filters based on the user's renter constraints.

**Move-out portability:**
Since renters move more often, their Colour DNA and design preferences travel with them. When setting up a new home, the app offers: "Moving to a new place? Here's how to adapt your palette to your new rooms."

**UX principle:** Renter Mode feels additive, not restrictive. Label adaptations as "Renter Edition" or "Designed for renters" rather than "Limited Mode." The messaging is: "Make this place feel like yours without risking your deposit." Onboarding copy: "We'll help you create a home you love, deposit intact." The 70/20/10 visually shows what is locked (landlord walls) versus what is the user's canvas (furniture, textiles, lighting). The renter path gets the same narrative warmth, recommendation richness, and visual polish as the owner path.

---

### Phase 1C: Web Acquisition Funnel (PARALLEL EFFORT)

**Theme:** Turn the Colour DNA quiz into a viral acquisition channel. This is a separate web project that ships alongside Phase 1E or early Phase 2.

**Priority note:** The web quiz should ship as early as possible. It is the lowest-cost acquisition channel (shareable Colour DNA cards on Instagram Stories), enables Partner Mode v1 later (partner takes quiz on web without installing), and generates installs that Phase 2 converts to revenue. These are complementary, not sequential.

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

---

### Phase 1D: Retention and Deepening

**Theme:** Features that make the product stickier but do not drive the initial "aha" moment. Build after validating Phase 1E conversions.

**Status: Not started.**

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

### Phase 1E: Conversion, Polish & Instrumentation (NEW)

**Theme:** Tighten the last 10% of the app around guidance, visibility, confidence, and measurement before building the commerce engine. Expert review identified that the app has strong intelligence but users still do too much interpretation before feeling ready to spend. This phase closes that gap.

**Ship order:** Analytics instrumentation first (you cannot improve what you do not measure), then visual polish, then conversion optimisation, then the remaining feature gaps.

---

#### Feature 1E.1: Analytics Instrumentation

**Why this is first:** Without event tracking, none of the success metrics can be validated. The web acquisition funnel (Phase 1C) and commerce engine (Phase 2) cannot be optimised without stage-by-stage data.

**Analytics tool:** PostHog (self-hostable, privacy-respecting, generous free tier) or Supabase logging (zero additional cost).

**Event taxonomy (minimum viable):**

_Onboarding:_

- `quiz_started`, `quiz_stage_completed` (with stage number), `quiz_skipped` (with stage number), `quiz_completed`, `quiz_shared`
- `archetype_assigned` (with archetype name)
- `quiz_drop_off_stage` (which stage they abandoned)

_Rooms:_

- `room_created`, `room_step_completed` (with step name), `room_deleted`
- `room_checklist_item_tapped` (with item name)
- `room_completion_score_changed` (with old/new score)
- `red_thread_created`, `red_thread_room_connected`

_Conversion:_

- `paywall_viewed` (with trigger source), `paywall_dismissed`, `upgrade_tapped` (with tier), `upgrade_completed` (with tier and billing period)
- `trial_started`, `trial_converted`, `trial_expired`
- `blurred_preview_viewed` (with feature name)
- `project_pass_viewed`, `project_pass_purchased`

_Commerce:_

- `buy_paint_tapped` (with brand, colour, source screen), `buy_paint_completed` (if trackable via affiliate)
- `product_rec_viewed`, `product_rec_tapped`, `product_rec_dismissed` (with reason), `product_rec_saved`
- `affiliate_link_tapped` (with product category, price, retailer)

_Engagement:_

- `colour_wheel_opened` (with context: standalone vs room), `white_finder_opened` (with context)
- `paint_library_filtered` (with filter type), `palette_edited`
- `explore_learn_card_opened` (with article name)
- `time_on_screen` (for key screens: room detail, home, explore)

_Retention:_

- `session_started`, `session_duration`, `days_since_last_session`
- `notification_opt_in`, `notification_tapped`

---

#### Feature 1E.2: A/B Testing Infrastructure

Build the ability to test variations on the most conversion-sensitive surfaces before Phase 2 adds density:

- Different paywall copy and layouts
- Different entry points for upgrade prompts (after room 2 vs. room 3)
- Annual vs. monthly default selection
- Blurred preview intensity
- Trial length (7-day vs. 14-day)
- Next-action card copy variations

**Implementation:** Feature flag system (PostHog feature flags, or simple Supabase-backed config). Each user assigned to a cohort at first launch. Cohort assignment stored locally and synced to analytics.

---

#### Feature 1E.3: Blurred Premium Previews

**Why this matters:** Research on progressive paywall patterns shows that showing users a tantalising preview of premium output (then gating the full detail) converts 2-3x better than fully hiding the feature. Currently, premium features show a hard lock (padlock icon). This must change to blurred previews that create desire.

**Where to implement:**

1. **Light Direction recommendations (Room Detail):** Generate the actual recommendations for the user's room, render them blurred with an upgrade CTA overlaid. The user can see that specific, personalised content exists for their room.

2. **70/20/10 planner preview (Room Detail):** Show the colour breakdown blurred, with the hero colour visible but beta and surprise colours obscured.

3. **Red Thread flow visualisation:** Show the flow diagram with room names visible but colour swatches blurred. The structure is visible; the specific guidance is gated.

4. **"Complete the Room" product recommendations (Phase 2):** Show that recommendations exist for the user's room (category labels visible, product images blurred).

**Design:** Each blurred preview includes: a 2-3 word description of what the content is ("Your personalised colour plan"), the blurred content, and a single CTA button ("Unlock with Palette Plus"). The blur level should be enough to obscure detail but allow the user to see that real, personalised content is present.

---

#### Feature 1E.4: Paywall Visual Redesign

The paywall screen is the single highest-leverage conversion surface. The current implementation leads with feature lists. The redesign leads with visual outcomes using the user's own data.

**Paywall structure:**

1. **Headline:** Outcome-led. "Avoid expensive colour mistakes" or "Get personalised recommendations for every room."
2. **Visual hero:** A blurred-then-revealed animation showing the user's own room data. Example: their Living Room's light direction recommendation, initially blurred, partially revealed to show the personalised content.
3. **Tier comparison:** Clean, scannable. Three tiers with clear value progression: Free = explore, Plus = plan, Pro = buy. Short descriptions, not exhaustive feature lists.
4. **Price with anchor:** "£3.99/month. Less than a Farrow & Ball sample pot per month."
5. **CTA:** Primary button in a warm accent colour (not the standard sage green) that stands out as the most prominent interactive element on the screen. Copy: "Start free trial" (if trial) or "Upgrade to Plus."
6. **Social proof:** "Join [X] homeowners planning with confidence" (once user count is meaningful).

---

#### Feature 1E.5: Visual Polish Pass

Address the visual hierarchy, contrast, and styling issues identified across all reviews. This is a systematic pass, not a redesign.

**Typography hierarchy:**
Establish a strict type scale applied consistently across all screens:

- Display weight: screen titles (e.g., "Your Design Plan", "Living Room")
- Section headings: card group labels (e.g., "Light & Direction", "Room Checklist")
- Card titles: individual card headers
- Body text: descriptions, explanations
- Caption: metadata, badges, timestamps

The editorial serif for headings should come through more strongly. Consider pairing a refined serif (Instrument Serif or DM Serif Display) for headings with the existing sans-serif body font.

**Sage green accent colour discipline:**
The sage green currently appears on buttons, progress bars, navigation highlights, tags, and card accents simultaneously. When everything is sage green, nothing stands out. Reserve the primary sage accent for primary CTAs and interactive elements only. Use a warm neutral (existing cream/gold tones) for secondary UI elements like tags and progress bars.

**Card depth system:**
Add clearer depth differentiation:

- Level 0 (flush): backgrounds
- Level 1 (subtle shadow): content cards, informational panels
- Level 2 (elevated shadow): interactive cards, CTAs, the "Next Action" card on Home

**Contrast accessibility pass:**
WCAG AA requires 4.5:1 contrast for normal text and 3:1 for UI components and large text. Run a systematic check on all screens, with particular attention to:

- Pale green labels on light backgrounds
- Muted secondary text
- Soft badge treatments on cards
- Disabled states and tertiary links
- All interactive elements (buttons, toggles, chips)

**Progress indicators:**
Replace generic green progress bar segments with the room's hero colour. This creates visual identity per room and makes progress feel personal rather than clinical.

---

#### Feature 1E.6: Branded Term Consistency

Every branded term must always appear with its plain-English subtitle. This is not optional; it is a systematic requirement across every screen where the term appears.

| Branded Term      | Plain-English Subtitle                 |
| ----------------- | -------------------------------------- |
| Colour DNA        | Your personal design identity          |
| Red Thread        | Keep your whole home feeling connected |
| Hero colour       | The main colour for this room          |
| 70/20/10          | Your room's colour balance             |
| Palette Story     | How your colours work together         |
| Colour Archetypes | Your design personality                |
| DNA Match         | Suits your personal palette            |

The subtitle appears in smaller, lighter text directly below or beside the branded term. It is persistent, not shown only on first encounter.

---

#### Feature 1E.7: Capture Tab Resolution

The Capture tab (Tab 3) currently leads to a "Coming Soon" screen. An empty tab in the primary navigation damages perceived app quality and user trust.

**Decision: Keep the 5-tab layout. Ship a minimal Colour Capture MVP (Option B).** A basic camera-to-colour extraction (photograph, identify dominant colour, show 3 closest paint matches). No palette integration, no clash warnings. Enough to make the tab functional and valuable. Do NOT remove the Capture tab.

---

#### Feature 1E.8: Red Thread Flow Visualisation

Implement the visual flow diagram described in Feature 1.6. This is the single most impactful remaining Phase 1 gap because it makes the app's most differentiated concept (whole-home coherence) tangible.

**Implementation:**
A node-and-edge diagram rendered with CustomPainter (Flutter). Each room is a rounded rectangle node containing the room name and hero colour swatch. Edges connect adjacent rooms, drawn as curved lines coloured with the shared thread colour(s). Rooms with no thread colour present show a subtle dashed border or warning indicator.

The diagram is scrollable and zoomable for homes with many rooms. Tapping a room node navigates to its room detail. A "Share" button exports the diagram as an image (premium).

---

#### Feature 1E.9: Room Preview Colour-Block Mockup

For each room with a hero colour and 70/20/10 plan, generate a simple colour-blocked representation showing the proportional colour balance. This is not a room render; it is an abstract visualisation of the colour proportions.

**Implementation:**
Three horizontal bands or rectangles:

- 70% band in the hero colour (largest area, representing walls/dominant surfaces)
- 20% band in the beta colour
- 10% band in the surprise/accent colour
- Optional thin line in the Red Thread dash colour

Labels on each band: "Walls & curtains", "Sofa & rug", "Cushions & art" (or renter equivalents).

This zero-cost visualisation addresses the Visualisation Gap and creates a satisfying output moment when the user completes their 70/20/10 plan.

---

#### Feature 1E.10: Applied State System

As more filters, badges, room matches, and recommendation contexts appear (especially in Phase 2), users need persistent evidence of the active context. Without this, users lose track of why they are seeing what they are seeing.

**Implementation:**

- Persistent filter chips above results in Paint Library, White Finder, and later product recommendations
- Room-context badge at the top of any tool accessed from a room: "Showing results for: Living Room (south-facing, evening)"
- Clear "Reset filters" action
- Filters remembered per room session (returning to a room's White Finder shows the same filters)

---

### Phase 1E Implementation Status

| Feature                               | Status      | Priority |
| ------------------------------------- | ----------- | -------- |
| 1E.1 Analytics Instrumentation        | Done        | P0       |
| 1E.2 A/B Testing Infrastructure       | Not started | P1       |
| 1E.3 Blurred Premium Previews         | Done        | P0       |
| 1E.4 Paywall Visual Redesign          | Done        | P0       |
| 1E.5 Visual Polish Pass               | Done        | P1       |
| 1E.6 Branded Term Consistency         | Done        | P1       |
| 1E.7 Capture Tab Resolution           | Done        | P1       |
| 1E.8 Red Thread Flow Visualisation    | Done        | P0       |
| 1E.9 Room Preview Colour-Block Mockup | Done        | P1       |
| 1E.10 Applied State System            | Not started | P2       |

---

### Phase 2: The Recommendation Engine

**Theme:** Move users from planning to purchasing with confidence. Colour intelligence powers personalised product recommendations that solve the Action Gap. This is the biggest leap in usefulness and the primary monetisation unlock.

**Core principle:** Palette wins if it feels like a calm, literate interior designer who knows your room and explains herself. Palette loses if it feels like a pastel affiliate storefront. Every product decision in Phase 2 is judged against that line. Diagnose first, recommend second, monetise third.

**Ship order:** Paint recommendations from existing data (immediate), then Furniture Lock expansion (data capture), then Room Gap engine, then rug recommendations, then lighting recommendations, then shopping lists, then paint & finish recommender, then seasonal refresh.

**The primary object in Phase 2 is a Room Gap, not a Product.** The user should never land in a generic shopping list. They should land in a diagnosis: what this room still needs, why that matters, and the best few ways to solve it.

**Commercial model:** Affiliate commerce. Every recommendation must pass two tests: (1) Would a good interior designer recommend this? (2) Does the "why this works" explanation teach the user something? If either answer is no, the product does not ship in that recommendation slot.

**Architectural decision:** Build the scoring engine as a configurable, category-agnostic system. Scoring dimensions and weights are defined in JSON configuration, not hardcoded. This lets you add new product categories by adding category data and adjusting weights, not rewriting the engine.

---

#### Phase 2A: Recommendation Foundations

---

##### Feature 2A.0: Paint Recommendations from Existing Data (Quick Win)

**Why this is first:** The existing Paint Library already contains 500+ colours with affiliate links, palette matching, and room context. Paint recommendations require zero new catalogue work. Filter the existing database by room context, add "Recommended for your [room]" badges, and surface contextual "Buy This Paint" affiliate links throughout the app (not just in the Paint Library, but also in Colour DNA results, Room Detail, White Finder, and Red Thread).

**Implementation:** Within the Room Detail screen, below the 70/20/10 plan, add a "Paint for this room" section showing 3-4 recommended paints filtered by: hero colour match, undertone compatibility with room direction, budget bracket. Each paint shows brand, name, swatch, price, and a "Buy" CTA.

**Effort estimate:** 1-2 weeks. Generates affiliate revenue immediately.

---

##### Feature 2A.1: Expanded Furniture Lock ("What You Already Own")

The current furniture lock is a basic placeholder. This becomes a rich data capture system because the data it generates makes all recommendations personal and defensible. Without knowing what the user already owns, recommendations feel generic immediately.

**User Stories:**

- As a user, I want to photograph my existing furniture and have the app understand its colour, material, and style so that recommendations work around what I already own.
- As a user, I want to mark items as "keeping" or "replacing" so that the app knows what to recommend.

**How it works: Photo-first, not form-first.**

The camera is the primary input. Users photograph an item, and the app auto-extracts colour (via Colour Capture logic) and suggests material and category. Manual entry is the fallback, not the primary flow.

**Progressive data capture (minimum viable lock is 3 taps):**

_Minimum viable lock:_

- Name/label (free text or preset)
- Category (sofa, bed, table, rug, chair, shelving, lighting, storage, other)
- Status: keeping / might replace / replacing

_Enhanced lock (optional, encouraged via "Want better recommendations? Add a photo"):_

- Photo (triggers auto-extraction)
- Primary colour (extracted from photo, with manual correction: "We detected warm brown. Is this correct?" with colour picker fallback)
- Primary material (wood, metal, fabric, leather, glass, stone, wicker/rattan, plastic)
- Wood tone (shown conditionally when material = wood): light oak, honey oak, walnut, dark stain, white-painted, reclaimed, teak, ash. This is critical for the Wood Tone Harmony Check in the scoring engine.
- Metal finish (shown conditionally when material = metal): antique brass, brushed gold, chrome, brushed nickel, matte black, copper, dark bronze. This is critical for the Metal Finish Consistency Check.
- Style (modern / traditional / eclectic, simple 3-option picker)
- Assigned 70/20/10 tier (which tier does this item occupy?)

_Advanced lock (for power users):_

- Visual weight: light / medium / heavy
- Finish/sheen: matte / low-sheen / polished
- Texture feel: smooth / low-texture / high-texture / chunky

**Camera white-balance fallback:**
Phone cameras auto-adjust white balance, often shifting warm woods grey or white sofas yellow. After auto-extraction, enforce a manual verification step: present the detected colour with a "Is this correct?" confirmation and material selector. The material is as important as the colour for balancing texture.

**"I don't have this yet" option:**
For first-time homeowners (primary persona), many rooms will be empty. The recommendation engine handles rooms with zero locked items as the default case, not an edge case. An "I don't have this yet" option alongside keeping/replacing is available for each category, and the engine recommends items for empty slots.

**Why this matters:** Once the app knows the user has a warm brown leather sofa (keeping), a light oak coffee table (keeping), an antique brass floor lamp (keeping), and wants to replace their rug, the recommendation engine can suggest a specific rug that grounds those two items, matches the room's warm undertones, adds the chunky texture the room is missing (all existing surfaces are smooth), avoids cool-toned metals that would clash with the brass lamp, and fits the budget bracket. The locked item data is what makes every recommendation feel like it was chosen by a designer who has actually been in the room.

**Recommendation quality gate:** In rooms with weak Furniture Lock data, the app says so honestly: "Add your sofa and rug to get better recommendations." This is better than pretending certainty the engine does not have.

---

##### Feature 2A.2: Room Gap Engine ("What This Room Still Needs")

The Room Gap is the primary diagnostic concept in Phase 2. Before recommending products, the app identifies what a room is missing based on the Design Rules Engine.

**Room Gap data model:**

```
gapType: rug | task-lighting | accent-lighting | ambient-lighting | texture-contrast | accent-colour | storage | artwork | curtain | throw | cushions | mirror | warm-material | cool-material | metal-clash | wood-clash | sheen-balance
severity: low | medium | high
confidence: low | medium | high
whyItMatters: String (plain-English sentence)
evidence: [String] (array of inputs used, e.g., "no rug locked", "all materials smooth", "room is north-facing", "accent tier empty")
recommendedCategories: [String] (ranked list)
blocker: String? (optional, e.g., "Add room dimensions for better rug sizing")
```

**Gap detection logic:**

The engine analyses each room's locked furniture, 70/20/10 plan, mood, direction, and Red Thread status against the Design Rules:

- "Your room needs a grounding rug" (no rug locked in 70% or 20% tier)
- "Add layered lighting" (no task or accent lighting locked)
- "Introduce texture contrast" (all locked items are smooth surfaces, or all are soft/plush)
- "Add your accent colour" (10% tier empty)
- "Your Red Thread colour isn't present in this room" (thread check fails)
- "This room has no soft surfaces" (texture layering rule violated)
- "Balance the visual weight" (all heavy items on one side, if dimensions captured)
- "Add a warm material" (room has only cool materials like chrome, glass; Material Balance rule violated)
- "Add a cool material" (room has only warm materials like wood, fabric; Material Balance rule violated)
- "Your metals are fighting each other" (3+ different metal finishes detected across locked items; Metal Finish Consistency Check violated)
- "Your wood tones have clashing undertones" (warm-toned and cool-toned woods locked in the same room; Wood Tone Harmony Check violated. Recommendation: swap one item or introduce a bridging material)
- "Too many reflective surfaces" (3+ high-sheen items locked; Sheen Coherence check triggered. Recommendation: add a matte-finish item to balance)

**Gap prioritisation:**
Gaps are ranked by severity (how much the room is affected) and confidence (how much data the engine has). A room with no rug, no lighting, and no accent colour shows the rug gap first (highest impact), not all three simultaneously. One confident next step is psychologically cleaner than multiple equally weighted suggestions.

**UI integration:**
Below the Room Checklist on the Room Detail screen, a "What this room still needs" section appears once the 70/20/10 plan exists. Each gap shows:

- Gap name in plain English ("Your room needs a grounding rug")
- Why it matters in one sentence ("Without a rug, the room feels unfinished and the sofa floats")
- "See recommendations" link (leads to product recommendations for that gap)
- Confidence label ("Strong suggestion" vs "Worth considering")

---

##### Feature 2A.3: Product Catalogue (Manual Curation)

**Decision: Manual curation for v1. Automated sourcing via affiliate feeds for v2.**

Manually curate a "Capsule Collection" of 250 high-quality items across three categories. Each item is tagged in Supabase with exact parameters that the scoring engine requires. Manual curation ensures recommendation quality at launch; API feeds (Awin product data) are a pluggable enhancement for later scale.

**Catalogue composition:**

_Rugs (100 items):_

- 4 size brackets (120x170, 160x230, 200x290, 240x340 cm)
- 6 colour families (matching the palette family system)
- 3 price tiers (affordable: under £150, mid-range: £150-400, investment: £400+)
- 4 texture types (flat-weave, low-pile, chunky/shag, natural fibre)
- Source from: John Lewis (8% commission via Awin), Dunelm (5-8%), Wayfair, The Rug Company (higher-end)

_Lighting (80 items):_

- Split across ambient (ceiling/pendant), task (desk/reading/floor), accent (table lamps, LED strips, plug-in wall lights)
- 3 price tiers per sub-category
- Material/finish variety (brass, matte black, chrome, ceramic, wood)
- Renter-safe flags on all items (plug-in vs. hardwired)
- Source from: John Lewis, Habitat, Dunelm, Pooky

_Soft furnishings (70 items):_

- Cushions, throws, curtains
- 6 colour families
- 3 price tiers
- Texture variety (velvet, linen, chunky knit, woven)

**Product data model:**

```
id: String
category: String (rug, pendant-light, floor-lamp, table-lamp, cushion, throw, curtain)
subcategory: String? (ambient, task, accent for lighting)
name: String
brand: String
retailer: String
priceGBP: Number
affiliateUrl: String
imageUrl: String
primaryColour: Lab colour
secondaryColour: Lab colour?
patternColours: [Lab colour]? (for products with 3+ significant colours, e.g., patterned rugs, printed cushions)
undertone: warm | cool | neutral
materials: [String] (wood-oak, wood-walnut, wood-ash, wood-teak, wood-birch, wood-pine, wood-reclaimed, metal-brass, metal-antique-brass, metal-brushed-gold, metal-chrome, metal-brushed-nickel, metal-matte-black, metal-copper, metal-bronze, fabric-linen, fabric-velvet, fabric-bouclé, fabric-cotton, fabric-silk, fabric-wool, fabric-jute, leather, glass, ceramic, rattan, stone)
woodTone: String? (light-oak, honey-oak, walnut, dark-stain, white-painted, reclaimed, teak, ash, birch, pine)
metalFinish: String? (antique-brass, brushed-gold, polished-brass, rose-gold, chrome, brushed-nickel, matte-black, copper, dark-bronze, aged-brass)
style: [String] (modern, traditional, scandi, mid-century, industrial, bohemian, minimalist)
textureFeel: smooth | low-texture | high-texture | chunky
dimensions: { width: Number, height: Number, depth: Number? } (cm)
sizeBracket: String? (for rugs: "120x170", "160x230", etc.)
visualWeight: light | medium | heavy
finishSheen: matte | low-sheen | polished
renterSafe: Boolean
removable: Boolean
available: Boolean
lastVerified: Date
```

**Product Colour and Material Extraction Workflow (for manual curation):**

Each of the 250 curated items must have accurate colour, material, and finish data for the scoring engine to work. This is the curation pipeline:

1. **Source the product.** Identify item from retailer, confirm affiliate availability, save product URL and high-resolution image.

2. **Extract primary colour.** Open the product image. Sample the dominant colour region (the largest area of a single colour). Use a colour picker tool (e.g., macOS Digital Color Meter, or a simple Flutter utility built for this purpose) to capture the RGB value. Convert to CIE L*a*b\* using the same sRGB/D65 conversion used in the paint database pipeline. Record as `primaryColour`.

3. **Extract secondary colour (if applicable).** If the product has a clearly distinct second colour covering at least 15% of the visible surface, sample and convert it the same way. Record as `secondaryColour`.

4. **Extract pattern colours (if applicable).** For products with 3+ significant colours (patterned rugs, printed cushions, multi-colour ceramics), sample each additional colour and record in `patternColours`. Cap at 5 colours; beyond that, the scoring gains diminishing returns.

5. **Classify undertone.** Using the extracted primary Lab colour, run the same undertone classification algorithm used for paints (warm if a* > 0 and b* > 0, cool if a* < 0 or b* < -5, neutral otherwise; thresholds configurable). Manually verify; the auto-classification is a starting point, not gospel.

6. **Tag materials, wood tone, and metal finish.** From the product description and image, select all applicable values from the data model enums. If the product has visible wood, tag the `woodTone`. If the product has visible metal, tag the `metalFinish`. These fields are what the Wood Tone Harmony Check and Metal Finish Consistency Check score against.

7. **Tag texture, visual weight, and sheen.** Assess from the image: is this smooth or chunky? Light or heavy? Matte or polished?

8. **Tag style.** Select 1-3 style tags from the enum based on the product's design language.

9. **Verify archetype compatibility.** Check that the product's colour, material, and finish attributes result in a match score > 0 for at least 3 of the 14 archetypes. If a product only matches one archetype, it is too niche for the initial catalogue unless it fills a specific gap.

10. **Record and review.** Enter all data into the Supabase `products` table. A second person (or a second pass by the same person on a different day) verifies the colour extraction and material tags. Inaccurate colour data produces bad recommendations, which destroys trust.

**Automation target for Phase 2B:** When transitioning to Awin product feed sourcing, steps 2-5 can be partially automated: extract dominant colours from product images using k-means clustering, auto-classify undertone, and auto-tag materials from product description keywords. Human review remains mandatory for quality assurance, but the pipeline reduces per-item curation time from ~10 minutes to ~3 minutes.

**Ensure coverage:** Each of the 14 Colour DNA archetypes must have at least 10 strong product matches across categories. Run the scoring engine against the full catalogue for each archetype and verify. If any archetype has fewer than 10 matches, curate additional items specifically for that archetype before launch.

---

##### Feature 2A.4: "Complete the Room" Product Recommendations (Pro)

The core commercial feature. Based on the room's gaps, 70/20/10 plan, light direction, mood, locked furniture, and budget bracket, the app generates curated product recommendations organised by what the room still needs.

**Architecture:**

1. **Gap Analysis Layer** (Feature 2A.2): Identifies what is missing using the Design Rules Engine.

2. **Hard Filters (Pass/Fail):** Remove anything that is wrong outright before scoring. Over budget, wrong dimensions for room size, not renter-safe (if Renter Mode), clashes with locked item undertones, unavailable, introduces a third metal finish when two are already present, wood tone undertone directly clashes with existing locked wood items (warm vs cool).

3. **Soft Scoring (Weighted):** Score remaining candidates across the dimensions defined in the Scoring Dimensions table. Weights stored in JSON configuration.

4. **Diversity Logic:** Do not simply show the top 4 highest-scoring beige rugs. For each gap, force the recommendation set to include variety:
   - Best overall fit ("Recommended")
   - Best budget option ("Best value")
   - Slightly bolder option ("Something different")
   - Safest option ("Safe choice")

5. **Explanation Layer:** Generate the "Why this works" copy for each recommendation.

**Explanation payload per recommendation:**

```
primaryReason: String ("Grounds your seating area with the right scale")
secondaryReason: String ("Warm gold undertone harmonises with south-facing evening light")
finishNote: String? ("The antique brass base complements your Cocooner palette's preference for warm metals and pairs with your existing brass door handles")
materialNote: String? ("The chunky jute weave adds the texture contrast your room needs; all your current surfaces are smooth")
supportingInputs: [String] ("room direction: south", "locked sofa: warm brown leather", "palette: Cocooner", "existing metals: antique brass", "texture profile: all smooth")
tradeoffNote: String? ("Slightly above your budget bracket but exceptional colour match")
confidenceLabel: "Strong match" | "Good alternative" | "Worth considering"
```

The explanation references the specific room context, not generic rules. Example: "Works because it introduces your 10% rust accent, softens the leather sofa with texture, and suits the room's warm evening light. The antique brass frame matches your existing hardware and fits your Cocooner identity. Based on your room direction, locked sofa, texture profile, and Cocooner palette."

**Room Detail integration:**
Below the Room Checklist and Room Preview on the Room Detail screen:

1. "What this room still needs" (gap analysis)
2. "Recommended next buy" (single top recommendation for the highest-priority gap)
3. "Alternatives" (3 more options for the same gap)
4. "Other gaps" (expandable sections for lower-priority gaps)

**Recommendation actions:**
Each recommendation card supports:

- "Buy" button with affiliate link
- "Save" to a room wishlist
- "Compare" (side-by-side with another saved item)
- "Not for me" with reason capture (style, price, colour, scale, wrong material)

"Not for me" feedback is high-quality data. Capture whether the rejection was style, price, colour, scale, or renter constraints. This data informs scoring weight adjustments over time even without ML; aggregate engagement patterns (which reasons appear most) suggest weight recalibration.

**Commission disclosure:**
A compact disclosure directly above the recommendation list: "We may earn a commission if you buy through these links. This never affects which products we recommend." Short, visible, plain. Repeated near the buy action on each card.

Commission rates must never influence sort order. This is architecturally enforced: the scoring engine has no access to commission data. Commission is a property of the affiliate link layer, not the recommendation layer.

**Renter Mode filtering:**
For renters, the entire recommendation set is filtered to renter-safe items. The gap analysis also changes: "define the floor" (rug), "define the soft layers" (curtains, throws), "define the lighting mood" (plug-in lamps), "define one vertical focal point without drilling" (leaning art, mirror). This is a native renter story, not "same product engine, fewer options."

**Mobile UX for recommendations:**

- Visible applied-filter chips above results (budget, renter-safe, room context)
- Persistent room-context badge: "For your north-facing kitchen"
- One-tap sort by "best match", "lowest price", "boldest option"
- Remembered filters per room session
- No modal filter sheets that require repeated trips in and out

**Edge cases:**

- Zero compatible products: "We don't have a perfect match in your budget range yet. Here are close alternatives, or try adjusting your budget bracket."
- Low confidence: "We need more information about this room to give you great recommendations. Add your existing furniture to improve results."
- Conflicting constraints: "Your locked sofa and chosen hero colour have different undertones. Here are products that bridge the gap."

---

##### Feature 2A.5: Instrumentation for Recommendations

Track everything from day one:

- `recommendation_viewed` (gap type, product ID, position in list, room ID)
- `recommendation_tapped` (product ID, action: buy/save/compare/dismiss)
- `recommendation_dismissed` (product ID, reason: style/price/colour/scale/material/other)
- `recommendation_bought` (product ID, via affiliate callback if available)
- `gap_identified` (gap type, severity, room ID)
- `filter_applied` (filter type, value)
- `filter_cleared`

---

#### Phase 2B: Recommendation Expansion

---

##### Feature 2B.1: Expanded Product Categories

Add curtains, artwork, mirrors, cushion sets, and throws to the curated catalogue. Target: 150 additional items. Each new category uses the same scoring engine with category-specific weight adjustments stored in JSON configuration.

**Renter-specific categories (added alongside):**

- Removable wallpaper and wall decals
- Peel-and-stick tiles (bathroom/kitchen backsplash)
- Plug-in pendant lights and sconces
- Leaning art and mirrors (no drilling)
- Command-strip-safe solutions
- Large rugs (to cover landlord carpets, heavy-weighted default for renters)

---

##### Feature 2B.2: Shopping List Aggregation

From any room's recommendations, users add items to a "Shopping List." The list aggregates across rooms, groups by retailer, shows total estimated cost, and provides direct "Buy" links per item.

The Shopping List is accessible from the Home screen and from each room's detail view.

---

##### Feature 2B.3: Paint & Finish Recommender with Shopping List

Finish recommendations based on Sowerby's guide (matt for living rooms/bedrooms, eggshell for woodwork, satin for bathrooms/kitchens).

**Paint quantity calculator:**
Standard formula: (perimeter x height - door/window area) / coverage rate per litre. Room dimensions captured in Phase 1E provide the inputs. Property type defaults used as fallback when dimensions not entered.

Output: "Add 2.5L of Savage Ground Matt Emulsion to basket" with deep link to retailer.

Shopping list aggregates all paint across rooms with brand, colour, code, finish, quantity, approximate price, and "Buy This Paint" deep links.

---

##### Feature 2B.4: Automated Product Sourcing (Scale)

Transition from manual curation to automated sourcing via Awin product feeds. The scoring engine filters and ranks feed items using the same dimensions as manually curated items. Manual curation continues for "hero" recommendations; feed items fill the catalogue breadth.

**Data pipeline:** Awin feed > parse product data > auto-classify colour (extract from image, map to Lab) > auto-classify undertone > auto-tag materials and style (from product description, using keyword matching or LLM classification) > human review queue for items scoring above a quality threshold > publish to catalogue.

---

##### Feature 2B.5: Seasonal Refresh Suggestions

Quarterly prompts suggesting small changes within the existing palette:

- "Spring refresh: swap your accent cushions to dusty rose. It brings warmth to your east-facing bedroom's morning light."
- "Autumn: add a chunky knit throw in your deepAnchor colour to cosy up the living room."

Each suggestion links to shoppable products. Drives repeat engagement and affiliate revenue.

**Content strategy:** Algorithmically generated from palette + season + available products, with human-written seasonal narrative templates. Template variables filled from user data + season logic. Example: "As the clocks go back, your [room name]'s [direction]-facing light shifts [warmer/cooler]. A [product type] in your [thread colour] brings [seasonal benefit]."

---

#### Phase 2C: Recommendation Intelligence

---

##### Feature 2C.1: Recommendation Feedback Loop

Aggregate user feedback (save, dismiss with reason, buy) to refine scoring weights. This does not require ML; adjust weights based on aggregate engagement patterns.

**Process:** Monthly review of aggregate data. If "too expensive" is the top dismiss reason for rugs, increase the budget fit weight for that category. If "wrong style" dominates lighting dismissals, increase style fit weight for lighting. Weight changes stored in versioned JSON configuration.

---

##### Feature 2C.2: Whole-Home Bundles

Cross-room recommendations that strengthen the Red Thread. "Your living room and hallway share a warm neutral thread. Here's a rug and a lamp that connect the two spaces."

---

### Phase 3: Visual Confidence & Social

**Theme:** Show people how choices will look before they commit, and add collaborative features.

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

#### Feature 3.3: Partner Mode

Partner invited via link or email. Partner completes their own Colour DNA (free, via web quiz if no app installed). Shared Palette shows overlap and divergence.

**v1 (Phase 3 launch):** Partner takes Colour DNA quiz (web-only, no install required). Results shared back to primary user. App shows overlap/divergence on a Venn diagram.

**v2:** Partner reacts to primary user's choices (love, like, unsure, not for me). Budget alignment indicator on product recommendations.

**v3:** Full collaborative editing with shared room plans.

---

### Phase 4: Full Home Companion

**Theme:** Extend beyond colour and furnishings into complete interior design.

- **Lighting Planner:** Three-layer lighting recommendations (ambient/task/accent) per room.
- **Room Audit Checklist:** Watson-Smyth's design rules codified with visual scoring.
- **Renovation Sequencing:** Lightweight guide adapted to property type.
- **Before & After Sharing:** Photo journey sharing for organic growth ("Design Diary").

---

## Screen Architecture (Updated)

**Tab 1: Home ("Your Design Plan")**
Mini palette strip, next recommended action card, room progress cards with completion scores (hero colour fills progress), whole-home coherence summary (Red Thread compact view), curated "Recommended for you" section (Phase 2, pulling from Colour DNA and rooms).

**Tab 2: Rooms**
Room list with hero colours and completion indicators visible. Room profiles (direction, mood, dimensions, 70/20/10, Room Preview mockup, furniture lock, "Why This Room Works", room checklist, "What this room still needs" gaps, "Complete the Room" product recs). Red Thread accessible from top of list (premium, blurred preview for free).

**Tab 3: Explore** (4-tab layout until Capture ships)
Three sections: Tools (Colour Wheel, White Finder, Paint Library with contextual notes), Learn (personalised educational content), Your Palette (Red Thread, Colour DNA summary).

**Tab 4: Profile & Settings**
Colour DNA summary with design identity guidance, account, preferences, subscription status, notification settings, Colour Blind Mode toggle, Renter/Owner toggle, sample order history.

When Colour Capture ships (Phase 1D), restructure to 5 tabs: Home, Rooms, Capture, Explore, Profile.

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

**Key principle:** Recommendation first, commission second. Commerce should feel like the result of good advice, not the reason for it. Commission rates must never influence recommendation sort order; this is architecturally enforced.

**Secondary: Subscriptions (Plus, Pro, Project Pass)**
The design tools tier (Plus) and the recommendation tier (Pro) create a clear value ladder. Project Pass captures high-intent users who prefer one-time purchase. Free trial drives initial conversion.

**Tertiary: AI credit top-ups**
Visualiser credits for Phase 3.

**Future: Sponsored brand collections**
Branded collections that feel editorial: "Curated by Farrow & Ball for North-Facing Rooms." Maximum one sponsored collection visible at any time. Charged as flat fee to brand.

### Biggest Purchases to Optimise Around

**For owners:** Sofas (£1,000-3,000), beds/mattresses (£500-2,000), dining tables (£400-1,500), large rugs (£200-800), curtains/blinds (£200-600), lighting (£100-500), paint (£150-500), accent furniture (£200-1,000).

**For renters:** Rugs (define the floor), curtains (frame windows), lighting (floor/table lamps), bedding, throws/cushions, art, mirrors, side tables, shelving/storage, peel-and-stick decor.

First-time buyers spend over £15,500 furnishing a new home. The UK home decor market is approximately £25.7 billion (2026). Furniture accounts for over 55% of spending.

### Affiliate Programmes

| Brand         | Network               | Commission                 | Cookie  | Notes                            |
| ------------- | --------------------- | -------------------------- | ------- | -------------------------------- |
| Farrow & Ball | Awin (UK: ID 20199)   | Up to 5% content, 3% base  | 30 days | Apply via Awin                   |
| Dulux         | Awin (ID 12009)       | 5% base                    | 30 days | UK-only, same Awin account       |
| Little Greene | Sovrn Commerce        | Varies (auto-monetisation) | Varies  | Product mentions auto-link       |
| Lick          | CJ Affiliate / direct | ~1%                        | Unknown | Low rate. Also sold via B&Q      |
| B&Q           | Impact                | 2% delivery + C&C          | Unknown | Sells Lick, Dulux, Crown         |
| Freshlick     | Awin (ID 101923)      | 2% opening                 | 30 days | Multi-brand fallback             |
| COAT          | Direct negotiation    | TBD                        | TBD     | Club COAT loyalty model          |
| John Lewis    | Awin                  | ~8%                        | 30 days | Rugs, lighting, soft furnishings |
| Dunelm        | Awin                  | 5-8%                       | 30 days | Rugs, lighting, curtains         |
| Wayfair       | Awin                  | Varies                     | 30 days | Large rug selection              |

**Implementation:** Build deep-link fallback ladder and "Buy This Paint" flow with plain product links. Affiliate tracking is a pluggable config layer (link resolver + attribution params per brand). When Awin approves, prepend tracking URL to existing database URLs.

---

## User Personas (Updated)

**Persona 1: "The Overwhelmed First-Timer" (Primary)**
Mia, 31. Just bought a 1930s semi in Essex with partner Tom. 400+ Pinterest pins, no plan. Loves green but terrified of mistakes. Bringing a brown leather sofa and IKEA pieces from rented flat. Never heard of undertones or 70/20/10.
_Needs:_ Confidence, education, framework, "what to buy next" for each room, furniture lock to work around what she's keeping. Likely Plus subscriber (via trial) converting to Pro when product recs launch.

**Persona 2: "The Taste-Confident Upgrader" (Secondary)**
Raj, 37. Moving from rented flat to Victorian terrace in south London. Strong style opinions (jewel tones, mid-century). Great individual purchases that don't cohere. Frustrated by rooms that look good in photos but feel "off."
_Needs:_ Red Thread, light direction, curated product recommendations that create coherence. Likely Pro subscriber or Project Pass buyer.

**Persona 3: "The Long-Term Renter" (Secondary)**
Priya, 28. Renting a 2-bed flat in Manchester. Cannot paint but wants personal space. Spends on cushions, throws, and prints that never quite come together. Frustrated that most design apps assume she can renovate.
_Needs:_ Renter Mode as a first-class experience. 70/20/10 restructured around furniture and textiles. Recommendations filtered to removable/renter-safe items. "Style Without Painting" guidance. Likely Plus subscriber.

**Persona 4: "The Reluctant Partner" (Tertiary)**
Sam, 34. Partner of someone deep in decorating decisions. Does not care much about interiors but wants an opinion without studying colour theory. Defaults to "whatever you think" or vetoes without explanation.
_Needs:_ Partner Mode (Phase 3). May never install the app; interacts via web quiz.

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

**Moat:** Persistent whole-home data model (hard to retrofit). Red Thread requires whole-house context from day one. Brand-agnostic positioning (paint brands cannot replicate). Education-first approach builds trust that shopping apps cannot match. Curated paint colour database (5,000+ colours normalised to CIE Lab) has standalone value. Algorithmic Design Rules Engine creates defensible recommendation quality. "Why this works" explanations build compounding user trust.

---

## Design Principles (UX)

**1. The app should feel like a well-designed room, not a tech product.**
Warm whites, soft creams, muted earth tones as the base palette. A single warm accent (sage green) for primary interactive elements only (buttons, CTAs). A warm neutral (cream/gold tones) for secondary UI elements (tags, progress bars, badges). Blue alternative in Colour Blind Mode. Clean sans-serif body type with an editorial serif for headings. Full-bleed imagery. No neon gradients, no heavy shadows, no "startup" aesthetic.

**2. Progressive disclosure, always.**
Show summary views first. Reveal complexity gradually. Surface the 3 most relevant actions at any stage. Use bottom sheets and overlays, not new screens.

**3. Rooms are the centre, tools are secondary.**
Every screen should answer at least one of: What suits my room? What should I buy next? Why does this work? How does this connect to the rest of my home? What can I do within my constraints? If a feature does not clearly answer one of these, it is secondary.

**4. Every recommendation teaches.**
No recommendation appears without a "why this works" explanation that references the user's specific room context. The app is a trusted advisor, not a shopping catalogue. The explanation quality is the moat.

**5. Image-first layouts.**
Colour swatches, room photos, product images, and moodboards are the heroes. Text supports images.

**6. Celebrate progress.**
Small animations at milestones. Skeleton loading states. Spring physics for transitions. Room completion scores (filled with the room's hero colour) drive engagement.

**7. Card-based UI with generous breathing room and clear depth.**
Three elevation levels (flush, subtle shadow, elevated). Status indicators use icons as primary signal (checkmark, clock, empty circle) with colour supplementary. Generous padding. State changes must be obvious. Buttons must feel tappable (pill shapes with chevrons for navigation actions). Labels must be legible. Soft palette should not sacrifice clarity on key actions.

**8. Context-aware navigation.**
Adapts emphasis based on journey stage: discovery, planning, acting, maintaining. Tools show personalised context headers when accessed from a room.

**9. Accessible by default.**
Dynamic Type (iOS) and font scaling (Android) from day one. Never rely on colour alone. Every swatch shows its name. WCAG AA contrast ratios throughout (4.5:1 for normal text, 3:1 for large text and UI components). Colour Blind Mode as settings toggle. Badge legends and tooltips for abbreviated labels.

**10. Colour disclaimer always visible.**
"Colours on screens are approximations. Always test physical samples before committing." Present in onboarding, on swatch detail views, and in exports.

**11. Branded terms always have plain-English support.**
Every branded term has a persistent plain-English subtitle. Not just on first encounter; always visible.

---

## Error Handling and Edge Cases

Define graceful degradation for each scenario:

| Scenario                                              | Handling                                                                                                                                                                       |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| User's palette has 0 compatible products in catalogue | "We don't have a perfect match in your budget range yet. Here are close alternatives, or try adjusting your budget bracket." Show nearest matches with delta-E distances.      |
| Room has conflicting furniture lock constraints       | "Your locked sofa and chosen hero colour have different undertones. Here are products that bridge the gap." Show the conflict visually with undertone indicators.              |
| Recommendation engine has low confidence              | "We need more information about this room to give you great recommendations. Add your existing furniture to improve results." Show a clear path to improving data quality.     |
| Camera colour extraction in poor lighting             | "For best results, capture in natural daylight." Show the captured colour with a "Nudge warmer/cooler" slider and manual correction option.                                    |
| Empty room (no furniture locked)                      | Handle as default case, not edge case. Recommend foundational items (rug, main light, key furniture) rather than accessories.                                                  |
| Affiliate link broken or product unavailable          | Fallback ladder: alternative retailer link > brand homepage with product code > "Copy product details to clipboard." Flag unavailable products in background checks (monthly). |
| User creates rooms but never completes setup          | Next-action card on Home screen progressively nudges: gentle encouragement, then more specific ("Your living room just needs a hero colour to unlock recommendations").        |
| Red Thread has no viable thread colours               | Suggest the 2-3 colours that appear most frequently across rooms, with explanation of why they connect.                                                                        |

---

## Resolved Decisions

### 1. Paint Colour Database

**Decision: Build our own local database. No paid API at launch.**

**Phase 1A shipped with:** ~500-1,500 colours across initial brands. Paint names display throughout the app. Delta-E matching and undertone classification operational.

**Internal data model:** CIE L*a*b\* as primary colour space (sRGB/D65). Schema: brand, name, code, Lab, RGB, hex, LRV, undertone, palette family, collection, approximate price per litre (indicative, with "last checked" date).

**The data pipeline is a first-class deliverable.** Versioned, repeatable process (script + versioned JSON). Ingest > convert to Lab > auto-classify undertone > assign palette family > output versioned JSON bundled at build time.

### 2. AI Room Visualiser

**Decision: Decor8 AI at ~£0.16/image ($0.20), Phase 3 only. Credit-based pricing.**

### 3. Light Simulation

**Decision: Kelvin lookup + RGB blend overlay at 10-20% opacity. Local computation. Zero cost.**

### 4. Product Catalogue Scope

**Decision: Phase 2A launches with manually curated 250 items across rugs, lighting, and soft furnishings. Paint recommendations use existing Paint Library. Automated sourcing via Awin feeds in Phase 2B.**

### 5. Offline Capability

**Decision: Offline-first. Local database is source of truth.**

Offline: Palette, rooms, wheel, moodboards (viewing), paint library, Red Thread, light simulation, Colour Capture, Room Preview mockup, room gaps analysis.
Online: AI Visualiser, product recommendations (requires catalogue sync), web image saving, share/export, Partner Mode sync, sample ordering, web quiz result retrieval, "Complete the Room" product data, affiliate link resolution.

### 6. Colour Blind Accessibility

**Decision: First-class from day one.** Named swatches, icon-first status, WCAG AA, shape-based indicators, Dynamic Type. Colour Blind Mode toggle adds pattern overlays, W/C badges, blue accent alternative.

### 7. Tech Stack

**Decision: Flutter.** Impeller rendering for 60fps animations. CustomPainter for colour wheel, light overlays, and Red Thread flow diagram. Decor8 AI Dart SDK. Offline-first via SQLite/Hive. PowerSync for Supabase sync.

### 8. Backend

**Decision: Supabase + PowerSync.** Auth, real-time sync (Partner Mode), row-level security, PostgreSQL. PowerSync for offline-first sync layer.

### 9. App Store Colour Accuracy

**Decision: No specific policy exists. Ship the disclaimer.**

### 10. Affiliate Programmes

**Decision: Apply to Awin. Launch with plain links. Add tracking when approved.**

### 11. Web Quiz Infrastructure

**Decision: Astro + Supabase Edge Function + shared JSON config.**

### 12. Web-to-App Handover

**Decision: Build lightweight handoff. No paid deep link provider at MVP.** Campaign URL parameters (primary), email save (secondary), cookie (tertiary).

### 13. Free Tier Room Limit

**Decision: 2 rooms free, unlimited with Plus.** Two rooms provide enough to experience the product (and create data for upgrade prompts). The third room creation triggers an upgrade prompt. This balances engagement (enough to invest effort) with conversion urgency.

### 14. Free Trial

**Decision: 14-day free trial of Palette Plus, triggered after second room creation.** Longer trials (17+ days) convert significantly better than short trials. The user has invested effort at this point, creating switching cost.

### 15. Analytics Tool

**Decision: PostHog.** Self-hostable, privacy-respecting, generous free tier. Feature flags included for A/B testing.

---

## Implementation Status

_Updated March 2026._

### Phase 1A: Complete (native app)

| Feature                         | Status | Notes                                                                             |
| ------------------------------- | ------ | --------------------------------------------------------------------------------- |
| 1.1 Colour DNA Onboarding (app) | Done   | 14 archetypes, system palette roles, DNA drift detection. Note: archetype names updated from original spec — see archetype definitions in code for current names. |
| 1.2 My Palette                  | Done   | Palette Story, feedback engine, paint name display, buy-this-paint links, cross-brand comparison |
| 1.4 Room Profiles               | Done   | 70/20/10, furniture lock (basic), renter mode (basic), light sim, room psychology. Note: room dimensions (small/medium/large picker) NOT yet implemented. |
| 1.5 Colour Wheel & White Finder | Done   | Zoomable wheel, undertone toggle, DNA overlay, context-aware whites, Neutral Finder for renters |
| 1.6 The Red Thread              | Done   | Templates, adjacency list, coherence check, PDF export, floor plan painter        |

### Phase 1B: Complete

| Feature                            | Status | Notes                                                            |
| ---------------------------------- | ------ | ---------------------------------------------------------------- |
| 1B.1 Home Screen Redesign          | Done   | Next-action engine, progress cards, room quick-access            |
| 1B.2 Room Detail Enhancement       | Done   | Room Story engine, decision checklist, config-driven labels      |
| 1B.3 Explore Tab Reorganisation    | Done   | Card-based layout, learn content, category navigation            |
| 1B.4 Paint Library Personalisation | Done   | DNA-matched paints, brand filtering, "Your Palette Match" badges |
| 1B.5 Colour DNA Expansion          | Done   | Archetype engine with 14 personalities, practical guidance       |
| 1B.6 Paywall Restructure           | Done   | Three-tier structure, Project Pass, feature comparison           |
| 1B.7 Renter Mode Enhancement       | Done   | RoomModeConfig, 5 renter constraints, Neutral Finder             |

### Phase 1C: Not started (PARALLEL)

| Feature                  | Status      | Notes                              |
| ------------------------ | ----------- | ---------------------------------- |
| 1C.1 Web Colour DNA Quiz | Not started | Separate Astro project. Ship ASAP. |
| 1C.2 Web-to-App Handover | Not started | Requires Supabase Edge Functions   |

### Phase 1D: Not started (DEFERRED)

| Feature                            | Status           | Notes                                           |
| ---------------------------------- | ---------------- | ----------------------------------------------- |
| 1D.1 Colour Capture                | Placeholder only | Route exists at `/capture`, shows "Coming Soon" |
| 1D.2 Digital Moodboards            | Not started      |                                                 |
| 1D.3 Sample Ordering               | Not started      |                                                 |
| 1D.4 Re-engagement & Notifications | Not started      |                                                 |

### Phase 1E: In progress (NEXT PRIORITY)

| Feature                               | Status      | Priority | Notes                                                              |
| ------------------------------------- | ----------- | -------- | ------------------------------------------------------------------ |
| 1E.1 Analytics Instrumentation        | Done        | P0       | AnalyticsService + events + screen tracking                        |
| 1E.2 A/B Testing Infrastructure       | Not started | P1       | PostHog feature flags                                              |
| 1E.3 Blurred Premium Previews         | Done        | P0       | PremiumGate widget with blur + CTA. Used on Light Dir, 70/20/10, Red Thread |
| 1E.4 Paywall Visual Redesign          | Done        | P0       | Visual hero with user room data + blur animation, warm accent CTA, outcome-focused tiers, free trial CTA |
| 1E.5 Visual Polish Pass               | Done        | P1       | Card depth system, WCAG contrast fixes, hero colour progress bars implemented |
| 1E.6 Branded Term Consistency         | Done        | P1       | Systematic pass — plain-English subtitles under branded terms      |
| 1E.7 Capture Tab Resolution           | Done        | P1       | Camera-to-paint matching MVP shipped                               |
| 1E.8 Red Thread Flow Visualisation    | Done        | P0       | Floor plan painter exists but NOT the node-and-edge flow diagram described in spec |
| 1E.9 Room Preview Colour-Block Mockup | Done        | P1       | Zero-cost visualisation                                            |
| 1E.10 Applied State System            | Not started | P2       | Prerequisite for Phase 2 density                                   |

### Phase 2A: Not started

| Feature                                    | Status      | Notes                            |
| ------------------------------------------ | ----------- | -------------------------------- |
| 2A.0 Paint Recommendations (existing data) | Done        | Room-context paint recs in Room Detail — hero match, direction undertone, budget filter |
| 2A.1 Expanded Furniture Lock               | Not started | Photo-first, progressive capture |
| 2A.2 Room Gap Engine                       | Not started | Core diagnostic concept          |
| 2A.3 Product Catalogue (manual curation)   | Not started | 250 items across 3 categories    |
| 2A.4 "Complete the Room" Product Recs      | Not started | Core commercial feature          |
| 2A.5 Recommendation Instrumentation        | Not started | Track everything from day one    |

### Phase 2B: Not started

| Feature                          | Status      | Notes                                |
| -------------------------------- | ----------- | ------------------------------------ |
| 2B.1 Expanded Product Categories | Not started | Curtains, artwork, mirrors, cushions |
| 2B.2 Shopping List Aggregation   | Not started |                                      |
| 2B.3 Paint & Finish Recommender  | Not started | With quantity calculator             |
| 2B.4 Automated Product Sourcing  | Not started | Awin feed integration                |
| 2B.5 Seasonal Refresh            | Not started | Algorithmic + template               |

### Phase 2C: Not started

| Feature                           | Status      | Notes                                    |
| --------------------------------- | ----------- | ---------------------------------------- |
| 2C.1 Recommendation Feedback Loop | Not started | Weight recalibration from aggregate data |
| 2C.2 Whole-Home Bundles           | Not started | Cross-room recommendations               |

### Phase 3: Not started

| Feature                 | Status      | Notes                                                  |
| ----------------------- | ----------- | ------------------------------------------------------ |
| 3.1 AI Room Visualiser  | Not started | Decor8 AI, credit system                               |
| 3.2 AI Design Assistant | Not started | Conversational interface                               |
| 3.3 Partner Mode        | Not started | v1: web quiz overlap, v2: reactions, v3: collaborative |

### Features added beyond original spec

These emerged during Phase 1A and 1B implementation and strengthen the core product:

- **Colour Archetypes** (14 personality-driven identities with system palette roles)
- **DNA Drift Detection** (tracks preference evolution, prompts re-engagement)
- **Palette Feedback Engine** (contextual natural-language impact descriptions)
- **Palette Story/Review Sheet** (magazine-style visual analysis with colour swatches)
- **Paint Name Display** (hex codes replaced with real paint names throughout)
- **Room Colour Psychology** (mood-to-colour recommendation mapping)
- **Locked Furniture Conflict Detection** (warns when constraints contradict)
- **QA Mode** (debug-only developer tools at `/dev` route with renter constraint toggles. Must be hidden in production builds.)
- **Room Story Engine** (narrative room descriptions combining mood, light, and colour choices)
- **Next Action Logic** (smart home screen CTAs that adapt to user progress and completion state)
- **RoomModeConfig Strategy Pattern** (single config object replaces scattered if/else renter branches)
- **Renter Constraint System** (5 home-level constraints: paint, drill, flooring, temporary, reversible)
- **Neutral Finder** (White Finder variant for can't-paint renters, textile-focused neutrals)
- **Smart Paint Colour Picker** (reusable context-aware paint selection widget with room-aware suggestions)
- **Colour Plan Harmony Analysis** (analyses harmony between hero/beta/surprise colours, produces verdicts)
- **Era Affinities** (property era influences archetype scoring during onboarding)
- **DNA Anchors** (structured palette anchors for suggestion generation)
- **Colour Suggestions Engine** (context-aware suggestion generation with PickerContext and PickerRole)

---

## Success Metrics (Updated)

### Phase 1A + 1B + 1E (Foundation + Polish):

- Quiz completion rate: 70%+
- Quiz share rate: 15%+
- Quiz drop-off: track per stage, optimise weakest stage
- Rooms per user: 2+ (free), 3+ (paid)
- Room completion score: average 4+ of 7 steps per room
- Home screen "Next action" tap-through rate: 30%+
- Blurred preview to upgrade tap rate: 10%+
- Free-to-Plus conversion: 3%+ (initial target), optimise toward 5% over 6 months
- Trial start rate: 20%+ of users who create second room
- Trial-to-paid conversion: 40%+
- Free-to-Pro conversion: 1.5%+
- Combined paid conversion: 5%+ (initial), 7%+ (6-month target)
- Project Pass as % of paid: 15%+
- "Buy This Paint" CTR (all users): 2%+ (free), 4%+ (paid)
- W4 retention: 25%+
- App Store rating: 4.5+

### Phase 1C (Web Funnel):

- Web quiz completion rate: 60%+
- Web quiz to app download: 25%+
- Web quiz share rate: 20%+

### Phase 2 (Recommendation Engine):

- "Complete the Room" engagement: 60%+ of Pro users interact
- Product recommendation CTR: 8%+
- Recommendation dismiss rate: track and segment by reason
- Affiliate conversion: 2%+
- "Buy This Paint" CTR: 5%+ (increase from Phase 1)
- Sample order conversion: 15% of users with 3+ rooms
- Days from first room to first purchase: target under 14 days
- Revenue target: 3%+ CTR on product recommendations for Pro users, 2%+ affiliate conversion, within 90 days of Phase 2A launch

### Phase 3:

- Visualiser usage: 4+ per month per credit holder
- Credit top-up rate: 10% of visualiser users
- Partner Mode adoption: 20% of Pro users

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
- Handle errors with user-friendly messages (see Error Handling section)
- Plain language only in UI text
- Test colour displays on light and dark backgrounds
- Validate colour calculations produce visually correct results
- Support Dynamic Type (iOS) and font scaling (Android)
- Include colour disclaimer on paint colour screens
- Pair colour with icon/label/pattern (never colour alone)
- Include "Why this works" explanation with every recommendation, referencing specific room context
- Apply Renter Mode constraints to all recommendation logic
- Use British English spellings throughout
- Include branded term plain-English subtitle wherever the branded term appears
- Track analytics events for all user-facing interactions (see event taxonomy)
- Ensure WCAG AA contrast ratios on all interactive elements
- Store scoring weights and feature flags in JSON configuration, not hardcoded
- Ensure commission rates are architecturally separated from recommendation scoring

**Ask first:**

- Before adding any new dependency
- Before modifying data model or schema
- Before changing navigation or adding screens
- Before integrating any external API
- Before architectural decisions affecting multiple features
- Before implementing notification/push logic
- Before adding a new product category to recommendations
- Before changing the Design Rules Engine scoring weights
- Before changing the paywall structure or pricing
- Before modifying the free tier room limit or trial duration

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
- Never let commission rates influence recommendation sort order
- Never expose QA Mode or debug surfaces in production builds
- Never ship a feature without corresponding analytics events

---

## Remaining Open Questions

### 1. Paint data: brand responses

**Action:** Email Lick, COAT, and e-paint.co.uk. Sign up for Encycolorpedia Pro. **Deadline:** Responses within 1-2 weeks. Manual curation in parallel. **Fallback:** Manual curation from websites (small ranges ~1 day each). **Resolved when:** 500+ colours across 2+ brands confirmed.

### 2. Decor8 AI: privacy and data processing

**Action:** Email privacy@decor8.ai before Phase 3 development. Negotiate DPA. **Deadline:** Before Phase 3 starts. **Fallback:** Alternative providers or prominent consent screen.

### 3. COAT Paints affiliate structure

**Action:** Clarify during colour data outreach. **Fallback:** Plain links without tracking.

### 4. Product recommendation catalogue sourcing

**Decision made:** Hybrid. Manual curation for Phase 2A launch (250 items), automated Awin feed sourcing for Phase 2B scale. See Feature 2A.3 for details.

### 5. Renter Mode algorithmic restructuring validation

**Action:** Validate through user testing whether the full algorithmic restructuring (shifting 70% Hero from walls to rug/sofa) resonates with renters. The restructuring is implemented; the question is whether it feels natural. **Deadline:** During Phase 1E. **Fallback:** Simpler constraint toggling with restructuring as opt-in.

### 6. Seasonal refresh content cadence

**Decision made:** Algorithmic generation from palette + season + available products, with human-written seasonal narrative templates. See Feature 2B.5.

### 7. Educational content production pipeline

**Action:** Determine format and production approach for the Learn section content. Options: (a) illustrated card-based walkthroughs (static, written by Jamie), (b) short video walkthroughs, (c) interactive tutorials. **Deadline:** Before Phase 1E ships (Learn content should be personalised by then). **Recommended:** Static illustrated cards for v1, personalised dynamically using room/palette data.

---

## Cost Summary

| Item                 | Phase 1                                | Phase 1E  | Phase 2                | Phase 3         |
| -------------------- | -------------------------------------- | --------- | ---------------------- | --------------- |
| Paint database       | Zero (or $29.99/yr Encycolorpedia Pro) | Zero      | Zero                   | Zero            |
| Product catalogue    | Zero                                   | Zero      | Zero (affiliate-based) | Zero            |
| AI Visualiser        | Zero                                   | Zero      | Zero                   | ~£0.16/vis      |
| Light simulation     | Zero                                   | Zero      | Zero                   | Zero            |
| Offline storage      | Zero                                   | Zero      | Zero                   | Zero            |
| Accessibility        | Zero                                   | Zero      | Zero                   | Zero            |
| Web quiz hosting     | Minimal (free tier)                    | Minimal   | Minimal                | Minimal         |
| Backend (Supabase)   | Free tier                              | Free tier | Free tier              | Scale as needed |
| Deep linking         | Zero (platform-native)                 | Zero      | Zero                   | Zero            |
| Analytics (PostHog)  | Zero                                   | Free tier | Free tier              | Scale as needed |
| **Total fixed cost** | **~Zero**                              | **~Zero** | **~Zero**              | **~Zero**       |

Variable cost from AI API only (Phase 3), offset by credit pricing.

---

_This is a living document. Update it as decisions are made, requirements change, or new insights emerge from building._

_Last updated: March 2026_
_Author: Jamie_
