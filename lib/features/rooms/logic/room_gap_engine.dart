import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';

/// The type of gap identified in a room.
enum GapType {
  rug,
  taskLighting,
  accentLighting,
  ambientLighting,
  textureContrast,
  accentColour,
  storage,
  artwork,
  curtain,
  throwSoft,
  cushions,
  mirror,
  warmMaterial,
  coolMaterial,
  metalClash,
  woodClash,
  sheenBalance,
  redThread,
}

extension GapTypeX on GapType {
  String get displayName => switch (this) {
    GapType.rug => 'Grounding rug',
    GapType.taskLighting => 'Task lighting',
    GapType.accentLighting => 'Accent lighting',
    GapType.ambientLighting => 'Ambient lighting',
    GapType.textureContrast => 'Texture contrast',
    GapType.accentColour => 'Accent colour',
    GapType.storage => 'Storage solution',
    GapType.artwork => 'Wall art',
    GapType.curtain => 'Window dressing',
    GapType.throwSoft => 'Throw or blanket',
    GapType.cushions => 'Cushions',
    GapType.mirror => 'Mirror',
    GapType.warmMaterial => 'Warm material',
    GapType.coolMaterial => 'Cool material',
    GapType.metalClash => 'Metal harmony',
    GapType.woodClash => 'Wood harmony',
    GapType.sheenBalance => 'Sheen balance',
    GapType.redThread => 'Red Thread connection',
  };
}

/// How severe the gap is for the room.
enum GapSeverity { low, medium, high }

/// How confident the engine is in this gap diagnosis.
enum GapConfidence { low, medium, high }

/// A single identified gap in a room's design.
class RoomGap {
  const RoomGap({
    required this.gapType,
    required this.severity,
    required this.confidence,
    required this.whyItMatters,
    required this.evidence,
    this.blocker,
  });

  final GapType gapType;
  final GapSeverity severity;
  final GapConfidence confidence;
  final String whyItMatters;
  final List<String> evidence;
  final String? blocker;

  String get title => switch (gapType) {
    GapType.rug => 'Your room needs a grounding rug',
    GapType.taskLighting => 'Add task lighting',
    GapType.accentLighting => 'Add accent lighting for mood',
    GapType.ambientLighting => 'Add ambient lighting',
    GapType.textureContrast => 'Introduce texture contrast',
    GapType.accentColour => 'Add your accent colour',
    GapType.storage => 'Add a storage solution',
    GapType.artwork => 'Add wall art or prints',
    GapType.curtain => 'Add a window dressing',
    GapType.throwSoft => 'Add a throw or blanket',
    GapType.cushions => 'Layer in some cushions',
    GapType.mirror => 'Add a mirror for light and depth',
    GapType.warmMaterial => 'Add a warm material',
    GapType.coolMaterial => 'Add a cool material',
    GapType.metalClash => 'Your metals are fighting each other',
    GapType.woodClash => 'Your wood tones have clashing undertones',
    GapType.sheenBalance => 'Too many reflective surfaces',
    GapType.redThread => "Your Red Thread colour isn't present",
  };

  String get confidenceLabel => switch (confidence) {
    GapConfidence.high => 'Strong suggestion',
    GapConfidence.medium => 'Recommended',
    GapConfidence.low => 'Worth considering',
  };
}

/// Result of gap analysis for a room.
class RoomGapReport {
  const RoomGapReport({required this.gaps, required this.dataQuality});

  final List<RoomGap> gaps;
  final DataQuality dataQuality;

  bool get hasGaps => gaps.isNotEmpty;

  /// The single highest-priority gap (for "Recommended next buy").
  RoomGap? get primaryGap => gaps.isNotEmpty ? gaps.first : null;

  /// Remaining gaps after the primary one.
  List<RoomGap> get secondaryGaps =>
      gaps.length > 1 ? gaps.sublist(1) : const [];
}

/// How much furniture data we have to work with.
enum DataQuality { none, minimal, good, rich }

