# Project Spec: Palette

## Objective

Palette is a colour-first interior design companion that helps homeowners and renters design their homes with confidence. It solves the visualisation gap, decision paralysis, and knowledge deficit that cause people to default to safe, soulless colour choices they later regret, or make expensive mistakes because they don't understand how light, undertones, and colour relationships work in their specific spaces.

**Target users:** People in the UK (25-40) who care about making their home feel personal but lack the confidence, knowledge, or tools to translate taste into decisions. Primary: first-time homeowners. Secondary: long-term renters who want a personal space. Tertiary: partners dragged into decorating decisions.

**What success looks like:** A user goes from "I don't know where to start with colour" to confidently choosing a whole-house palette, purchasing paint and products, and feeling genuinely proud of how their home looks, without hiring a colour consultant.

---

## The Problem (Validated by Research)

Six interlocking problems consistently emerged across book research (Sowerby, Watson-Smyth), multi-model analysis, and competitive review:

**1. The Visualisation Gap.** Most people cannot imagine a finished room from a paint chip. They need to see it. This is the single biggest source of renovation anxiety, partner conflict, and costly mistakes. (Sowerby, Watson-Smyth, Houzz UK data: 20% of homeowners cite this as a top challenge.)

**2. Decision Paralysis.** After 647 Pinterest pins, most people are more confused than when they started. They cannot separate what they genuinely like from what has been beautifully styled for a photograph. There is a massive gap between "inspiration" (infinite, free) and "decision" (what people desperately need and will pay for). (Watson-Smyth)

