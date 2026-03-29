import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';

/// A single step in the renovation sequence for a room.
class RenovationStep {
  const RenovationStep({
    required this.order,
    required this.title,
    required this.description,
    required this.whyThisOrder,
    required this.status,
    this.estimatedCostBracket,
    this.renterNote,
    this.tip,
  });

  /// Step number in the sequence (1-based).
  final int order;

  /// Short title (e.g. "Paint the walls").
  final String title;

  /// What this step involves.
  final String description;

  /// Why this step comes at this point in the sequence.
  final String whyThisOrder;

  /// Whether this step is done, in progress, or upcoming.
  final RenovationStepStatus status;

  /// Rough cost indication.
  final String? estimatedCostBracket;

  /// Note for renters (e.g. "Skip this step if you cannot paint").
  final String? renterNote;

  /// Professional tip for this step.
  final String? tip;
}

/// Status of a renovation step.
enum RenovationStepStatus {
  /// Evidence in the room data that this is done.
  done,

  /// Partially complete or in progress.
  inProgress,

  /// Not yet started.
  upcoming,

  /// Skipped (e.g. renter cannot paint).
  skipped,
}

extension RenovationStepStatusX on RenovationStepStatus {
  String get label => switch (this) {
    RenovationStepStatus.done => 'Done',
    RenovationStepStatus.inProgress => 'In progress',
    RenovationStepStatus.upcoming => 'Up next',
    RenovationStepStatus.skipped => 'Skipped',
  };
}

/// Complete renovation guide for a room.
class RenovationGuide {
  const RenovationGuide({
    required this.roomName,
    required this.steps,
    required this.summary,
    required this.completedCount,
    required this.totalCount,
    this.propertyNote,
  });

  final String roomName;
  final List<RenovationStep> steps;
  final String summary;
  final int completedCount;
  final int totalCount;

  /// Property-specific note (e.g. "Victorian homes often need...")
  final String? propertyNote;

  double get progressPercent =>
      totalCount > 0 ? completedCount / totalCount : 0;
}

