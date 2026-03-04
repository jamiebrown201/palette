import 'package:palette/core/constants/enums.dart';

/// Rich content definition for a colour archetype.
class ArchetypeDefinition {
  const ArchetypeDefinition({
    required this.archetype,
    required this.name,
    required this.headline,
    required this.description,
    required this.whyItWorks,
    required this.styleTips,
    required this.watchOutFor,
    required this.suggestedRooms,
  });

  final ColourArchetype archetype;
  final String name;
  final String headline;
  final String description;
  final String whyItWorks;
  final List<String> styleTips;
  final String watchOutFor;
  final List<String> suggestedRooms;
}

/// Maps primary family + saturation preference to an archetype.
///
/// All 14 archetypes are reachable through this map.
const Map<PaletteFamily, Map<ChromaBand, ColourArchetype>>
    familySaturationToArchetype = {
  PaletteFamily.warmNeutrals: {
    ChromaBand.muted: ColourArchetype.theCocooner,
    ChromaBand.mid: ColourArchetype.theCocooner,
    ChromaBand.bold: ColourArchetype.theGoldenHour,
  },
  PaletteFamily.coolNeutrals: {
    ChromaBand.muted: ColourArchetype.theCurator,
    ChromaBand.mid: ColourArchetype.theCurator,
    ChromaBand.bold: ColourArchetype.theMonochromeModernist,
  },
  PaletteFamily.pastels: {
    ChromaBand.muted: ColourArchetype.theRomantic,
    ChromaBand.mid: ColourArchetype.theRomantic,
    ChromaBand.bold: ColourArchetype.theColourOptimist,
  },
  PaletteFamily.earthTones: {
    ChromaBand.muted: ColourArchetype.theNatureLover,
    ChromaBand.mid: ColourArchetype.theNatureLover,
    ChromaBand.bold: ColourArchetype.theStoryteller,
  },
  PaletteFamily.jewelTones: {
    ChromaBand.muted: ColourArchetype.theVelvetWhisper,
    ChromaBand.mid: ColourArchetype.theVelvetWhisper,
    ChromaBand.bold: ColourArchetype.theMaximalist,
  },
  PaletteFamily.brights: {
    ChromaBand.muted: ColourArchetype.theBrightener,
    ChromaBand.mid: ColourArchetype.theBrightener,
    ChromaBand.bold: ColourArchetype.theBrightener,
  },
  PaletteFamily.darks: {
    ChromaBand.muted: ColourArchetype.theDramatist,
    ChromaBand.mid: ColourArchetype.theDramatist,
    ChromaBand.bold: ColourArchetype.theMidnightArchitect,
  },
};

/// Backward-compatible flat map (delegates to nested map with mid).
const Map<PaletteFamily, ColourArchetype> familyToArchetype = {
  PaletteFamily.warmNeutrals: ColourArchetype.theCocooner,
  PaletteFamily.coolNeutrals: ColourArchetype.theCurator,
  PaletteFamily.pastels: ColourArchetype.theRomantic,
  PaletteFamily.earthTones: ColourArchetype.theNatureLover,
  PaletteFamily.jewelTones: ColourArchetype.theVelvetWhisper,
  PaletteFamily.brights: ColourArchetype.theBrightener,
  PaletteFamily.darks: ColourArchetype.theDramatist,
};

/// Map quiz result to an archetype using family + saturation preference.
///
/// When [saturationPreference] is null, falls back to the mid mapping.
/// Special case: warmNeutrals + muted → theMinimalist if very low Cab*
/// average is detected (handled by the caller if needed).
ColourArchetype mapToArchetype({
  required PaletteFamily primaryFamily,
  ChromaBand? saturationPreference,
}) {
  final band = saturationPreference ?? ChromaBand.mid;
  return familySaturationToArchetype[primaryFamily]?[band] ??
      ColourArchetype.theCocooner;
}