/// Analyse a room and identify what it still needs.
///
/// Gaps are prioritised by severity (high > medium > low) and within
/// the same severity by confidence (high > medium > low).
RoomGapReport analyseRoomGaps({
  required Room room,
  required List<LockedFurniture> furniture,
  required List<RedThreadColour> threadColours,
}) {
  final gaps = <RoomGap>[];
  final keepingItems = furniture
      .where((f) => f.isKeeping)
      .toList(growable: false);

  // Determine data quality
  final dataQuality = _assessDataQuality(keepingItems);

  // Only analyse if we have a 70/20/10 plan
  final hasPlan =
      room.heroColourHex != null &&
      room.betaColourHex != null &&
      room.surpriseColourHex != null;

  if (!hasPlan) {
    return RoomGapReport(gaps: gaps, dataQuality: dataQuality);
  }

  // --- Gap checks ---

  // 1. Rug check — no rug in any tier
  _checkRug(keepingItems, gaps, room);

  // 2. Lighting checks — no lighting items
  _checkLighting(keepingItems, gaps);

  // 3. Accent colour check — 10% tier empty
  _checkAccentColour(room, keepingItems, gaps);

  // 4. Texture contrast check
  _checkTextureContrast(keepingItems, gaps);

  // 5. Material balance: warm vs cool
  _checkMaterialBalance(keepingItems, gaps);

  // 6. Metal clash check
  _checkMetalClash(keepingItems, gaps);

  // 7. Wood tone clash check
  _checkWoodClash(keepingItems, gaps);

  // 8. Sheen balance check
  _checkSheenBalance(keepingItems, gaps);

  // 9. Soft furnishing gaps (cushions, throws, curtains)
  _checkSoftFurnishings(keepingItems, gaps);

  // 10. Artwork check — no wall art in the room
  _checkArtwork(keepingItems, gaps);

  // 11. Mirror check — north-facing or small rooms benefit from a mirror
  _checkMirror(keepingItems, gaps, room);

  // 12. Red Thread connection check
  _checkRedThread(room, threadColours, gaps);

  // Sort by severity desc, then confidence desc
  gaps.sort((a, b) {
    final sevCmp = b.severity.index.compareTo(a.severity.index);
    if (sevCmp != 0) return sevCmp;
    return b.confidence.index.compareTo(a.confidence.index);
  });

  return RoomGapReport(gaps: gaps, dataQuality: dataQuality);
}

DataQuality _assessDataQuality(List<LockedFurniture> items) {
  if (items.isEmpty) return DataQuality.none;
  final enhanced = items.where((f) => f.hasEnhancedData).length;
  if (enhanced == 0) return DataQuality.minimal;
  if (enhanced < items.length) return DataQuality.good;
  return DataQuality.rich;
}

void _checkRug(List<LockedFurniture> items, List<RoomGap> gaps, Room room) {
  final hasRug = items.any((f) => f.category == FurnitureCategory.rug);
  if (!hasRug) {
    String? blocker;
    if (items.isEmpty) {
      blocker = 'Add your existing furniture for better recommendations';
    } else if (room.roomSize == null && room.areaMetres == null) {
      blocker = 'Add room dimensions for better rug sizing';
    }
    gaps.add(
      RoomGap(
        gapType: GapType.rug,
        severity: GapSeverity.high,
        confidence:
            items.isNotEmpty ? GapConfidence.high : GapConfidence.medium,
        whyItMatters:
            'Without a rug, the room feels unfinished and the seating area '
            'floats. A rug grounds the space and defines the conversation zone.',
        evidence: [
          'No rug locked in any tier',
          if (items.isNotEmpty)
            '${items.length} other items locked'
          else
            'No furniture locked yet',
          if (room.roomSize != null) 'Room size: ${room.roomSize!.displayName}',
        ],
        blocker: blocker,
      ),
    );
  }
}