**3. Light Direction Ignorance.** People do not understand that the direction a room faces fundamentally changes how every colour appears. A beautiful green in a south-facing showroom can look cold and dingy in a north-facing living room. This is expert knowledge that consumers simply do not have access to in a structured form. (Sowerby's single most practical insight)

**4. Undertone Blindness.** Every colour, including whites, has an undertone (blue, red, yellow, grey) that determines how it behaves in a space. Choosing the wrong white can undermine an entire colour scheme. People do not know this, and no consumer tool teaches it. (Sowerby dedicates an entire chapter to whites alone)

**5. The Trend Trap.** People default to fashionable colours (grey, white, whatever Instagram is pushing) out of anxiety about getting it wrong, rather than choosing colours they actually love. This leads to soulless homes and eventual dissatisfaction. (Both books identify this as the root cause of bad interiors)

**6. Room-by-Room Thinking.** People decorate one room at a time with no unifying thread. The result is a house that feels disjointed rather than cohesive. The "red thread" principle (a limited palette that creates subconscious harmony room-to-room) is professional knowledge that consumers never encounter. (Sowerby)

---

## Core Philosophy

Four principles that guide every feature decision:

**Emotion first, colour second.** The app never starts with a colour chart. It starts with who you are, what you love, and why. Your palette emerges from your memories, your wardrobe, your personality. This is the central thesis of both Sowerby and Watson-Smyth, and it is the primary differentiator from every existing tool.

**Teach the why, not just the what.** Existing paint apps show you swatches. Palette teaches you why certain combinations work, why light direction matters, why undertones change everything. Education embedded in the tool builds confidence and trust, and confident users buy more, share more, and churn less.

**The whole house, not just one room.** Every feature considers how choices flow from space to space. The "red thread" runs through the entire experience. This is the feature gap no competitor fills.

**Discover free, decide premium.** Free users can explore their taste and fall in love with the app. But the tools that move them from "I have ideas" to "I'm confident enough to spend money" are where the paywall sits. The upgrade moment is buying certainty, not buying features.

---

## Phased Feature Plan

The app ships in three phases. Each phase is a complete, usable product. Later phases absorb elements of the "Curate" concept (anti-Pinterest decision engine, curated product recommendations, partner collaboration).

---

### Phase 1: Colour Confidence (MVP)

**Theme:** Help people discover their personal palette, understand how to use it in their specific home, and reach the point where they are ready to act.

Phase 1 ships in two stages to get to validation faster:

**Phase 1A (ship first, validate):** Colour DNA Onboarding (1.1), My Palette (1.2), Room Profiles with light direction, 70/20/10, furniture lock, and renter mode (1.4), Interactive Colour Wheel and White Finder (1.5), The Red Thread with blurred preview (1.6). This is the core loop: discover, plan, see the whole house. It contains the primary conversion trigger (light direction gate) and the strongest premium preview (blurred Red Thread). Ship this first and validate whether people convert before building 1B.

**Phase 1B (ship second, based on learnings):** Colour Capture (1.3), Digital Moodboards (1.7), Sample Ordering (1.8), Re-engagement Notifications (1.9). These are retention and deepening features. They make the product stickier but do not drive the initial "aha" moment.

The web-based Colour DNA quiz (part of 1.1) can ship alongside or shortly after 1A as a separate engineering effort (web, not native).

---

#### Feature 1.1: Colour DNA Onboarding [Phase 1A]

The onboarding is the product's signature moment. It replaces the standard "pick a style" quiz with an emotionally-driven discovery process. This feature also exists as a standalone web experience (no app install required) to serve as the primary viral acquisition channel.

**User Stories:**

- As a new user, I want to discover my personal colour palette through a guided process so that I have a confident starting point for decorating my home.
- As a new user, I want the onboarding to feel personal and enjoyable (not like a form) so that I feel invested in the result.
- As a new user, I want to be able to skip onboarding and complete it later so that I am not blocked from exploring the app.
- As someone who received a shared Colour DNA card, I want to take the quiz on the web without installing the app so that I can see my own result immediately.

**How it works:**

The onboarding has three stages, designed to complete in under 3 minutes for users who engage thoughtfully, or under 90 seconds for users who tap quickly. A visible progress bar drives momentum throughout.

_Stage 1: Memory Prompts (Emotional Anchoring)_
Three to four prompts that mine the user's happiest colour associations. These are not "pick your favourite colour" questions. They are designed to surface genuine emotional connections:

- "Think of a place where you felt completely at peace. What colours do you remember?"
- "What colour is the item of clothing you reach for when you want to feel most like yourself?"
- "Close your eyes and picture your ideal Saturday morning. What colours surround you?"

Each prompt offers 6-8 colour-mood cards to choose from (not raw swatches, but atmospheric images paired with colour families). Users can tap multiple cards per prompt. The quality of the Colour DNA result depends on thoughtful input, so prompts should invite reflection rather than rush users through.

_Stage 2: Visual Preference (Style Calibration)_
Six to eight room photographs. Users swipe or tap to indicate which feel right to them. These images are carefully curated to represent Sowerby's seven palette families (pastels, brights, jewel tones, earth tones, darks, warm neutrals, cool neutrals) without labelling them. The app is reading preference signals, not asking users to self-categorise.

_Stage 3: Property Context_
Four quick selections:

- Property type (flat, terraced, semi-detached, detached, other)
- Property era (Victorian, Edwardian, 1930s-50s, post-war, modern, new build, not sure)
- Current stage (just bought, planning, mid-project, finishing touches, just curious)
- Tenure: Owner or Renter (this activates Renter Mode, see Feature 1.4)

**Output:** A "Colour DNA" result screen showing the user's primary palette family (and any secondary leanings), their personal palette of 8-12 colours, and a short explanation of why these colours resonate with them. This result is shareable as a beautiful card (designed for Instagram Stories and WhatsApp). Every shared card links back to the web-based quiz, not just a static image.

**Web Experience:**
The Colour DNA quiz is also available as a standalone web page (no app install required). The web version delivers a teaser result (palette family, top 3 colours, shareable card). The full detailed result (complete palette, paint matches, room recommendations) is gated behind app download. This turns every shared result into a zero-cost acquisition funnel.

**Web Quiz to App Handover:**
iOS Safari's Intelligent Tracking Prevention purges first-party cookies after 7 days of no site interaction. A user who takes the web quiz and downloads the app 10+ days later will have a blank cookie. Browser cookies alone will break the acquisition funnel.

The primary handover mechanism is **campaign URL parameters** (a lightweight approach that avoids paid deep link providers). When the user finishes the web quiz, the result is saved to Supabase with a unique `result_id`. The "Download App" button links to the App Store / Play Store with the `result_id` encoded in the campaign URL (iOS: `ct` parameter; Android: `referrer` parameter). When the user installs and opens the app, it checks for the campaign parameter and fetches their result from Supabase.

Secondary mechanism: **email save** (prominently offered on the web result screen, not buried). User enters email, result is stored server-side keyed to that email, app prompts "Enter the email you used for the web quiz" on first launch. This is the most reliable fallback.

Tertiary: browser cookie as a bonus for users who download quickly (within 7 days).

For Universal Links and App Links (so `palette.app/quiz/[result_id]` opens the app if already installed rather than going to the store), host `apple-app-site-association` and `assetlinks.json` on the domain. These are free platform features, no third-party provider needed.

This requires a **lightweight backend endpoint** even in Phase 1A (a single API that stores and retrieves quiz results by ID, built as a Supabase Edge Function). The web quiz is a parallel engineering effort that can ship alongside or shortly after 1A.

**Acceptance Criteria:**

- Onboarding completes in under 3 minutes for engaged users, under 90 seconds for quick tappers
- Skip option is available at every stage
- Colour DNA result is generated even with partial completion (minimum: one memory prompt answered)
- Result card is shareable via native share sheet
- Shared card links to web-based quiz (not a dead image)
- Web quiz is completable without app install; full result gated behind download
- Web quiz result is handed to app via campaign URL parameter (primary), email-based retrieval (secondary), or cookie (tertiary fallback)
- Email save is prominently offered on the web result screen (not buried or optional)
- User can retake the quiz at any time from settings
- No account required to complete onboarding; account gated behind saving results

---

#### Feature 1.2: My Palette [Phase 1A]

The user's personal colour palette, always accessible. Viewing is free; editing is premium.

**User Stories:**

- As a user, I want to see my personal colour palette in one place so that I have a reference point for every decision I make.
- As a user, I want to understand why certain colours work together so that I feel confident combining them.
- As a premium user, I want to edit my palette (add, remove, swap colours) so that it evolves as my taste develops.
- As a user, I want to see my palette mapped to real paint colours from brands I can actually buy so that I can move from inspiration to action.

**How it works:**

The palette screen shows the user's 8-12 colours arranged in a visually pleasing layout. Each colour is tappable to reveal:

- Its palette family (e.g., "Jewel Tones") and undertone (warm/cool)
- Why it works with the other colours in the palette (colour wheel relationship explained simply)
- Matched paint colours from major UK brands (Farrow & Ball, Little Greene, Lick, Dulux, Crown) with colour codes, names, and price per litre
- Cross-brand price comparison where colour matches exist (e.g., "Farrow & Ball Hague Blue, 49 per 2.5L vs Lick Blue 08, 32 per 2.5L, 92% colour match")
- A "See it in a room" link that shows curated example photos featuring that colour family

Premium users can add colours (from the interactive colour wheel, from a photo via camera extraction, or from the paint brand library), remove colours, or swap one for a related shade. The app gently flags when a new colour might clash with the existing palette and explains why.

Every paint colour swatch in the app displays a "Buy This Paint" button that deep-links to the retailer's product page with the exact colour code pre-selected. This is the primary affiliate touchpoint and should be frictionless (one tap to retailer checkout).

**Deep-link fallback ladder:** Retailer URLs break regularly when brands redesign their sites. The fallback must be **proactive, not reactive**: you cannot reliably detect whether a deep link works from within the app (the OS opens the browser regardless). Instead, maintain a **retailer config layer** (a JSON/database table per brand mapping colour codes to URL templates) that specifies which fallback level is currently working for each brand. Check and update this config quarterly.

Fallback levels per brand:

1. Exact product SKU link (ideal)
2. Brand product page with colour code in URL
3. Brand search results page with colour name pre-filled
4. Brand homepage with a "Copy colour code to clipboard" CTA

Budget a few hours per brand for initial URL template setup, and plan for quarterly re-verification.

**Indicative pricing:** All price-per-litre data is labelled "Prices approximate, last checked [date]" rather than presented as live pricing. Updated periodically (monthly or quarterly), not in real time. This prevents stale prices from undermining trust in the cross-brand comparison feature.

**Acceptance Criteria:**

- Palette displays 8-12 colours generated from onboarding
- Each colour links to at least 3 matched paint colours from real UK brands
- Cross-brand price comparison shown where delta-E match is 92%+ (configurable threshold), with disclaimer: "Paint finishes and pigments vary between brands. A close colour match is not identical. Always compare physical samples side by side."
- "Buy This Paint" deep link on every paint swatch in the app (not just My Palette) with fallback ladder (SKU > product page > search > homepage with copy code)
- All pricing labelled "Prices approximate, last checked [date]"
- Adding/removing/swapping colours (premium) updates the palette in real time
- Colour relationship explanations use plain language (no jargon)
- Palette is accessible from every screen in the app via a persistent shortcut

---

#### Feature 1.3: Colour Capture (Camera Extraction) [Phase 1B]

Users constantly encounter colours in the real world and want to bring them into their palette. This feature bridges the physical and digital worlds.

**User Stories:**

- As a user, I want to point my camera at any surface (a cushion, a tile, a wall, a sunset) and capture its colour so that I can use real-world inspiration in my palette.
- As a user, I want to know the undertone and palette family of a captured colour so that I understand how it will work in my home.
- As a user, I want to see the closest paint matches for a captured colour so that I can find it at a shop.
- As a free user, I want to save a captured colour to my moodboard so that I can build my vision even before upgrading.
- As a premium user, I want to add a captured colour to my palette with clash warnings so that my palette stays coherent.

**How it works:**

The camera viewfinder shows a reticle/target area. Users point at any surface and tap to capture. The app samples the pixels within the reticle, averages to a dominant colour (or uses k-means clustering for patterned surfaces), and converts to CIE L*a*b\* for matching.

**Important technical constraint:** Phone cameras auto-adjust white balance and exposure, so the captured colour is the _perceived_ colour under current lighting, not the true surface colour. A cool white wall under warm incandescent light will read as warm/yellow. The app does not attempt to classify the true undertone of the physical surface. Instead, it matches the captured colour to the closest paints in the database and reports the undertone and palette family of _those paint matches_. This is more reliable and more useful (the user wants to know "what paint is this closest to?" not "what is the absolute colour science of this surface").

The capture screen displays:

- The captured colour as a swatch with a "For best results, capture in natural daylight" tip
- The 3 closest paint matches from the database (with brand, name, code, price, and each match's undertone)
- Palette fit indicator with clear thresholds (see below)
- A "nudge warmer/cooler" slider allowing the user to manually adjust if they know the lighting is skewing the capture

**Palette fit algorithm:** The palette fit indicator uses delta-E (CIEDE2000) distance from the captured colour to the nearest colour in the user's existing palette:

- Delta-E < 25: green check, "Fits your palette"
- Delta-E 25-40: amber, "Could work, worth testing alongside your palette"
- Delta-E > 40: gentle warning, "This is a departure from your palette. That might be exactly the surprise you need, or it might clash."

**Free/premium boundary:** Free users can capture, view results (including paint matches and fit indicator), and save captured colours to their one free moodboard. The premium gate is on "save to palette with clash warnings," which is the decision-making tool.

Premium users can add the colour to their palette directly from this screen.

**Acceptance Criteria:**

- Colour extraction works in real time from the camera viewfinder
- Captured colour is matched to closest paints; undertone and palette family come from the paint match, not raw camera data
- At least 3 paint matches displayed (sorted by delta-E proximity)
- Palette fit indicator uses defined delta-E thresholds (< 25 / 25-40 / > 40)
- "Nudge warmer/cooler" slider available before locking the capture
- "Capture in natural daylight" guidance displayed in viewfinder
- Free users can save captured colours to their moodboard
- Adding to palette (premium) triggers clash check with explanation

---

#### Feature 1.4: Room Profiles [Phase 1A]

The room-by-room planning hub. This is where colour theory meets reality.

**User Stories:**

- As a user, I want to set up profiles for each room in my home so that I can plan colours room by room.
- As a premium user, I want the app to know which direction each room faces so that it can recommend colours that will actually work in my light.
- As a premium user, I want to understand how my room's light affects colour at different times of day so that I do not get surprised after painting.
- As a user, I want to pick one colour I love for a room and have the app suggest the rest so that I am not overwhelmed by having to choose everything at once.
- As a user with existing furniture I am keeping, I want to "lock" those items so that colour recommendations adapt around what I already own.
- As a renter, I want the app to focus on furniture, rugs, and accessories rather than wall paint so that I can personalise my space within my constraints.

**How it works:**

Users can create unlimited rooms (free and premium). For each room, they provide:

- Room name (from a preset list or custom)
- Direction the main window faces (N/S/E/W, or "not sure" which triggers the phone compass)
- Primary usage time (morning, afternoon, evening, all day)
- Desired mood (selected from Sowerby's mood vocabulary: calm, energising, cocooning, elegant, fresh, grounded, dramatic, playful)
- Budget bracket for this room (affordable / mid-range / investment). This is set per room, not globally. A user might be "investment" on the living room and "affordable" on a spare bedroom. Product recommendations filter per room based on the room's bracket.

**Light Direction Recommendations (Premium):**
The app cross-references the room's light direction and usage time against the user's palette to generate tailored colour recommendations. A north-facing room used in the evening gets very different suggestions than a south-facing room used in the morning. This is the primary conversion trigger.

_Free user experience (educational, builds desire):_
Free users enter their room's compass direction (the data is stored for when they upgrade). They see a personalised educational message and a blurred preview of the premium recommendations beneath it. Example copy for a north-facing room: "Your living room faces north. North-facing rooms get cool, blue-toned light that changes how every colour looks. Warm undertones will balance this beautifully. Unlock light-matched colour recommendations to see which shades from your palette will actually work in this room." Below: a blurred card showing recommendation previews with a clear upgrade CTA.

_Premium user experience (actionable, specific):_
Premium users see the full light-matched recommendations. Example copy: "Your living room faces north. Cool, blue-toned light means warm undertones will balance beautifully here. Based on your palette, here are your best options..." followed by specific colour suggestions tailored to the room's direction, usage time, and mood. The compass input is never wasted, even for free users, because the educational message is personalised to their room's actual direction.

**70/20/10 Planner (Premium, Progressive Entry):**
The flow starts simple: the user picks one colour they love for the room (the hero). The app then generates the full 70/20/10 breakdown automatically:

- 70% Hero Colour: walls, curtains, largest furniture. The user's chosen colour.
- 20% Beta Colour: one large piece plus 1-2 smaller touches. Auto-suggested using colour wheel logic (analogous or complementary relationship to hero, filtered by the room's light direction).
- 10% Surprise Colour: something unexpected. Constrained to colours in a complementary or split-complementary relationship with the hero, but from a _different palette family_ than the user's primary. This gives unexpectedness within a theoretically sound boundary and prevents the suggestion from feeling random or jarring.
- Dash: the connecting colours from other rooms (the red thread).

The algorithm is deterministic (rule-based colour theory, not ML). The quality of suggestions will make or break the product, so plan for significant tuning time: generate hundreds of sample outputs across all palette families and manually review them. The "Never auto-generate palette algorithms without visual review" boundary applies here.

The user's first interaction is a single decision, not three. They can then swap and adjust any tier.

**Compass UX Note:**
The compass requires the user to physically point their phone toward the window. The UI should make this clear: "Point your phone toward this room's main window and hold still for a moment." Only N/S/E/W classification is needed (90-degree buckets), so even moderate compass accuracy is sufficient.

**Existing Furniture Lock:**
Users can "lock" items they are keeping (e.g., a brown leather sofa assigned as the 20% Beta). The algorithm dynamically adjusts the remaining tiers to accommodate the locked item. For example, locking a warm brown sofa shifts the wall colour suggestions toward cooler blues and greens to create balance. This dramatically increases the planner's real-world utility because almost no first-time buyer starts with an empty house.

**Renter Mode:**
If the user selected "Renter" during onboarding, the 70/20/10 planner shifts focus. The 70% (walls) is locked to the landlord's existing colour (user photographs or selects "magnolia/white/other"). The planner concentrates on the 30% the renter can control: furniture (20%) and accessories/textiles/art (10%). All recommendations, product suggestions, and the Red Thread adapt to work within these constraints.

**Light Simulation Preview:**
For each room, the app shows how chosen colours will appear at different times of day using a colour temperature overlay. Three swatches side by side: morning, midday, evening, labelled clearly (e.g., "How Hague Blue looks in morning light in your north-facing living room"). Paired with plain-language guidance from Sowerby's rules. LRV data adds a brightness indicator alongside each colour.

**Visual QA note:** The Kelvin overlay at extreme values (7,500-10,000K for north-facing rooms) produces noticeably blue tints that can look unconvincing on warm colours. All simulation outputs across the full Kelvin range need manual visual review before launch. Phrase the UI around "helpful preview" rather than "photorealistic simulation." The colour disclaimer applies here too.

**Acceptance Criteria:**

- Users can create unlimited rooms (free and premium)
- Free users see personalised educational message for their room's compass direction plus blurred recommendation preview with upgrade CTA
- Premium users get full light direction recommendations following Sowerby's matrix
- 70/20/10 planner starts with a single hero colour pick; app auto-generates beta, surprise, and dash
- Users can override any suggestion with manual colour picks
- Existing Furniture Lock allows 1+ items to be locked per room with adaptive recommendations
- Renter Mode locks walls and shifts focus to furniture and accessories
- Light simulation shows 3 time-of-day variants for any colour in any room
- Compass-based direction detection works reliably on iOS and Android
- Each room profile is saveable and editable

---

#### Feature 1.5: Interactive Colour Wheel and White Finder [Phase 1A]

An educational tool that makes colour theory intuitive and explorable. The White Finder is promoted as a standalone feature because "choosing the wrong white" is one of the most relatable paint frustrations and a strong marketing hook ("Did you know there are 50+ shades of white? Find yours in 30 seconds").

**User Stories:**

- As a user, I want to explore colour relationships visually so that I understand why certain combinations work.
- As a user, I want to see what complementary, analogous, and triadic pairings look like for any colour so that I can experiment with confidence.
- As a user, I want to understand undertones so that I stop picking colours that look wrong on my walls.
- As a user, I want a dedicated tool to find the right white for my room so that I do not undermine my colour scheme with the wrong neutral.

**How it works:**

A zoomable, tappable colour wheel. Selecting any colour highlights its relationships: complementary (opposite), analogous (neighbours), triadic (triangle), and split-complementary. Each relationship type has a one-sentence explanation and example room photos.

An undertone layer can be toggled on, visually showing how every hue has warm and cool variants.

**White Finder (prominently accessible from Explore tab and from within any room profile):**
Shows the spectrum of whites organised by undertone (blue, pink, yellow, grey) with Sowerby's "Paper Test" tutorial. When accessed from a room profile, the White Finder is context-aware: it pre-filters to whites that suit the room's light direction.

**Acceptance Criteria:**

- Colour wheel is smooth and responsive (no lag on pan/zoom)
- Selecting a colour shows at least 3 relationship types with visual indicators
- Undertone toggle clearly differentiates warm vs cool variants
- White Finder covers at least 20 whites across 4 undertone families from multiple brands
- White Finder is accessible from both the Explore tab and within room profiles
- When accessed from a room profile, White Finder pre-filters by light direction
- Every educational element uses one sentence of explanation maximum (progressive disclosure for more detail)

---

#### Feature 1.6: The Red Thread (Whole-House Flow) [Phase 1A]

The feature no competitor has. A visual map of how colour flows through the entire home. Premium only, with blurred preview for free users.

**User Stories:**

- As a premium user, I want to see all my room colour choices on a single view so that I can check whether my home feels cohesive.
- As a premium user, I want the app to flag when adjacent rooms clash or feel disconnected so that I can fix it before committing.
- As a premium user, I want to define my "red thread" (2-4 unifying colours) and see how they appear across every room so that my house feels like one home, not a collection of separate rooms.
- As a free user, I want to see a blurred preview of the Red Thread so that I understand what I would get by upgrading.

**How it works:**

**Phase 1A: Templates + adjacency list.** Users select a floor plan template based on their property type (Victorian terrace, 1930s semi, post-war estate, modern flat, new build). Each template is a static layout with predefined tappable room zones. Users assign their rooms to zones on the template. Each room on the plan shows its hero colour as a filled block, with beta and surprise colours as smaller indicators.

For property types not covered by templates, users build a simple adjacency list: add rooms, then declare which rooms connect to each other ("Living room connects to hallway connects to kitchen"). The Red Thread coherence logic and adjacent room comparison work identically whether the data comes from a template or an adjacency list. The value of this feature is in the coherence analysis, not in spatial precision.

**Future: Custom floor plan drawing.** A freeform rectangle-based editor (rooms as rectangles, drag to arrange, snap to grid) is deferred to Phase 2 or later. This is a custom canvas interaction (create, resize, reposition, snap, label, undo/redo) that carries 2-3x the engineering time of any other Phase 1A feature. Templates + adjacency list cover 80%+ of target users (first-time buyers of period UK properties) and validate whether the Red Thread concept resonates before investing in a floor plan editor.

The red thread is defined at the top: the 2-4 colours that appear in some form in every room. The app highlights where these threads appear and flags rooms where no thread colour is present ("this room might feel disconnected from the rest of your home"). The coherence check is a straightforward set intersection: does any room's 70/20/10 contain zero overlap with the red thread colours?

Tapping any two adjacent rooms shows them side by side with their palettes, so the user can see the visual transition from space to space.

Free users who have created 3+ rooms see a blurred preview of the Red Thread view with a clear upgrade prompt.

**Acceptance Criteria:**

- Floor plan templates available for at least 5 common UK property types
- Adjacency list available for property types not covered by templates
- Custom floor plan drawing is NOT in Phase 1A scope (deferred)
- Red thread definition accepts 2-4 colours
- Coherence flagging identifies rooms with no thread colour present
- Adjacent room comparison view shows palettes side by side
- Whole-house view is exportable as an image and PDF (premium)
- Free users see a blurred preview after creating 3+ rooms

---

#### Feature 1.7: Digital Moodboards [Phase 1B]

Room-specific moodboards that bring the plan to life. Creating is free (1 moodboard); sharing, exporting, and unlimited moodboards are premium.

**User Stories:**

- As a user, I want to create a moodboard for each room so that I can see how my colour choices will look with real materials, furniture, and accessories.
- As a user, I want to save images from anywhere (web, Pinterest, Instagram, camera) into my moodboards so that I can collect inspiration in one place.
- As a premium user, I want to share my moodboard with my partner or a tradesperson so that we are aligned on the vision.
- As a premium user, I want to export my moodboard as a PDF so that I have a physical reference.

**How it works:**

Each room profile has an attached moodboard canvas. Users can add:

- Colour swatches from their palette (auto-populated from their room's 70/20/10 plan)
- Images saved from the web via the app's share extension
- Photos taken with the camera (fabric swatches, tiles, hardware samples, captured via Colour Capture)
- Products from the app's curated catalogue (Phase 2 for full product integration)

The moodboard auto-generates a colour summary showing whether the collected items align with the room's planned palette.

Free: 1 moodboard, view and build only (no share, no export).
Premium: Unlimited moodboards, shareable via link (viewable without the app installed), exportable as PDF.

**Acceptance Criteria:**

- Free users can create and build 1 moodboard
- Premium users get unlimited moodboards with share and export
- Share extension works reliably from Safari and Chrome. Pinterest share is best-effort (may receive URL rather than image; app fetches and renders the image from the URL). Instagram native app sharing is not supported (Instagram restricts share sheet data); users can save from Instagram via browser
- Camera capture saves to the moodboard with automatic colour extraction
- Colour alignment summary updates in real time as items are added
- Share link works without requiring the recipient to have the app (premium)
- PDF export includes the colour summary and all saved items (premium). Note: image-heavy moodboards (10+ high-resolution images) may need server-side PDF generation via cloud function to avoid memory issues on older devices. If server-side rendering is required, PDF export moves to the "online required" category

---

#### Feature 1.8: Sample Ordering Flow [Phase 1B]

The critical bridge between digital planning and physical commitment.

**User Stories:**

- As a user, I want to order sample pots or peel-and-stick samples for my shortlisted colours so that I can test them in my actual room before committing.
- As a user, I want the app to bundle my sample order across rooms so that I can order everything in one go.
- As a user, I want reminders and guidance on how to test my samples properly so that I get the most out of them.

**How it works:**

From any room profile or from My Palette, users can add colours to a "Sample List." The app aggregates samples across all rooms and groups them by brand, linking directly to each brand's sample ordering page (Farrow & Ball ~8 per pot, Lick ~2 for peel-and-stick, Dulux ~3-4 for tester pots, Little Greene sample pots).

After ordering, the app prompts a follow-up 3-5 days later: "Have your samples arrived? Here's how to test them properly." This links to a short guide based on Sowerby's method: paint onto moveable card (not directly onto walls), reposition around the room throughout the day, check in morning, afternoon, and evening light.

**Acceptance Criteria:**

- Colours can be added to a Sample List from any paint swatch in the app
- Sample List aggregates across all rooms and groups by brand
- Direct links to brand sample ordering pages
- Follow-up prompt triggers 3-5 days after a colour is added to the Sample List
- Testing guide follows Sowerby's moveable-card method
- Affiliate tracking on sample order links

---

#### Feature 1.9: Re-engagement and Notification Strategy [Phase 1B]

Decorating projects stretch over weeks or months. Without thoughtful nudges, users forget the app exists between decisions.

**Important: Notifications are OFF by default.** Apple's App Store requires opt-in for push notifications. The app requests notification permission after the user completes their first room profile (a moment of engagement where permission feels natural). The opt-in prompt explains what they will receive: "Get helpful reminders like when to test your paint samples and weekend project ideas?" Users who decline still see in-app prompts on the Home Dashboard; they just do not receive push notifications.

**User Stories:**

- As a user in the middle of a decorating project, I want helpful reminders that keep me on track without being annoying.
- As a user who just moved, I want the app to help me prioritise which rooms to tackle first.

**How it works:**

A lightweight notification system tied to the user's project state:

_Project-based prompts:_

- "Weekend project" Saturday morning nudge (e.g., "Test your sample colours today. Morning light is best for your east-facing kitchen")
- Progress celebrations: "You've planned 3 of 5 rooms. Your home is 60% there"
- Sample follow-up: "Have your samples arrived? Test them in evening light tonight"

_Life-event prompts:_

- Moving day countdown (user enters completion date; app generates a priority room sequence)
- "First Christmas in your new home" palette refresh prompt (October, drives accessory affiliate clicks)
- Spring textile refresh nudge (drives rug/cushion affiliate revenue)
- Clocks change reminder: "Your east-facing rooms will get more morning light next week. Here's how that affects your palette"

_Partner prompts (if Partner Mode is active):_

- "[Partner] updated the living room palette. Tap to see"
- "[Partner] reacted to a product recommendation. See where you agree"

All prompts are dismissible. Users control notification frequency in settings (daily/weekly/off).

**Acceptance Criteria:**

- Push notifications are OFF by default; opt-in prompt appears after first room profile completion
- Users who decline push notifications still see in-app prompts on the Dashboard
- Notification system respects user-configured frequency settings
- Project-based prompts are contextual (tied to rooms in progress, samples ordered, etc.)
- Life-event prompts trigger based on onboarding data (move date, season)
- All prompts are dismissible
- Partner prompts only appear when Partner Mode is active
- No notifications sent to users who have completed all rooms (until seasonal refresh)

---

### Phase 2: Curated Decisions (Expansion)

**Theme:** Move users from planning to purchasing with confidence. Ship the conversion feature (Visualiser) first, then revenue features (Recommender, Product Recs), then the retention feature (Partner Mode).

---

#### Feature 2.1: AI Room Visualiser

Show people how their choices will look before they commit. Highest-conversion Phase 2 feature.

**User Stories:**

- As a premium user, I want to upload a photo of my room and see it with my chosen colours applied so that I can visualise the result before painting.
- As a premium user, I want to see how my room will look at different times of day so that I understand the light effect.
- As a premium user, I want to compare two colour options side by side in my actual room so that I can make a confident final decision.

**How it works:**

Users photograph their room. The app uses Decor8 AI's `/change_wall_color` endpoint, which accepts a hex colour code and returns a realistic wall recolour. The API determines which surfaces are walls and applies the colour. Ceiling and trim are NOT separately targetable via this API; the scope at Phase 2 launch is wall colour only. Ceiling/trim targeting is a future stretch goal (may require a different API or manual masking).

The time-of-day light simulation is a local post-processing overlay (same Kelvin lookup + RGB blend as the swatch simulation in Feature 1.4, applied to the photograph). This is Palette's proprietary differentiator and adds zero API cost.

Comparison mode shows two colour options side by side in the same room photo. Each comparison consumes 2 credits (one per generation). The UI makes this clear before the user generates.

**Privacy and data retention:** Room photos are uploaded to Decor8 AI for processing and are not stored by Palette. The app should display a clear statement: "Your room photo is processed by our AI partner and is not stored after the visualisation is generated." This prevents churn and negative reviews from users who assume their home photos are being collected.

**Credit-based pricing:**

- Palette Pro: 25 credits/month included
- Palette Plus: 5 credits/month included
- Top-up packs: 10 credits for 1.99
- Non-subscribers can purchase visualiser packs (10 for 2.99) without a subscription

**Acceptance Criteria:**

- Wall colour application looks realistic across typical UK room photos (not a flat overlay)
- Scope is wall colour only at Phase 2 launch; ceiling and trim are out of scope
- Light simulation post-processing shows at least 3 time-of-day variants
- Comparison mode displays two options simultaneously (2 credits consumed, user warned)
- Processing time under 30 seconds per visualisation with clear loading state
- Graceful failure UX when API returns poor results (cluttered rooms, mirrors, open plan): offer retry or manual feedback, not a blank error
- Future enhancement (not Phase 2 launch): allow manual correction where users tap to mark "this is wall" when detection fails. Without this, support burden spikes for edge-case room photos. Defer unless failure rate exceeds 20% in beta testing
- Credit deduction only on successful generation
- Credit balance always visible before generating
- Privacy/data retention statement displayed before first use

---

#### Feature 2.2: Paint & Finish Recommender with Shopping List

**User Stories:**

- As a premium user, I want to know which paint finish to use in each room so that I do not choose matt for my bathroom or silk for my bumpy walls.
- As a premium user, I want a definitive paint shopping list for my entire home so that I can buy exactly what I need.
- As a premium user, I want to understand how much paint I need for each room so that I buy the right amount first time.

**How it works:**

Finish recommendations based on Sowerby's guide (matt for living rooms/bedrooms, eggshell for woodwork, satin for bathrooms/kitchens, silk for dark rooms needing light bounce). Paint calculator estimates quantity from room dimensions. Shopping list aggregates all paint across all rooms with brand, colour, code, finish, quantity, price, and "Buy This Paint" deep links. Cross-brand alternatives shown where available. "Complete the Look" bundles group non-paint items where the app knows the retailer: items from the curated product catalogue (Phase 2.3) and moodboard items saved via web link with a parseable retailer domain. Arbitrary camera photos on the moodboard cannot be matched to retailers and are excluded from bundles.

**Acceptance Criteria:**

- Finish recommendations follow Sowerby's matrix
- Paint calculator estimates within 10% of actual need
- Shopping list exportable as PDF and shareable via link (premium)
- Cross-brand alternatives shown where delta-E match exceeds 90%
- "Complete the Look" bundles appear where 2+ items from curated catalogue or web-saved links share a parseable retailer domain

---

#### Feature 2.3: Curated Product Recommendations

The anti-Pinterest. Three categories at launch: paint, rugs, lighting.

**User Stories:**

- As a premium user, I want to see 3-4 products that match my palette and room so that I can choose without drowning in options.
- As a user, I want to understand why a product has been recommended so that I trust the suggestions.
- As a user, I want to mark items I already own so that the app does not try to sell me things I do not need.

**How it works:**

3-4 options per category. Each includes: why it was chosen, price, retailer, direct purchase link (affiliate tracked). At least one non-sponsored alternative in every set. "Already own something similar?" toggle per category. Watson-Smyth's "something new, something old, something black, something gold" rule as a gentle checklist nudge. "We may earn a commission" disclosure visible.

**Acceptance Criteria:**

- 3-4 options maximum per category
- At least one non-sponsored alternative per set
- "Already own something similar?" toggle available
- Budget bracket filter applied before results shown
- Commission disclosure present and visible

---

#### Feature 2.4: Partner Mode

**User Stories:**

- As a premium user, I want to invite my partner to collaborate on our home's palette.
- As a premium user, I want to see where we agree and disagree on colour choices.
- As a premium user, I want a budget alignment indicator on product recommendations.

**How it works:**

Partner invited via link or email. Partner completes their own Colour DNA quiz (free, via web if no app). Shared Palette shows overlap and divergence. Both partners react to choices (love, like, unsure, not for me). Cost-to-execute gauge (affordable / mid-range / investment) visible on product recommendations when Partner Mode is active.

**Acceptance Criteria:**

- Partner can react via web without app install
- Shared Palette generates automatically from both profiles
- Overlap and divergence visually clear
- Reactions visible to both partners in real time
- Neither partner can override the other's choices
- Cost-to-execute gauge visible on product recommendations

---

### Phase 3: Full Home Companion (Future Vision)

**Theme:** Extend beyond colour into complete interior design and light renovation.

---

#### Feature 3.1: Lighting Planner

Follows Sowerby's three rules and Watson-Smyth's layering framework. Visual room diagram with suggested lamp positions and product recommendations.

#### Feature 3.2: Room Audit Checklist

Watson-Smyth's design rules codified: something old, something black, something metallic, layered lighting, signature piece, 70/20/10 balance, seasonal textiles. Visual scoring with actionable suggestions.

#### Feature 3.3: Renovation Sequencing (Settle Lite)

Lightweight sequencing guide adapted to property type. Correct order of operations with dependency flags and difficulty ratings. Not a full project management tool.

#### Feature 3.4: Seasonal Refresh Prompts

Seasonal textile and accessory swap suggestions within the existing palette. Shoppable with affiliate links. Extends re-engagement strategy into long-term retention.

---

## Design Principles (UX)

**1. The app should feel like a well-designed room, not a tech product.**
Warm whites, soft creams, muted earth tones as the base palette. A single warm accent (sage green or soft gold) for interactive elements (blue alternative in Colour Blind Mode). Clean sans-serif body type with an editorial serif for headings. Full-bleed imagery. No neon gradients, no heavy shadows, no "startup" aesthetic.

**2. Progressive disclosure, always.**
Show summary views first. Reveal complexity gradually. Surface the 3 most relevant actions at any stage. Use bottom sheets and overlays, not new screens.

**3. Image-first layouts.**
Colour swatches, room photos, product images, and moodboards are the heroes. Text supports images.

**4. Celebrate progress.**
Small animations at milestones. Skeleton loading states. Spring physics for transitions.

**5. Card-based UI with generous breathing room.**
Status indicators use icons as primary signal (checkmark, clock, empty circle) with colour supplementary. Generous padding.

**6. Context-aware navigation.**
Adapts emphasis based on journey stage: discovery, planning, acting, maintaining.

**7. Accessible by default.**
Dynamic Type (iOS) and font scaling (Android) from day one. Never rely on colour alone. Every swatch shows its name. WCAG AA contrast ratios throughout. Colour Blind Mode as settings toggle.

**8. Colour disclaimer always visible.**
"Colours on screens are approximations. Always test physical samples before committing." Present in onboarding, on swatch detail views, and in exports.

---

## Screen Architecture

**Tab 1: Home (Dashboard)**
Colour DNA card, active rooms with status, "next actions" (2-3 suggested tasks), "My Moodboards" quick-access card (one tap to view all moodboards across rooms, preserving discoverability for Priya and other renter/moodboard-heavy users), curated inspiration feed.

**Tab 2: My Rooms**
Room list with hero colours visible. Room profiles (direction, mood, 70/20/10, moodboard, products). Red Thread accessible from top (premium, blurred preview for free).

**Tab 3: Capture**
Camera colour extraction. One-tap save to palette or moodboard. Recently captured colour history.

**Tab 4: Explore**
Colour wheel, White Finder (prominently featured), paint library, palette family guides, educational content.

**Tab 5: Profile & Settings**
Colour DNA summary, account, preferences, partner management, subscription status, notification settings, Colour Blind Mode toggle, sample order history.

---

## Monetisation Model

### Pricing Tiers

**Free:**

- Colour DNA quiz and shareable result (web and app)
- Personal palette (view only, no edits)
- Unlimited room creation (invest effort before paywall)
- Basic colour wheel and White Finder
- 1 moodboard (build only, no share/export)
- Colour Capture (view results and save to moodboard, but no save to palette)
- Educational content (light direction explainer without room-specific recs)
- "Buy This Paint" affiliate links on all swatches

**Palette Plus (3.99/month or 29.99/year):**

- Everything in Free, plus:
- Palette editing (add, remove, swap)
- Light direction recommendations per room
- 70/20/10 planner with auto-generation and furniture lock
- Red Thread whole-house flow
- Unlimited moodboards with share and export
- Colour Capture save to palette with clash warnings
- Sample ordering flow with testing reminders
- 5 AI Visualiser credits/month (Phase 2)

**Palette Pro (7.99/month or 59.99/year):**

- Everything in Plus, plus:
- 25 AI Visualiser credits/month (Phase 2)
- Full curated product recommendations (paint + rugs + lighting)
- Paint & Finish Recommender with shopping list and quantities
- Partner Mode with shared palette and budget alignment
- Lighting Planner (Phase 3)
- Room Audit Checklist (Phase 3)

**Project Pass (24.99 one-time):**

- 6 months of full Palette Pro access
- For users who prefer a one-time purchase for a defined project
- **Expiry behaviour:** When the 6 months end, the user downgrades to Free. All data is preserved (rooms, moodboards, palette edits, Red Thread). They retain view access to everything they created but lose access to premium features (editing, exports, light recs, visualiser). The app shows a gentle re-conversion prompt 2 weeks before expiry ("Your Project Pass expires on [date]. Want to keep your premium features?") and again on the expiry day. No data is ever deleted.

**AI Visualiser Credit Top-ups:**

- 10 credits for 1.99 (in-app purchase, available to any tier)

**Annual pricing framing:** "Less than a Farrow & Ball sample pot per month."

### Revenue Streams

Primary: Subscriptions (Plus, Pro, Project Pass).
Secondary: Affiliate commissions ("Buy This Paint" links, product recommendations, sample orders, cross-brand price comparison clicks). UK paint affiliate commissions: 2-8%.
Tertiary: AI credit top-ups.
Future (Phase 3+): Sponsored brand collections (e.g., "Curated by Farrow & Ball for North-Facing Rooms"). Branded collections that feel editorial, not advertorial. Maximum one sponsored collection visible at any time. Charged as flat fee to brand, separate from affiliate commissions.

### Upgrade Triggers

Premium prompts appear after meaningful moments:

- After completing second room plan (light recs locked)
- When tapping Export on moodboard or shopping list
- When trying to define the Red Thread (blurred preview shown)
- When trying to edit palette
- When tapping "Save to Palette" in Colour Capture

Show preview of premium output (blurred Red Thread, blurred PDF) before paywall.

---

## User Personas

**Persona 1: "The Overwhelmed First-Timer" (Primary)**
Mia, 31. Just bought a 1930s semi in Essex with partner Tom. 400+ Pinterest pins, no plan. Loves green but terrified of mistakes. Bringing a brown leather sofa and IKEA pieces from rented flat. Never heard of undertones or 70/20/10.
_Needs:_ confidence, education, framework, visualisation, furniture lock. Likely Plus subscriber.

**Persona 2: "The Taste-Confident Upgrader" (Secondary)**
Raj, 37. Moving from rented flat to Victorian terrace in south London. Strong style opinions (jewel tones, mid-century). Great individual purchases that don't cohere. Frustrated by rooms that look good in photos but feel "off."
_Needs:_ red thread, light direction, curated recommendations. Likely Pro subscriber.

**Persona 3: "The Long-Term Renter" (Secondary)**
Priya, 28. Renting a 2-bed flat in Manchester. Cannot paint but wants personal space. Spends on cushions, throws, and prints that never quite come together.
_Needs:_ Renter Mode. 70/20/10 for furniture and accessories. Likely Plus subscriber.

**Persona 4: "The Reluctant Partner" (Tertiary)**
Sam, 34. Partner of someone deep in decorating decisions. Does not care much about interiors but wants an opinion without studying colour theory. Defaults to "whatever you think" or vetoes without explanation.
_Needs:_ Partner Mode. May never install the app; interacts via web links.

---

## Competitive Positioning

| Competitor                        | What They Do                        | What They Miss                                                  | Palette's Edge                                              |
| --------------------------------- | ----------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------- |
| **Dulux Visualizer**              | AR paint preview                    | No palette planning, no education, no whole-house, single-brand | Multi-brand, education-first, whole-house coherence         |
| **Lick**                          | Curated paint collections           | Walled garden, no personalisation, no light direction           | Brand-agnostic, personalised to emotional palette and light |
| **Houzz**                         | Inspiration library + pro directory | US-centric, bloated, no guided decisions                        | UK-focused, decision engine                                 |
| **Pinterest**                     | Infinite inspiration                | Zero structure, causes decision paralysis                       | Solves inspiration-to-decision gap                          |
| **HomeDesignsAI / ReimagineHome** | AI room restyling                   | No palette planning, no light direction, no whole-house         | Visualiser inside a complete system                         |

**Positioning:** Palette is the first interior design app that starts with who you are, not what is trending. The colour consultant in your pocket.

**Moat:** Red Thread requires whole-house data model from day one (hard to retrofit). Brand-agnostic positioning (Dulux/Lick can never replicate). Education-first approach (paint companies are culturally bad at teaching, only selling). Curated paint colour database (5,000+ colours normalised to CIE Lab with LRV and undertone classification across multiple brands) has standalone value as a data asset no competitor has assembled.

---

## Success Metrics

**Phase 1:**

- Quiz completion rate: 70%+
- Quiz share rate: 15%+
- Web quiz to app download: 25%+
- Rooms per user: 3+
- Free-to-Plus conversion: 5%+ (Note: Plus and Pro targets are additive segments, not overlapping. Combined paid conversion target: 7%)
- Free-to-Pro conversion: 2%+
- Project Pass purchases as % of total paid: 15%+
- "Buy This Paint" CTR (all users including free): 3%+ (affiliate links are live from day one)
- W4 retention: 25%
- App Store rating: 4.5+

**Phase 2:**

- Visualiser usage: 4+ per month per credit holder
- Credit top-up rate: 10% of visualiser users
- Product rec CTR: 8%+
- Affiliate conversion: 2%+
- "Buy This Paint" CTR (all users): 5%+ (target increase from Phase 1 baseline as product recs improve)
- Partner Mode adoption: 20% of Pro users
- Sample order conversion: 15% of users with 3+ rooms
- Days from first room to first sample order: target under 14 days (measures planning-to-action speed)

**Phase 3:**

- MAU retention at 12 months: 15%
- ARPU (paying users): 5/month
- Project Pass renewal/conversion rate: 30%+ of expired passes convert to subscription or repurchase
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

**Ask first:**

- Before adding any new dependency
- Before modifying data model or schema
- Before changing navigation or adding screens
- Before integrating any external API
- Before architectural decisions affecting multiple features
- Before implementing notification/push logic

**Never do:**

- Never commit API keys, secrets, or credentials
- Never remove a failing test without approval
- Never auto-generate palette algorithms without visual review
- Never hardcode brand-specific data that should come from a data layer
- Never skip accessibility (contrast ratios, screen reader, Dynamic Type)
- Never use em dashes in any user-facing text or documentation
- Never use colour alone to convey information
- Never use red/green pairings in UI status indicators

---

## Resolved Decisions

### 1. Paint Colour Database

**Decision: Build our own local database. No paid API at launch.**

**Data sources (priority order):**

_Primary: Direct approach to Lick and COAT Paints._ Both brands are in active growth/investment mode (Lick is currently crowdfunding on Republic to raise £1.5M; COAT has just appointed a new brand ambassador and engaged a performance marketing agency for 2026). Pitch: "We'll put your colours in front of decorators and drive affiliate sales." The timing for a CSV/colour data partnership is unusually good. Email their partnerships/marketing teams this week.

_Secondary: e-paint.co.uk for Farrow & Ball, Little Greene, Dulux._ Their ToS covers only product sales/returns and does not explicitly mention automated access or data extraction. Their Lab values are labelled "for guidance only" and based on "averages of various measurements using various spectrophotometers." Email sales@e-paint.co.uk for explicit permission. Frame as: "We're building an app that helps consumers choose paint. We'd like to use your publicly available colour reference data (with attribution) to match colours to paint brands. Is this acceptable?" Getting their blessing lets you use the data openly and builds a relationship for future data updates. If refused, fall back to manual curation from published colour cards and brand websites.

_Tertiary: Manual curation for Crown and gaps._

_Accelerator: Encycolorpedia API._ Three pricing tiers: User ($9.99/yr), Pro ($29.99/yr), Enterprise ($149.99/yr). The database contains 870,000+ colours with pre-calculated HEX, RGB, CMYK, and Lab values, including commercial paint codes. Sign up for Pro ($29.99/yr) immediately to evaluate data quality and coverage for UK paint brands. The Pro tier may be sufficient; upgrade to Enterprise only if needed. This could eliminate weeks of manual curation for Dulux and Crown. API documentation at api.encycolorpedia.com/doc.

**Per-brand effort estimate (manual curation, if needed):**

| Brand         | Approx. colours | Effort (manual curation) | Notes                                                                                          |
| ------------- | --------------- | ------------------------ | ---------------------------------------------------------------------------------------------- |
| Lick          | ~100            | 1 day                    | Small range. Website publishes hex values. Likely to share CSV directly.                       |
| COAT          | ~100            | 1 day                    | Small range. B Corp certified, "climate positive" positioning. Pitch the sustainability angle. |
| Farrow & Ball | ~150            | 2-3 days                 | Published colour cards, hex values available via multiple online sources.                      |
| Little Greene | ~300            | 3-4 days                 | Similar to F&B.                                                                                |
| Dulux         | ~2,000+         | 1-2 weeks                | This is where volume comes from. Encycolorpedia likely covers this.                            |
| Crown         | ~1,500+         | 1 week                   | Large range, less premium positioning. Deferred if time is tight.                              |

**Realistic total timeline:** 2-4 weeks of focused effort across 5 brands (excluding Crown) if doing manual curation. Encycolorpedia Pro would significantly reduce the Dulux/Crown effort.

**Phase 1A MVP scope:** You do not need 5,000-6,000 colours to validate the core loop. Phase 1A can ship with **500-1,500 carefully curated colours across 2-3 brands** (Lick + COAT + Farrow & Ball or Dulux), as long as the matching, "Buy This Paint" flow, and cross-brand comparison all work. This de-risks the timeline: if the core loop does not convert, you have saved weeks of data curation effort. Expand to full 5,000+ for Phase 1B or as brands respond to outreach.

**Colour space standardisation:** Converting brand-provided hex/RGB to CIE L*a*b\* requires standardised assumptions. All conversions must use **sRGB colour space with D65 illuminant** (the web standard). Document these assumptions in the codebase. Without standardisation, delta-E matching will be mathematically correct but visually inconsistent across brands.

**Internal data model:** CIE L*a*b\* as primary colour space (converted from hex/RGB via sRGB/D65). Enables delta-E matching (CIEDE2000), undertone classification, LRV storage. Schema: brand, name, code, Lab, RGB, hex, LRV, undertone, palette family, collection, approximate price per litre (indicative, labelled with "last checked" date, updated monthly/quarterly).

**Delta-E matching caveats:** Even a "close" delta-E match (e.g., 92%+) can look different in person due to finish differences (matte absorbs light differently from eggshell), pigment composition, and metamerism (colours that match under one light source but diverge under another). The existing colour disclaimer ("Colours on screens are approximations. Always test physical samples before committing") covers screen-to-wall discrepancy. Cross-brand comparisons should additionally note: "Paint finishes and pigments vary between brands. A close colour match is not identical. Always compare physical samples side by side."

**The data pipeline is a first-class deliverable.** Treat it as a versioned, repeatable process (script + versioned JSON), not a one-off manual task. The pipeline should: ingest source data (CSV, scraped HTML, or manual entry), convert to Lab via sRGB/D65, auto-classify undertone from the b\* channel (positive = warm, negative = cool), assign palette family via heuristic rules (with manual review of a representative sample per brand to calibrate), and output a versioned JSON file that the app bundles at build time. Plan for the pipeline to run quarterly for price updates and when new brand collections launch.

**Undertone classification:** The b* channel in CIE Lab provides the warm/cool axis (positive b* = warm/yellow undertone, negative b* = cool/blue undertone). The a* channel adds red-green information. Classification rules should be calibrated by manually reviewing 20-30 colours per brand and adjusting thresholds until the automated classification matches expert judgment. Treat undertone as probabilistic ("leaning warm") rather than absolute, especially for colours near the neutral boundary.

**Launch scope:** Phase 1A MVP: 500-1,500 colours across 2-3 brands. Full target: ~5,000-6,000 colours across 5+ brands (Phase 1B or as outreach responses arrive). **Running cost: zero (Encycolorpedia Pro at $29.99/yr if used).**

### 2. AI Room Visualiser

**Decision: Decor8 AI at $0.20/image, Phase 2 only. Credit-based pricing.**

Uses the `/change_wall_color` endpoint which accepts a hex colour code and room photo. Decor8's pre-built brand integrations focus on US brands (Benjamin Moore, Sherwin-Williams, Behr), but the hex code input works independently of brand, which is what Palette needs for UK brands. Time-of-day simulation is local post-processing (our differentiator). Revisit build-vs-buy at 50,000+ visualisations/month. Dart SDK available on pub.dev.

**Privacy/data handling (known):** Decor8's privacy policy states uploaded photos are "used solely to generate your requested designs," "stored securely in your account," "not shared with third parties without consent," and "not used for AI training without explicit opt-in consent." Photos are retained "for as long as your account is active." No auto-deletion timeline. **However**, their Terms of Service grants a broader license including the right to use uploads "for research and development purposes," which creates tension with the privacy policy. A Data Processing Agreement (DPA) should be negotiated before Phase 2 launch. See Open Question #2.

**Phase 1 cost: zero. Phase 2 cost: ~$0.20/visualisation, pay-as-you-go.**

### 3. Light Simulation

**Decision: Kelvin lookup + RGB blend overlay at 10-20% opacity. Local computation.**

North: 7,500-10,000K. South: 4,000-5,500K. East: 3,500-5,000K morning, 7,000-8,000K afternoon. West: reversed. Supplemented by LRV data. Phrase all UI around "helpful preview" rather than "photorealistic simulation." Extreme Kelvin values at the north-facing end produce noticeably blue tints; all outputs need visual QA across the full colour/Kelvin matrix before launch. **Running cost: zero.**

### 4. Product Catalogue Scope

**Decision: Paint, rugs, lighting at Phase 2. Sofas deferred.**

All affiliate-based, zero upfront cost.

### 5. Offline Capability

**Decision: Offline-first. Local database is source of truth.**

Offline: Palette, rooms, wheel, moodboards (viewing and rearranging), paint library, Red Thread, light simulation, Colour Capture.
Online: AI Visualiser, product recs, web image saving, share/export, Partner Mode sync, sample ordering links, web quiz result retrieval.
Potentially online: PDF export of image-heavy moodboards (10+ high-resolution images may exceed memory on older devices; may need server-side rendering via cloud function). Simple PDF exports (Red Thread summary, shopping list) can remain client-side.

**Running cost: zero.**

### 6. Colour Blind Accessibility

**Decision: First-class from day one. Colour Blind Mode as settings toggle.**

Always on: named swatches, icon-first status indicators, WCAG AA contrast, shape-based colour wheel indicators, Dynamic Type support.
Colour Blind Mode toggle: pattern overlays, W/C badges, prominent colour names, blue accent alternative.

**Running cost: zero.**

### 7. Tech Stack

**Decision: Flutter.**

All feasibility analysis converges on Flutter as the stronger framework choice for Palette. Key factors:

- Impeller rendering engine delivers 60fps with zero dropped frames on animation-heavy interactions (colour wheel pan/zoom, spring physics transitions). React Native benchmarks show 15.5% frame drops on iOS for comparable animation workloads.
- The colour wheel, light simulation overlays, and moodboard canvas are custom painting/blending operations that Flutter's `CustomPainter` handles natively, whereas React Native would require react-native-skia bridging.
- Decor8 AI publishes a Dart SDK on pub.dev, simplifying Phase 2 integration.
- Offline-first architecture is well-supported via SQLite/Hive with battle-tested patterns.
- PowerSync (for Supabase sync) has a dedicated Flutter SDK.

This does not preclude a future web or React-based version. The web Colour DNA quiz is a separate web project (Astro) that shares colour logic via shared JSON configuration files consumed by both the Dart app and the web site.

### 8. Backend

**Decision: Supabase + PowerSync.**

Supabase covers authentication, real-time sync (needed for Partner Mode), row-level security (needed for multi-user data), and has a generous free tier (50,000 MAUs). PostgreSQL foundation is a natural fit for the relational queries the Red Thread coherence-checking logic requires.

PowerSync provides the offline-first sync layer: a local SQLite database acts as the offline source of truth, and a background worker handles incremental sync with Supabase/Postgres when the device reconnects. This avoids building a custom bidirectional sync engine (which is notoriously difficult and would derail the timeline).

Phase 1A backend requirements are minimal: quiz result storage for the web-to-app handover, and user account management. The full Supabase real-time capabilities are needed in Phase 2 for Partner Mode.

### 9. App Store Colour Accuracy

**Decision: No specific policy exists. Ship the disclaimer and move on.**

There is no Apple or Google guideline specifically addressing colour accuracy in apps. Apple's App Review Guidelines address misleading practices generally but contain no colour-specific requirements. Overwhelming precedent exists: Dulux Visualizer, PaintGenius (uses delta-E matching), Datacolor ColorReader (claims "90% accuracy"), and Color Study (displays Lab/RGB values from camera) are all live in both stores.

Palette's planned disclaimer ("Colours on screens are approximations. Always test physical samples before committing") is more thorough than what any competitor includes. Ship it from day one in onboarding, swatch detail views, exports, and the AI Visualiser screen ("render is illustrative"). Avoid any claim like "exact colour match" or "guaranteed accurate" in marketing copy or App Store screenshots.

### 10. Affiliate Programmes

**Decision: Apply to Awin this week. Launch with plain links. Add tracking when approved.**

| Brand         | Network                           | Commission                               | Cookie  | Notes                                                                                                  |
| ------------- | --------------------------------- | ---------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------ |
| Farrow & Ball | Awin (UK: ID 20199)               | Up to 5% for content publishers, 3% base | 30 days | Apply via Awin. Small deposit required (refunded with first commission).                               |
| Dulux         | Awin (ID 12009)                   | 5% base on all sales                     | 30 days | UK-only. Same Awin account as F&B.                                                                     |
| Little Greene | Sovrn Commerce (formerly VigLink) | Varies (auto-monetisation)               | Varies  | Product mentions automatically become affiliate links. Simplifies "Buy This Paint" implementation.     |
| Lick          | CJ Affiliate / direct             | ~1% per sale                             | Unknown | Low rate. Lick products are also sold via B&Q.                                                         |
| B&Q           | Impact                            | 2% on home delivery + Click & Collect    | Unknown | Sells Lick, Dulux, Crown. May be better affiliate path for Lick products than Lick's own 1% programme. |
| Freshlick     | Awin (ID 101923)                  | 2% opening commission                    | 30 days | Multi-brand retailer, 10,000+ products. Useful fallback if individual brand approvals are slow.        |
| COAT          | Direct negotiation                | TBD                                      | TBD     | Uses loyalty-based "Club COAT" rather than a standard network. May need a direct referral code.        |

**Implementation approach:** Build the deep-link fallback ladder and "Buy This Paint" flow now with plain product links (no tracking parameters). Affiliate tracking is a pluggable layer: a link resolver + attribution params that can be added as a config change per brand, not a refactor. When Awin approves, prepend their tracking URL to existing database URLs.

**Apply this week:** Awin (covers F&B + Dulux in one account). Contact Little Greene about Sovrn Commerce. Pitch Lick and COAT directly (combine with colour data partnership outreach). RugVista and Pooky: email marketing teams to identify their programmes.

### 11. Web Quiz Infrastructure

**Decision: Astro + Supabase Edge Function + shared JSON config.**

| Component             | Decision                                | Rationale                                                                                                                                                                                                                                                                                                                                          |
| --------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Static site framework | Astro                                   | Single-page quiz experience, not a multi-page app. Astro ships zero JS by default and hydrates only interactive islands (the quiz steps). Faster load, better Core Web Vitals than Next.js.                                                                                                                                                        |
| Hosting               | Vercel or Cloudflare Pages              | Generous free tiers. Astro deploys to both trivially.                                                                                                                                                                                                                                                                                              |
| Quiz result storage   | Supabase (same instance as app backend) | One `quiz_results` table: `id`, `email` (nullable), `palette_family`, `colours_json`, `property_context`, `created_at`, `claimed_by_user_id` (nullable). When app user logs in and claims their result, link the row to their account.                                                                                                             |
| API endpoints         | Supabase Edge Functions                 | `POST /quiz-result` (saves result, returns `result_id`). `GET /quiz-result/:id` (retrieves for app import). Minimal serverless cost.                                                                                                                                                                                                               |
| Shared colour logic   | JSON configuration file                 | The quiz only needs the mapping from user selections to palette families and colour lists. Export as JSON files (`palette_families.json`, `colour_mappings.json`) that both the Dart app and the Astro site import. CIE Lab computation happens app-side only. No shared TypeScript/Dart library needed; the logic is a lookup, not a calculation. |
| Shareable card        | Server-rendered OG image                | Supabase Edge Function generates an OG image (or uses a template with the user's colours) so shared links have a beautiful preview on Instagram/WhatsApp without client-side rendering.                                                                                                                                                            |

The web quiz is not a complex engineering effort. It is: (a) 3 stages of tappable cards, (b) a result screen with a shareable image, (c) a "Get full results in the app" CTA with deep link. Ships alongside or shortly after Phase 1A as a parallel web project.

### 12. Web-to-App Handover (Deferred Deep Linking)

**Decision: Build your own lightweight handoff. No paid deep link provider at MVP.**

Neither Smler nor Dub offers deferred deep linking on their free tiers. Smler's deferred deep links start at their "Most Popular" tier (~$2.40/mo). Dub's deep links require a Pro plan ($24/mo). Paid attribution SDKs like Branch.io jump to $499+/month above 10,000 MAUs. None of these are justified before validating whether the web-to-app funnel drives meaningful conversions.

**The lightweight handoff:**

1. Web quiz completion stores result in Supabase with a unique `result_id`.
2. The shareable card link is `palette.app/quiz/[result_id]` (custom domain).
3. The "Get the app" CTA links to App Store / Play Store with the `result_id` encoded in the campaign URL (iOS: `ct` parameter in App Store link; Android: `referrer` parameter in Play Store link).
4. On first app launch, the app checks: (a) Did the user arrive from a campaign URL with a `result_id`? If yes, fetch the quiz result from Supabase. (b) If no campaign URL, prompt "Have you taken the Colour DNA quiz online? Enter your email to import your results."
5. Email save is the most reliable fallback and should be prominently offered on the web result screen (not buried).

**For Universal Links and App Links** (so `palette.app/quiz/[result_id]` opens the app if installed): these are free platform features. Host the `apple-app-site-association` and `assetlinks.json` files on your domain. No third-party provider needed.

This covers 80%+ of the funnel at zero cost. The 20% gap (users who skip email and whose campaign parameter gets lost) can be closed later by adding Smler (~$2.40/mo) or Dub Pro ($24/mo) once the funnel is validated.

### Cost Summary

| Item                 | Phase 1                                | Phase 2    |
| -------------------- | -------------------------------------- | ---------- |
| Paint database       | Zero (or $29.99/yr Encycolorpedia Pro) | Zero       |
| AI Visualiser        | Zero                                   | ~$0.20/vis |
| Light simulation     | Zero                                   | Zero       |
| Product catalogue    | Zero                                   | Zero       |
| Offline storage      | Zero                                   | Zero       |
| Accessibility        | Zero                                   | Zero       |
| Web quiz hosting     | Minimal (free tier)                    | Minimal    |
| Backend (Supabase)   | Free tier                              | Free tier  |
| Deep linking         | Zero (platform-native)                 | Zero       |
| **Total fixed cost** | **~Zero**                              | **~Zero**  |

Variable cost from AI API only, offset by credit pricing.

---

## Remaining Open Questions

These are genuine unknowns that depend on external responses. Each has a clear action, owner, deadline, and fallback.

### 1. Paint data: brand responses

**Action:** Email Lick partnerships team, COAT marketing team (or founder Rob Abrahams directly), and sales@e-paint.co.uk this week. Sign up for Encycolorpedia Pro ($29.99/yr) to evaluate data quality in parallel.

**Deadline:** Responses expected within 1-2 weeks. Begin manual curation in parallel so data work is not blocked by waiting.

**Fallback:** If Lick and COAT decline CSV sharing, their ranges are small enough (~100 colours each) to curate manually in a day per brand from their websites. If e-paint declines permission, curate from published colour cards and fan decks. Encycolorpedia Pro may cover Dulux and Crown entirely.

**What determines "resolved":** At least 500 colours across 2 brands confirmed and ingested into the data pipeline.

### 2. Decor8 AI: privacy and data processing clarification

**Action:** Email privacy@decor8.ai before Phase 2 development with three specific questions:

1. Are API-submitted photos treated differently from app-submitted photos for retention? (API users may not have "accounts" in the same way.)
2. Is there an API endpoint to delete a specific processed image after rendering?
3. Where is data processed? (Relevant for UK GDPR compliance post-Brexit.)

**Critical nuance:** Decor8's Terms of Service grants a broader license than their privacy policy suggests, including the right to "use uploaded photos for research and development purposes." This creates tension with the privacy policy's "not used for AI training without explicit opt-in." Negotiate a Data Processing Agreement (DPA) that explicitly limits retention and excludes training use.

**Deadline:** Must be resolved before Phase 2 development begins. Not blocking Phase 1.

**Fallback:** If Decor8 cannot provide satisfactory privacy terms, evaluate alternative providers or add a prominent user consent screen with full transparency about Decor8's retention policy.

### 3. COAT Paints affiliate structure

**Action:** During the colour data partnership outreach to COAT, also clarify their affiliate/referral model. COAT uses a loyalty-based "Club COAT" programme rather than a standard affiliate network. They may need a direct referral code (e.g., `PALETTE10`) that tracks conversions on their backend.

**Deadline:** Before "Buy This Paint" links go live for COAT colours.

**Fallback:** Link to COAT product pages without tracking. Monitor click-through data on Palette's side to demonstrate value, then renegotiate.

---

_This is a living document. Update it as decisions are made, requirements change, or new insights emerge from building._

_Last updated: February 2026_
_Author: Jamie_