/// Generates a renovation sequencing guide for a room.
///
/// Adapts the order based on property type, era, room type, tenure,
/// and what furniture is already locked. The sequence follows the
/// professional decorator's rule: work top-down, big-to-small,
/// structural-to-decorative.
RenovationGuide generateRenovationGuide({
  required Room room,
  required List<LockedFurniture> furniture,
  PropertyType? propertyType,
  PropertyEra? propertyEra,
  Tenure? tenure,
}) {
  final isRenter = room.isRenterMode || tenure == Tenure.renter;
  final roomLower = room.name.toLowerCase();

  final steps = <RenovationStep>[];
  var order = 1;

  // Step 1: Clear and prep
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Clear and prepare the room',
      description:
          'Remove furniture and belongings. Protect floors with dust sheets. '
          'Fill cracks and sand surfaces that need painting.',
      whyThisOrder:
          'Everything else is easier and cleaner when the room is empty.',
      status: _inferClearStatus(furniture),
      renterNote:
          isRenter
              ? 'Even if you are not painting, clearing the room helps you '
                  'see the space properly before making decisions.'
              : null,
      tip:
          'Take photos of the empty room from each corner. These are '
          'invaluable for planning and measuring.',
    ),
  );

  // Step 2: Fix structural issues (owners only)
  if (!isRenter) {
    steps.add(
      RenovationStep(
        order: order++,
        title: 'Fix structural issues',
        description:
            'Address damp, cracks, uneven floors, or damaged plaster. '
            'Check the ceiling for stains or damage.',
        whyThisOrder:
            'Structural problems must be fixed before any decorating, '
            'otherwise new finishes will deteriorate quickly.',
        status: RenovationStepStatus.upcoming,
        estimatedCostBracket: _structuralCostHint(propertyEra),
        tip: _structuralTip(propertyEra),
      ),
    );
  }

  // Step 3: Ceiling
  if (!isRenter) {
    steps.add(
      RenovationStep(
        order: order++,
        title: 'Paint the ceiling',
        description:
            'Always start with the ceiling. Use a matt or flat finish '
            'to reduce glare and make the room feel taller.',
        whyThisOrder:
            'Paint drips downward. Doing the ceiling first means any '
            'splashes on the walls get covered in the next step.',
        status: RenovationStepStatus.upcoming,
        tip:
            'Use a warm white that matches the undertone of your wall '
            'colour. A pure brilliant white can look harsh against '
            'warm-toned walls.',
      ),
    );
  }

  // Step 4: Walls
  if (!isRenter) {
    final hasHero = room.heroColourHex != null;
    steps.add(
      RenovationStep(
        order: order++,
        title: 'Paint the walls',
        description:
            hasHero
                ? 'Apply your chosen hero colour. Two coats for full coverage. '
                    'Cut in edges first, then roll the main areas.'
                : 'Choose your wall colour first using the room planner, '
                    'then apply two coats for full coverage.',
        whyThisOrder:
            'Walls go after the ceiling but before woodwork, so you can '
            'cut clean lines against fresh wall paint.',
        status:
            hasHero
                ? RenovationStepStatus.inProgress
                : RenovationStepStatus.upcoming,
        estimatedCostBracket: _paintCostHint(room),
        tip: _paintFinishTip(roomLower),
      ),
    );
  } else {
    // Renters: identify existing wall colour
    final hasWall = room.wallColourHex != null;
    steps.add(
      RenovationStep(
        order: order++,
        title: 'Identify your wall colour',
        description:
            hasWall
                ? 'You have identified your existing wall colour. All '
                    'recommendations will work around it.'
                : 'Photograph your walls or match them to a common '
                    'landlord colour so recommendations suit your space.',
        whyThisOrder:
            'Knowing the fixed wall colour is the foundation for every '
            'other choice in the room.',
        status:
            hasWall ? RenovationStepStatus.done : RenovationStepStatus.upcoming,
        renterNote:
            "Most landlord walls are Magnolia, Builder's White, or Cool Grey. "
            'Knowing the undertone helps you pick furnishings that work.',
      ),
    );
  }

  // Step 5: Woodwork (owners only)
  if (!isRenter) {
    steps.add(
      RenovationStep(
        order: order++,
        title: 'Paint woodwork and trim',
        description:
            'Skirting boards, architraves, window frames, and door frames. '
            'Use eggshell for durability and easy cleaning.',
        whyThisOrder:
            'Woodwork goes after walls. The slight sheen of eggshell '
            'creates a clean line between wall and trim.',
        status: RenovationStepStatus.upcoming,
        tip:
            "Match the trim white to your wall colour's undertone. "
            'A cool white against warm walls creates an unintentional clash.',
      ),
    );
  }

  // Step 6: Flooring
  final hasRug = furniture.any((f) => f.category == FurnitureCategory.rug);
  steps.add(
    RenovationStep(
      order: order++,
      title: isRenter ? 'Define the floor' : 'Install or update flooring',
      description:
          isRenter
              ? 'Choose a rug to define the seating or sleeping area. '
                  'A rug is the single biggest impact a renter can make.'
              : 'Lay flooring before bringing in large furniture. '
                  'Consider how the floor colour interacts with your walls.',
      whyThisOrder:
          isRenter
              ? 'The rug anchors everything else. Pick it before '
                  'choosing smaller accessories.'
              : 'Flooring goes under furniture. Installing it after '
                  'large pieces arrive means moving everything twice.',
      status:
          hasRug ? RenovationStepStatus.done : RenovationStepStatus.upcoming,
      renterNote:
          isRenter
              ? 'A large rug (at least 160x230cm for a living room) covers '
                  'landlord carpet and defines your style instantly.'
              : null,
      tip: _flooringTip(roomLower, isRenter),
    ),
  );

  // Step 7: Large furniture
  final largeFurniture = furniture.where(
    (f) =>
        f.category == FurnitureCategory.sofa ||
        f.category == FurnitureCategory.bed ||
        f.category == FurnitureCategory.table,
  );
  final hasLarge = largeFurniture.isNotEmpty;
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Place large furniture',
      description:
          'Sofa, bed, dining table, or main storage. These are the '
          "70% (hero) pieces that define the room's character.",
      whyThisOrder:
          'Large furniture dictates the layout and determines where '
          'everything else goes. Get this right first.',
      status:
          hasLarge ? RenovationStepStatus.done : RenovationStepStatus.upcoming,
      tip:
          'Leave at least 90cm walkways around large furniture. '
          'The most common mistake is buying pieces that are too '
          'big for the room.',
    ),
  );

  // Step 8: Lighting
  final hasLighting = furniture.any(
    (f) => f.category == FurnitureCategory.lighting,
  );
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Set up lighting layers',
      description:
          'Ambient (ceiling or main), task (reading, desk), and accent '
          '(table lamps, LED strips). Three layers make a room feel '
          'finished and adaptable.',
      whyThisOrder:
          'Lighting comes after large furniture so you know where '
          'task light is needed and where accent light will shine.',
      status:
          hasLighting
              ? RenovationStepStatus.done
              : RenovationStepStatus.upcoming,
      renterNote:
          isRenter
              ? 'Plug-in floor lamps and table lamps are your best tools. '
                  'No wiring needed, and they travel with you.'
              : null,
      tip:
          'Every room needs at least two light sources at different '
          'heights. A single overhead light flattens the room.',
    ),
  );

  // Step 9: Window treatments
  steps.add(
    RenovationStep(
      order: order++,
      title: isRenter ? 'Add window dressing' : 'Hang curtains or blinds',
      description:
          isRenter
              ? 'Lightweight curtains on a tension rod, or no-drill '
                  'blinds. Frame the window to add softness and colour.'
              : 'Hang curtain poles 15cm above the window frame and '
                  '15cm wider on each side to make windows look larger.',
      whyThisOrder:
          'Window treatments come after furniture because the curtain '
          'fabric should complement your sofa or bed.',
      status: RenovationStepStatus.upcoming,
      renterNote:
          isRenter
              ? 'Tension rods and command-hook curtain rods leave no marks.'
              : null,
      tip:
          'Curtains that just touch the floor look most polished. '
          'Too short looks unfinished; too long looks messy.',
    ),
  );

  // Step 10: Secondary furniture and storage
  final hasStorage = furniture.any(
    (f) =>
        f.category == FurnitureCategory.shelving ||
        f.category == FurnitureCategory.storage ||
        f.category == FurnitureCategory.chair,
  );
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Add secondary furniture',
      description:
          'Side tables, shelving, occasional chairs, storage. These are '
          'the 20% (beta) pieces that support the hero.',
      whyThisOrder:
          'Secondary pieces fill gaps around the main furniture. '
          'Placing them too early means rearranging later.',
      status:
          hasStorage
              ? RenovationStepStatus.done
              : RenovationStepStatus.upcoming,
      tip:
          'Mix wood tones rather than matching perfectly. A walnut '
          'side table next to a honey oak shelf adds depth.',
    ),
  );

  // Step 11: Soft furnishings (the 10%)
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Layer soft furnishings',
      description:
          'Cushions, throws, and textiles. These are the 10% (accent) '
          'pieces that bring colour pops and texture variety.',
      whyThisOrder:
          'Soft furnishings are the finishing layer. They tie the room '
          'together and are the easiest to swap seasonally.',
      status: RenovationStepStatus.upcoming,
      tip:
          'Group cushions in odd numbers (3 or 5). Mix at least two '
          'textures (e.g. velvet and linen) for visual interest.',
    ),
  );

  // Step 12: Art and accessories
  steps.add(
    RenovationStep(
      order: order++,
      title: 'Hang art and place accessories',
      description:
          'Artwork, mirrors, plants, candles, decorative objects. '
          'Place accent colours in a triangle around the room.',
      whyThisOrder:
          'Art and accessories go last because they respond to everything '
          'else. Hanging art before the sofa arrives is guesswork.',
      status: RenovationStepStatus.upcoming,
      renterNote:
          isRenter
              ? 'Command strips and leaning frames avoid drilling. '
                  'A large mirror leaning against a wall adds light and depth.'
              : null,
      tip:
          'Hang art at eye level (centre of the piece at about 150cm '
          'from the floor). Above a sofa, leave a 15-20cm gap.',
    ),
  );

  final completedCount =
      steps.where((s) => s.status == RenovationStepStatus.done).length;

  return RenovationGuide(
    roomName: room.name,
    steps: steps,
    summary: _buildSummary(
      room: room,
      isRenter: isRenter,
      completedCount: completedCount,
      totalCount: steps.length,
    ),
    completedCount: completedCount,
    totalCount: steps.length,
    propertyNote: _propertyNote(propertyType, propertyEra),
  );
}