void _checkLighting(List<LockedFurniture> items, List<RoomGap> gaps) {
  final lightingItems =
      items.where((f) => f.category == FurnitureCategory.lighting).toList();

  if (lightingItems.isEmpty) {
    gaps.add(
      const RoomGap(
        gapType: GapType.ambientLighting,
        severity: GapSeverity.medium,
        confidence: GapConfidence.medium,
        whyItMatters:
            'Every room needs layered lighting — ambient, task, and accent. '
            'Without it, the space feels flat, especially in the evening.',
        evidence: ['No lighting items locked'],
      ),
    );
  } else if (lightingItems.length < 2) {
    gaps.add(
      const RoomGap(
        gapType: GapType.accentLighting,
        severity: GapSeverity.low,
        confidence: GapConfidence.low,
        whyItMatters:
            'A single light source creates harsh shadows. Adding a second '
            'layer of lighting (table lamp, floor lamp, or LED strip) adds '
            'depth and mood.',
        evidence: ['Only one lighting item locked'],
      ),
    );
  }
}

void _checkAccentColour(
  Room room,
  List<LockedFurniture> items,
  List<RoomGap> gaps,
) {
  final surpriseItems = items.where((f) => f.role == FurnitureRole.surprise);
  if (surpriseItems.isEmpty) {
    gaps.add(
      RoomGap(
        gapType: GapType.accentColour,
        severity: GapSeverity.medium,
        confidence: GapConfidence.high,
        whyItMatters:
            'Your 10% accent colour is what gives the room personality. '
            'Without it, the space can feel safe but one-dimensional.',
        evidence: [
          'Accent (10%) tier has no locked items',
          'Surprise colour: ${room.surpriseColourHex ?? "not set"}',
        ],
      ),
    );
  }
}

void _checkTextureContrast(List<LockedFurniture> items, List<RoomGap> gaps) {
  final textured = items.where((f) => f.textureFeel != null).toList();
  if (textured.length < 2) return; // Not enough data

  final allSmooth = textured.every((f) => f.textureFeel == TextureFeel.smooth);
  final allSoft = textured.every(
    (f) =>
        f.textureFeel == TextureFeel.highTexture ||
        f.textureFeel == TextureFeel.chunky,
  );

  if (allSmooth) {
    gaps.add(
      const RoomGap(
        gapType: GapType.textureContrast,
        severity: GapSeverity.medium,
        confidence: GapConfidence.high,
        whyItMatters:
            'All your surfaces are smooth. Adding a chunky knit throw, '
            'woven rug, or rattan basket creates visual and tactile interest.',
        evidence: ['All locked items with texture data are smooth'],
      ),
    );
  } else if (allSoft) {
    gaps.add(
      const RoomGap(
        gapType: GapType.textureContrast,
        severity: GapSeverity.medium,
        confidence: GapConfidence.high,
        whyItMatters:
            'Your room has lots of soft, plush surfaces. Adding harder '
            'textures like glass, metal, or smooth ceramic creates contrast.',
        evidence: ['All locked items with texture data are soft/chunky'],
      ),
    );
  }
}

void _checkMaterialBalance(List<LockedFurniture> items, List<RoomGap> gaps) {
  final materialed = items.where((f) => f.material != null).toList();
  if (materialed.length < 2) return;

  const warmMaterials = {
    FurnitureMaterial.wood,
    FurnitureMaterial.leather,
    FurnitureMaterial.wickerRattan,
    FurnitureMaterial.fabric,
  };
  const coolMaterials = {
    FurnitureMaterial.metal,
    FurnitureMaterial.glass,
    FurnitureMaterial.stone,
  };

  final warmCount =
      materialed.where((f) => warmMaterials.contains(f.material)).length;
  final coolCount =
      materialed.where((f) => coolMaterials.contains(f.material)).length;

  if (coolCount == 0 && warmCount >= 3) {
    gaps.add(
      const RoomGap(
        gapType: GapType.coolMaterial,
        severity: GapSeverity.low,
        confidence: GapConfidence.medium,
        whyItMatters:
            'Your room has only warm materials (wood, fabric, leather). '
            'Introducing some metal, glass, or stone creates contrast and '
            'stops the space feeling heavy.',
        evidence: [
          'All materials are warm (wood, fabric, leather)',
          'No cool materials (metal, glass, stone) present',
        ],
      ),
    );
  } else if (warmCount == 0 && coolCount >= 2) {
    gaps.add(
      const RoomGap(
        gapType: GapType.warmMaterial,
        severity: GapSeverity.low,
        confidence: GapConfidence.medium,
        whyItMatters:
            'Your room has mostly cool, hard materials. Adding wood, '
            'fabric, or leather softens the space and makes it feel '
            'more inviting.',
        evidence: [
          'All materials are cool (metal, glass, stone)',
          'No warm materials (wood, fabric, leather) present',
        ],
      ),
    );
  }
}