/// Full content definitions for all archetypes.
///
/// All 14 archetypes are defined here. The basic version (Phase 0) only
/// maps 7 of them (one per family). The remaining 7 activate in Phase 2
/// when the saturation axis is introduced.
const Map<ColourArchetype, ArchetypeDefinition> archetypeDefinitions = {
  // ── Warm Neutrals ──────────────────────────────────────────────────────

  ColourArchetype.theCocooner: ArchetypeDefinition(
    archetype: ColourArchetype.theCocooner,
    name: 'The Cocooner',
    headline: 'Warmth without fuss',
    description:
        'You are drawn to colours that wrap a room in warmth — soft linens, '
        'weathered wood tones, and the gentle glow of golden-hour light. '
        'Your spaces feel like a deep exhale at the end of the day.',
    whyItWorks:
        'Warm neutrals share yellow and pink undertones that harmonise '
        'naturally. They create depth without drama, making rooms feel '
        'larger and more inviting as light shifts through the day.',
    styleTips: [
      'Layer three depths of the same warm tone — lightest on ceilings, '
          'mid on walls, deepest on woodwork — for a cocooning effect',
      'Choose a warm white with a yellow or pink base for trim; '
          'a blue-white will clash with your palette',
      'Add texture through natural materials — linen curtains, jute rugs, '
          'raw wood — to stop warm neutrals feeling flat',
    ],
    watchOutFor:
        'Too many similar mid-tones can make a room feel muddy. '
        'Ensure at least 15 points of lightness difference between '
        'your lightest and darkest wall colours.',
    suggestedRooms: ['Living room', 'Bedroom', 'Hallway'],
  ),

  ColourArchetype.theGoldenHour: ArchetypeDefinition(
    archetype: ColourArchetype.theGoldenHour,
    name: 'The Golden Hour',
    headline: 'Rich warmth, confident depth',
    description:
        'You gravitate toward the richer end of warm tones — deep honeys, '
        'amber glows, and caramel depths. Your spaces have the warmth of '
        'a late-summer evening, inviting and unapologetically cosy.',
    whyItWorks:
        'Saturated warm neutrals create rooms with real presence. The shared '
        'golden undertone ties deeper and lighter shades together, giving '
        'you richness without the risk of colours fighting each other.',
    styleTips: [
      'Use your deepest tone on a single feature wall and surround it '
          'with lighter versions of the same warmth',
      'Brass and aged gold hardware amplifies this palette beautifully — '
          'choose warm metals over chrome or nickel',
      'A dark anchor colour like a deep caramel on skirting boards '
          'grounds the whole room',
    ],
    watchOutFor:
        'In small or north-facing rooms, rich warm tones can feel heavy. '
        'Balance with generous warm white on ceilings and trim.',
    suggestedRooms: ['Dining room', 'Living room', 'Study'],
  ),

  // ── Cool Neutrals ─────────────────────────────────────────────────────

  ColourArchetype.theCurator: ArchetypeDefinition(
    archetype: ColourArchetype.theCurator,
    name: 'The Curator',
    headline: 'Considered calm',
    description:
        'You are drawn to the quiet confidence of cool greys, soft blues, '
        'and stone tones. Your spaces feel curated and intentional — '
        'every element earns its place.',
    whyItWorks:
        'Cool neutrals share blue and green undertones that create a sense '
        'of calm and spaciousness. They act as a sophisticated backdrop '
        'that lets furniture, art, and natural light take centre stage.',
    styleTips: [
      'Pair cool grey walls with a slightly warmer grey on trim '
          'to avoid the palette feeling clinical',
      'Introduce one natural material — pale oak flooring, stone, '
          'or concrete — to ground the coolness',
      'A single accent in a contrasting temperature (a warm brass lamp, '
          'a terracotta pot) adds life without disrupting the calm',
    ],
    watchOutFor:
        'In north-facing rooms, cool neutrals can feel cold and unwelcoming. '
        'Consider shifting one shade warmer or adding warm-toned textiles.',
    suggestedRooms: ['Home office', 'Bathroom', 'Open-plan living'],
  ),

  ColourArchetype.theMonochromeModernist: ArchetypeDefinition(
    archetype: ColourArchetype.theMonochromeModernist,
    name: 'The Monochrome Modernist',
    headline: 'Dramatic contrasts, clean lines',
    description:
        'You love the power of contrast — crisp whites against dramatic '
        'charcoals, sharp edges softened only by texture. Your spaces '
        'are bold, graphic, and deliberately minimal.',
    whyItWorks:
        'High-contrast cool neutrals create visual drama through lightness '
        'differences rather than colour. This makes rooms feel dynamic '
        'and architectural without any risk of colour clashing.',
    styleTips: [
      'Commit to the contrast — pale walls with very dark skirting '
          'and door frames creates a modern, graphic look',
      'Use matte finishes on dark surfaces and eggshell on light ones '
          'for subtle textural interest',
      'Limit your accent colours to just one or two — in this palette, '
          'less really is more',
    ],
    watchOutFor:
        'Pure black and pure white can feel harsh in UK light. '
        'Choose an off-black (like a very dark grey) and a warm white '
        'for a more liveable result.',
    suggestedRooms: ['Hallway', 'Bathroom', 'Kitchen'],
  ),

  // ── Pastels ────────────────────────────────────────────────────────────

  ColourArchetype.theRomantic: ArchetypeDefinition(
    archetype: ColourArchetype.theRomantic,
    name: 'The Romantic',
    headline: 'Gentle colour, quiet confidence',
    description:
        'You are drawn to whispered colour — soft blush, powder blue, '
        'and gentle sage. Your spaces feel calm and nurturing, with just '
        'enough colour to lift the mood without overwhelming it.',
    whyItWorks:
        'Pastels share high lightness and low saturation, creating a palette '
        'that feels cohesive even when mixing pink, blue, and green. '
        'The gentle tones reflect light beautifully, making rooms feel '
        'airy and spacious.',
    styleTips: [
      'Choose one pastel as your dominant wall colour and use white '
          'or a paler version for supporting rooms — this creates flow',
      'Avoid mixing pastels with competing warm whites; pick a white '
          'that matches your pastel\'s undertone',
      'Add depth with a mid-tone version of your dominant pastel '
          'on a feature wall or alcove — pastels need anchoring',
    ],
    watchOutFor:
        'An all-pastel scheme can feel saccharine. Ground it with '
        'one deeper accent — a soft navy cushion, a charcoal frame — '
        'to add grown-up sophistication.',
    suggestedRooms: ['Bedroom', 'Nursery', 'Bathroom'],
  ),

  ColourArchetype.theColourOptimist: ArchetypeDefinition(
    archetype: ColourArchetype.theColourOptimist,
    name: 'The Colour Optimist',
    headline: 'Joyful colour, playful spirit',
    description:
        'You love pastels with personality — confident lilacs, cheerful '
        'mint, and playful coral. Your spaces radiate optimism and warmth, '
        'proving that soft colours can still make a bold statement.',
    whyItWorks:
        'Bolder pastels retain the lightness that makes rooms feel open '
        'while delivering more colour impact. The shared high-lightness '
        'values keep the overall feel harmonious and uplifting.',
    styleTips: [
      'Pick your boldest pastel for the room you spend most time in — '
          'it will make you smile every time you walk in',
      'Mix two or three pastels from different hue families '
          '(pink + green, blue + peach) for an eclectic but cohesive look',
      'White woodwork is your best friend — it gives bold pastels '
          'breathing room and keeps the scheme fresh',
    ],
    watchOutFor:
        'Too many bold pastels in one room can feel chaotic. '
        'Limit yourself to two pastel wall colours per room and let '
        'one dominate.',
    suggestedRooms: ['Kitchen', 'Children\'s room', 'Living room'],
  ),

  // ── Earth Tones ────────────────────────────────────────────────────────

  ColourArchetype.theNatureLover: ArchetypeDefinition(
    archetype: ColourArchetype.theNatureLover,
    name: 'The Nature Lover',
    headline: 'Grounded in nature',
    description:
        'You are drawn to the quiet palette of the outdoors — muted olive, '
        'stone grey, and soft clay. Your spaces feel connected to nature, '
        'restful and grounded without being heavy.',
    whyItWorks:
        'Earth tones are drawn from the natural landscape where they always '
        'work together. The shared warmth and low-to-mid saturation create '
        'rooms that feel timeless and universally calming.',
    styleTips: [
      'Use your lightest earth tone (stone or clay) as the dominant '
          'wall colour and bring deeper tones in through furniture and textiles',
      'Natural textures are essential — raw linen, unglazed ceramics, '
          'and woven baskets complete the earthy feel',
      'Greenery (real plants) is the perfect accent for this palette — '
          'it echoes the natural inspiration',
    ],
    watchOutFor:
        'Earth tones can feel dark in rooms with limited natural light. '
        'Reserve your deepest shades for well-lit south-facing rooms '
        'and use lighter tones elsewhere.',
    suggestedRooms: ['Living room', 'Bedroom', 'Conservatory'],
  ),

  ColourArchetype.theStoryteller: ArchetypeDefinition(
    archetype: ColourArchetype.theStoryteller,
    name: 'The Storyteller',
    headline: 'Rich earth, bold character',
    description:
        'You love earth tones with real depth — terracotta that glows, '
        'ochre that commands attention, and burnt sienna that wraps a room '
        'in spiced warmth. Your spaces tell a story.',
    whyItWorks:
        'Saturated earth tones bring the warmth and groundedness of nature '
        'with added intensity. The shared orange-brown undertones ensure '
        'harmony even at higher saturation levels.',
    styleTips: [
      'A single terracotta feature wall paired with warm white creates '
          'a stunning focal point without overwhelming the room',
      'Layer different earth tones by depth — lightest ochre on most walls, '
          'deepest terracotta as an accent',
      'Dark wood furniture and warm metals (copper, brass) are natural '
          'companions for bold earth tones',
    ],
    watchOutFor:
        'Bold earth tones in every room can feel relentless. '
        'Use lighter, muted versions in connecting spaces like hallways '
        'to give the eye a rest.',
    suggestedRooms: ['Dining room', 'Kitchen', 'Study'],
  ),

  // ── Jewel Tones ────────────────────────────────────────────────────────

  ColourArchetype.theVelvetWhisper: ArchetypeDefinition(
    archetype: ColourArchetype.theVelvetWhisper,
    name: 'The Velvet Whisper',
    headline: 'Quiet opulence',
    description:
        'You are drawn to the softer side of richness — dusty teal, '
        'muted plum, and soft emerald. Your spaces feel luxurious but '
        'liveable, with depth that reveals itself slowly.',
    whyItWorks:
        'Muted jewel tones retain the richness and complexity of their '
        'saturated cousins while being easier to live with day-to-day. '
        'Their shared depth creates a sophisticated, layered feel.',
    styleTips: [
      'Choose one muted jewel tone as your hero colour and pair it '
          'with warm neutrals for a balanced, elegant scheme',
      'Velvet and silk fabrics in your palette colours amplify the '
          'luxurious quality these tones naturally carry',
      'A deep anchor colour on woodwork (dark teal or plum skirting) '
          'adds period charm, especially in Victorian or Edwardian homes',
    ],
    watchOutFor:
        'Muted jewel tones can read as grey in poor light. '
        'Test your chosen colour under your room\'s actual lighting '
        'conditions before committing.',
    suggestedRooms: ['Living room', 'Bedroom', 'Dining room'],
  ),

  ColourArchetype.theMaximalist: ArchetypeDefinition(
    archetype: ColourArchetype.theMaximalist,
    name: 'The Maximalist',
    headline: 'Unapologetically bold',
    description:
        'You love colour at full volume — deep sapphire, rich emerald, '
        'and dramatic ruby. Your spaces are confident, enveloping, and '
        'designed to make a lasting impression.',
    whyItWorks:
        'Saturated jewel tones create rooms with real presence and intimacy. '
        'Despite their intensity, they harmonise through shared depth '
        'and richness, making bold combinations feel intentional.',
    styleTips: [
      'Go all in — paint walls, woodwork, and ceiling in the same '
          'deep jewel tone for a truly immersive, enveloping effect',
      'High ceilings and period features (cornicing, picture rails) '
          'are perfect canvases for saturated jewel tones',
      'Metallic accents (gold, brass) against deep jewel tones create '
          'a timeless, luxurious combination',
    ],
    watchOutFor:
        'Bold jewel tones absorb light aggressively. Ensure good '
        'artificial lighting and consider a lighter hallway palette '
        'to provide contrast as you move through the house.',
    suggestedRooms: ['Dining room', 'Snug', 'Master bedroom'],
  ),

  // ── Brights ────────────────────────────────────────────────────────────

  ColourArchetype.theBrightener: ArchetypeDefinition(
    archetype: ColourArchetype.theBrightener,
    name: 'The Brightener',
    headline: 'Colour that makes rooms come alive',
    description:
        'You are drawn to colour that lifts the energy of a room — vivid '
        'yellows, warm corals, and bold teals. Your spaces feel optimistic '
        'and alive, reflecting your confident approach to colour.',
    whyItWorks:
        'Bright colours work by creating focal points that draw the eye '
        'and energise a space. When balanced with neutral supporting colours, '
        'they bring personality without chaos.',
    styleTips: [
      'Use your brightest colour on one wall or a defined area '
          '(alcove, chimney breast) and keep surrounding walls neutral',
      'Bright colours are powerful in small doses — a vivid front door, '
          'a bold kitchen island, or colourful shelving can transform a space',
      'Balance brights with a generous amount of white or light neutral '
          'to let them breathe and avoid visual fatigue',
    ],
    watchOutFor:
        'Bright colours on every surface will overwhelm. '
        'The 70/20/10 rule is your best friend — 70% neutral, '
        '20% supporting colour, 10% bright accent.',
    suggestedRooms: ['Kitchen', 'Playroom', 'Home office'],
  ),

  // ── Darks ──────────────────────────────────────────────────────────────

  ColourArchetype.theDramatist: ArchetypeDefinition(
    archetype: ColourArchetype.theDramatist,
    name: 'The Dramatist',
    headline: 'Quiet drama, bold comfort',
    description:
        'You are drawn to the depth and intimacy of dark colours — '
        'charcoal wraps, deep navy comfort, and the quiet sophistication '
        'of near-black. Your spaces feel like a protective cocoon.',
    whyItWorks:
        'Dark colours create intimacy and make rooms feel cocooning '
        'and protected. They blur the boundaries between walls and '
        'ceiling, making architectural imperfections disappear and '
        'drawing attention to what you place within the space.',
    styleTips: [
      'Paint everything — walls, ceiling, woodwork — in the same dark '
          'colour for a truly immersive, cocooning experience',
      'Layer textures (matte walls, satin woodwork, glossy accents) '
          'to add visual interest within a single-colour scheme',
      'Light-coloured art, mirrors, and warm lighting become dramatic '
          'focal points against dark backgrounds',
    ],
    watchOutFor:
        'Dark colours in windowless rooms need excellent artificial '
        'lighting. Plan your lighting before painting — wall lights '
        'and table lamps work better than harsh overhead spots.',
    suggestedRooms: ['Snug', 'Bedroom', 'Dining room'],
  ),

  ColourArchetype.theMidnightArchitect: ArchetypeDefinition(
    archetype: ColourArchetype.theMidnightArchitect,
    name: 'The Midnight Architect',
    headline: 'Inky depth, bold statement',
    description:
        'You love the boldest end of dark — jet black statements, inky '
        'depths, and the kind of contrast that makes everything else pop. '
        'Your spaces are architectural and unapologetically dramatic.',
    whyItWorks:
        'Very dark colours act as a visual anchor, grounding everything '
        'in the room. The extreme contrast with lighter elements creates '
        'a gallery-like quality that makes furniture and art sing.',
    styleTips: [
      'Use very dark colours where you want to create a sense of '
          'occasion — a dramatic hallway, a moody dining room',
      'Pair inky walls with crisp white ceilings for maximum impact '
          'and a sense of height',
      'High-gloss dark paint on woodwork reflects light beautifully '
          'and adds a layer of sophistication',
    ],
    watchOutFor:
        'Very dark colours show every mark, dust particle, and '
        'imperfection. Use high-quality paint and prepare surfaces '
        'thoroughly for the best result.',
    suggestedRooms: ['Hallway', 'Cloakroom', 'Dining room'],
  ),

  // ── Cross-family (Phase 2 activation) ──────────────────────────────────

  ColourArchetype.theMinimalist: ArchetypeDefinition(
    archetype: ColourArchetype.theMinimalist,
    name: 'The Minimalist',
    headline: 'One perfect shade',
    description:
        'You believe in the power of restraint — warm whites, pale oak '
        'tones, and just one carefully chosen accent colour. Your spaces '
        'feel calm, purposeful, and effortlessly elegant.',
    whyItWorks:
        'A highly restrained palette lets light, texture, and form do '
        'the talking. With fewer colours competing for attention, each '
        'element in the room matters more.',
    styleTips: [
      'Choose your single accent colour with care — it will carry '
          'a lot of weight in the room, so pick something you truly love',
      'Vary the sheen of your neutral — matte walls, satin woodwork, '
          'gloss on doors — for subtle visual richness',
      'Natural materials (stone, wood, linen) provide warmth and texture '
          'that a minimal colour palette needs to feel complete',
    ],
    watchOutFor:
        'Minimalism done poorly can feel sterile. Ensure your warm white '
        'truly has warmth (check the undertone) and layer plenty of '
        'natural textures.',
    suggestedRooms: ['Open-plan living', 'Bedroom', 'Bathroom'],
  ),
};