// ── Helpers ──────────────────────────────────────────────────────────

RenovationStepStatus _inferClearStatus(List<LockedFurniture> furniture) {
  // If user has locked furniture with statuses, they are past clearing
  if (furniture.isNotEmpty) return RenovationStepStatus.done;
  return RenovationStepStatus.upcoming;
}

String? _structuralCostHint(PropertyEra? era) {
  return switch (era) {
    PropertyEra.victorian || PropertyEra.edwardian =>
      'Older properties often need replastering or damp treatment. '
          'Budget for surprises.',
    PropertyEra.thirtiesToFifties || PropertyEra.postWar =>
      'Check for artex ceilings and lead paint on woodwork.',
    _ => null,
  };
}

String? _structuralTip(PropertyEra? era) {
  return switch (era) {
    PropertyEra.victorian =>
      'Victorian homes may have lime plaster. Use breathable paints '
          '(clay or lime-based) on original plaster to prevent damp.',
    PropertyEra.edwardian =>
      'Edwardian properties often have picture rails. Keep them if '
          'possible; they are a period feature and useful for hanging art.',
    PropertyEra.thirtiesToFifties =>
      '1930s homes commonly have single-skin bay windows that can be '
          'cold. Consider secondary glazing if the room feels draughty.',
    PropertyEra.newBuild =>
      'New builds often have very smooth walls. A quick sand is all '
          'you need before painting.',
    _ => null,
  };
}