void _checkMetalClash(List<LockedFurniture> items, List<RoomGap> gaps) {
  final metals =
      items
          .where((f) => f.metalFinish != null)
          .map((f) => f.metalFinish!)
          .toSet();

  if (metals.length < 3) return;

  // Check if they span warm and cool undertones
  final warmMetals = metals.where((m) => m.undertone == Undertone.warm);
  final coolMetals = metals.where((m) => m.undertone == Undertone.cool);

  if (warmMetals.isNotEmpty && coolMetals.isNotEmpty) {
    gaps.add(
      RoomGap(
        gapType: GapType.metalClash,
        severity: GapSeverity.medium,
        confidence: GapConfidence.high,
        whyItMatters:
            'Your room has ${metals.length} different metal finishes spanning '
            'warm and cool tones. A room works best with one dominant metal '
            'and at most one accent.',
        evidence: [
          'Warm metals: ${warmMetals.map((m) => m.displayName).join(", ")}',
          'Cool metals: ${coolMetals.map((m) => m.displayName).join(", ")}',
        ],
      ),
    );
  }
}

void _checkWoodClash(List<LockedFurniture> items, List<RoomGap> gaps) {
  final woods =
      items.where((f) => f.woodTone != null).map((f) => f.woodTone!).toSet();

  if (woods.length < 2) return;

  final warmWoods = woods.where((w) => w.undertone == Undertone.warm);
  final coolWoods = woods.where((w) => w.undertone == Undertone.cool);

  if (warmWoods.isNotEmpty && coolWoods.isNotEmpty) {
    gaps.add(
      RoomGap(
        gapType: GapType.woodClash,
        severity: GapSeverity.medium,
        confidence: GapConfidence.high,
        whyItMatters:
            'Your wood tones have clashing undertones — warm-toned and '
            'cool-toned woods in the same room can feel disjointed. Consider '
            'swapping one or introducing a bridging material.',
        evidence: [
          'Warm woods: ${warmWoods.map((w) => w.displayName).join(", ")}',
          'Cool woods: ${coolWoods.map((w) => w.displayName).join(", ")}',
        ],
      ),
    );
  }
}

void _checkSheenBalance(List<LockedFurniture> items, List<RoomGap> gaps) {
  final polishedItems =
      items.where((f) => f.finishSheen == FinishSheen.polished).length;

  if (polishedItems >= 3) {
    gaps.add(
      RoomGap(
        gapType: GapType.sheenBalance,
        severity: GapSeverity.low,
        confidence: GapConfidence.high,
        whyItMatters:
            'Your room has $polishedItems highly reflective surfaces. Too '
            'much sheen creates visual noise. Adding a matte-finish piece '
            'brings calm.',
        evidence: ['$polishedItems items with polished finish'],
      ),
    );
  }
}