String? _paintCostHint(Room room) {
  final area = room.areaMetres;
  if (area == null) return null;
  // Rough: 2.5L covers ~30m2 wall area; room wall area ~= floor area * 2.5
  final wallArea = area * 2.5;
  final litresNeeded = (wallArea / 12).ceilToDouble(); // ~12m2 per litre
  return 'You will need roughly ${litresNeeded.toStringAsFixed(0)}L for '
      'two coats in this room.';
}

String _paintFinishTip(String roomLower) {
  if (roomLower.contains('kitchen')) {
    return 'Use satin or soft sheen in the kitchen. It resists '
        'moisture and grease and is easy to wipe clean.';
  }
  if (roomLower.contains('bathroom')) {
    return 'Bathroom walls need satin or soft sheen for moisture '
        'resistance. Matt finishes can peel in humid rooms.';
  }
  if (roomLower.contains('hallway') || roomLower.contains('hall')) {
    return 'Consider eggshell on the lower half of hallway walls. '
        'It withstands scuffs from coats and bags.';
  }
  if (roomLower.contains('child') ||
      roomLower.contains('kid') ||
      roomLower.contains('nursery')) {
    return "Use eggshell or soft sheen on children's room walls. "
        'Little hands leave marks that matt paint cannot survive.';
  }
  return 'Matt finish is ideal for living rooms and bedrooms. It '
      'absorbs light evenly and hides small imperfections.';
}

String _flooringTip(String roomLower, bool isRenter) {
  if (isRenter) {
    return 'The number one amateur mistake is buying a rug that is '
        'too small. All front legs of the sofa should sit on the rug.';
  }
  if (roomLower.contains('kitchen') || roomLower.contains('bathroom')) {
    return 'Kitchens and bathrooms need water-resistant flooring. '
        'Luxury vinyl tile is durable, warm underfoot, and comes '
        'in realistic wood and stone finishes.';
  }
  return 'Engineered wood is more stable than solid wood in UK '
      'homes with underfloor heating or fluctuating humidity.';
}

String _buildSummary({
  required Room room,
  required bool isRenter,
  required int completedCount,
  required int totalCount,
}) {
  if (completedCount == totalCount) {
    return 'Your ${room.name} renovation sequence is complete. '
        'Time to enjoy the space.';
  }
  if (completedCount == 0) {
    return isRenter
        ? 'A step-by-step guide to transforming your ${room.name} '
            'without risking your deposit.'
        : "A professional decorator's order for renovating your "
            '${room.name}, from prep to finishing touches.';
  }
  final remaining = totalCount - completedCount;
  return '$remaining step${remaining == 1 ? '' : 's'} remaining. '
      'You are making good progress on your ${room.name}.';
}

String? _propertyNote(PropertyType? type, PropertyEra? era) {
  if (type == null && era == null) return null;

  final notes = <String>[];

  if (era == PropertyEra.victorian) {
    notes.add(
      'Victorian homes often have high ceilings and original features '
      'like cornicing and fireplaces. Work around these rather than '
      'removing them; they add character and value.',
    );
  } else if (era == PropertyEra.edwardian) {
    notes.add(
      'Edwardian properties typically have generous rooms with good '
      'natural light. Take advantage of this when choosing colours.',
    );
  } else if (era == PropertyEra.thirtiesToFifties) {
    notes.add(
      '1930s and 1940s homes have distinctive features like curved '
      'bay windows and parquet floors. These are worth preserving.',
    );
  } else if (era == PropertyEra.newBuild) {
    notes.add(
      'New builds have smooth, even walls but often lack character. '
      'Texture and colour do the heavy lifting here.',
    );
  }

  if (type == PropertyType.flat) {
    notes.add(
      'In a flat, sound travels. Consider underlay beneath hard '
      'flooring and soft furnishings to absorb noise.',
    );
  } else if (type == PropertyType.terraced) {
    notes.add(
      'Terraced homes are narrower, so use lighter wall colours in '
      'hallways and stairways to keep the flow feeling open.',
    );
  }

  return notes.isEmpty ? null : notes.join(' ');
}