void _checkSoftFurnishings(List<LockedFurniture> items, List<RoomGap> gaps) {
  if (items.length < 2) return; // Need some data context

  final categories = items.map((f) => f.category).toSet();

  // Cushion check — no cushions present among at least 3 items
  if (items.length >= 3 && !categories.contains(FurnitureCategory.other)) {
    final hasSoftSeating =
        categories.contains(FurnitureCategory.sofa) ||
        categories.contains(FurnitureCategory.chair);
    if (hasSoftSeating) {
      // Check if any item name suggests cushions (heuristic)
      final hasCushionLike = items.any(
        (f) => f.name.toLowerCase().contains('cushion'),
      );
      if (!hasCushionLike) {
        gaps.add(
          const RoomGap(
            gapType: GapType.cushions,
            severity: GapSeverity.low,
            confidence: GapConfidence.low,
            whyItMatters:
                'Cushions add colour, pattern, and comfort to seating. '
                'They are one of the easiest ways to introduce your accent '
                'colour without commitment.',
            evidence: ['Seating present but no cushions identified'],
          ),
        );
      }
    }
  }
}

void _checkArtwork(List<LockedFurniture> items, List<RoomGap> gaps) {
  if (items.length < 3) return; // Need enough context

  // Check if any item name or category suggests artwork/prints
  final hasArt = items.any(
    (f) =>
        f.name.toLowerCase().contains('art') ||
        f.name.toLowerCase().contains('print') ||
        f.name.toLowerCase().contains('poster') ||
        f.name.toLowerCase().contains('painting') ||
        f.name.toLowerCase().contains('picture'),
  );
  if (!hasArt) {
    gaps.add(
      const RoomGap(
        gapType: GapType.artwork,
        severity: GapSeverity.low,
        confidence: GapConfidence.low,
        whyItMatters:
            'Wall art adds personality and creates a vertical focal point. '
            'It also introduces your accent colour at eye level, which draws '
            'the eye around the room.',
        evidence: ['No artwork or prints identified among locked items'],
      ),
    );
  }
}

void _checkMirror(List<LockedFurniture> items, List<RoomGap> gaps, Room room) {
  if (items.length < 3) return;

  final hasMirror = items.any((f) => f.name.toLowerCase().contains('mirror'));
  if (hasMirror) return;

  // Mirrors are especially useful in north-facing or small rooms
  final isNorthFacing = room.direction == CompassDirection.north;
  final isSmall = room.roomSize == RoomSize.small;

  if (isNorthFacing || isSmall) {
    gaps.add(
      RoomGap(
        gapType: GapType.mirror,
        severity: GapSeverity.low,
        confidence: GapConfidence.medium,
        whyItMatters:
            isNorthFacing
                ? 'A mirror bounces the limited northern light around the room, '
                    'making the space feel brighter and more open.'
                : 'A well-placed mirror makes a small room feel larger by creating '
                    'visual depth and reflecting light.',
        evidence: [
          'No mirror identified among locked items',
          if (isNorthFacing) 'Room faces north (limited natural light)',
          if (isSmall) 'Room is small',
        ],
      ),
    );
  }
}

void _checkRedThread(
  Room room,
  List<RedThreadColour> threadColours,
  List<RoomGap> gaps,
) {
  if (threadColours.isEmpty) return;

  final roomHexes = [
    if (room.heroColourHex != null) room.heroColourHex!,
    if (room.betaColourHex != null) room.betaColourHex!,
    if (room.surpriseColourHex != null) room.surpriseColourHex!,
  ];

  if (roomHexes.isEmpty) return;

  for (final thread in threadColours) {
    final threadLab = hexToLab(thread.hex);
    for (final roomHex in roomHexes) {
      final roomLab = hexToLab(roomHex);
      if (deltaE2000(threadLab, roomLab) < 15.0) {
        return; // Connected — no gap
      }
    }
  }

  gaps.add(
    const RoomGap(
      gapType: GapType.redThread,
      severity: GapSeverity.medium,
      confidence: GapConfidence.high,
      whyItMatters:
          "None of your room's colours match the Red Thread. Without it, "
          'this room will feel disconnected from the rest of your home.',
      evidence: ['No 70/20/10 colour within delta-E 15 of any thread colour'],
    ),
  );
}
