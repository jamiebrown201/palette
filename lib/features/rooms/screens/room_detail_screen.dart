import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_suggestions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/kelvin_simulation.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/core/widgets/smart_paint_colour_picker.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/onboarding/models/dna_anchors.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/data/room_colour_psychology.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';
import 'package:palette/features/rooms/logic/room_story.dart';
import 'package:palette/features/rooms/logic/seventy_twenty_ten.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));

    return roomAsync.when(
      data: (room) {
        if (room == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Room not found')),
          );
        }
        return _RoomDetailContent(room: room);
      },
      loading:
          () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: $e')),
          ),
    );
  }
}

class _RoomDetailContent extends ConsumerWidget {
  const _RoomDetailContent({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roomModeConfigProvider(room.isRenterMode));

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit room',
            onPressed: () => _showEditRoomSheet(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (room.direction != null)
                  _InfoChip(
                    icon: Icons.explore_outlined,
                    label: '${room.direction!.displayName}-facing',
                  ),
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: room.usageTime.displayName,
                ),
                ...room.moods.map(
                  (m) => _InfoChip(
                    icon: Icons.mood_outlined,
                    label: m.displayName,
                  ),
                ),
                if (config.modeBadge != null)
                  _InfoChip(
                    icon: Icons.vpn_key_outlined,
                    label: config.modeBadge!,
                  ),
              ],
            ),

            // Wall context row (can't-paint renters)
            if (config.showWallAsFixedContext &&
                room.wallColourHex != null) ...[
              const SizedBox(height: 16),
              _WallContextRow(hex: room.wallColourHex!),
            ],

            // Hero colour swatch
            if (room.heroColourHex != null) ...[
              const SizedBox(height: 16),
              _HeroColourSwatch(
                hex: room.heroColourHex!,
                label: config.heroLabel,
              ),
            ],
            const SizedBox(height: 16),

            // Room checklist
            _RoomChecklist(room: room),
            const SizedBox(height: 20),

            // Light direction (compact) — fully premium-gated
            if (room.direction != null) ...[
              PremiumGate(
                requiredTier: SubscriptionTier.plus,
                upgradeMessage: 'See how light affects colour in this room',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Light & Direction'),
                    const SizedBox(height: 8),
                    _LightDirectionCompact(
                      direction: room.direction!,
                      usageTime: room.usageTime,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed:
                          () => context.push(
                            '/explore/white-finder?roomId=${room.id}',
                          ),
                      icon: const Icon(Icons.format_paint_outlined, size: 16),
                      label: Text(config.finderIntro),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PaletteColours.sageGreenDark,
                        side: const BorderSide(color: PaletteColours.sageGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Furniture Lock
            SectionHeader(
              key: _furnitureSectionKey,
              title: 'Existing Furniture',
            ),
            const SizedBox(height: 4),
            Text(
              "Lock items you're keeping so colour suggestions adapt around them.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _FurnitureLockSection(
              roomId: room.id,
              heroColourHex: room.heroColourHex,
            ),
            const SizedBox(height: 24),

            // 70/20/10 Planner
            const SectionHeader(title: '70/20/10 Colour Plan'),
            const SizedBox(height: 8),
            PremiumGate(
              requiredTier: SubscriptionTier.plus,
              upgradeMessage: 'Get a balanced colour plan for this room',
              child: _ColourPlanSection(room: room),
            ),

            // Colour plan harmony insight
            if (room.heroColourHex != null &&
                (room.betaColourHex != null ||
                    room.surpriseColourHex != null)) ...[
              const SizedBox(height: 12),
              _ColourHarmonyInsight(room: room),
            ],

            // Why this room works card
            if (room.heroColourHex != null && room.direction != null)
              _WhyThisRoomWorksCard(room: room),

            // Room colour psychology tip
            _RoomPsychologyTip(roomName: room.name),

            // DNA trim white suggestion
            _TrimWhiteSuggestion(room: room),
            const SizedBox(height: 12),

            // Contextual tool links
            if (room.heroColourHex != null) _ContextualToolLinks(room: room),
            const SizedBox(height: 24),

            // Light simulation
            if (room.heroColourHex != null && room.direction != null) ...[
              const SectionHeader(title: 'Light Simulation'),
              const SizedBox(height: 8),
              _LightSimulation(
                hex: room.heroColourHex!,
                direction: room.direction!,
              ),
              const SizedBox(height: 24),
            ],

            const ColourDisclaimer(),
          ],
        ),
      ),
    );
  }

  void _showEditRoomSheet(BuildContext context, WidgetRef ref) {
    var name = room.name;
    var direction = room.direction;
    var usageTime = room.usageTime;
    var budget = room.budget;
    var isRenterMode = room.isRenterMode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit Room',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Room name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => name = v,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CompassDirection>(
                        value: direction,
                        decoration: const InputDecoration(
                          labelText: 'Window direction',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            CompassDirection.values.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d.displayName),
                              );
                            }).toList(),
                        onChanged: (v) => setSheetState(() => direction = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UsageTime>(
                        value: usageTime,
                        decoration: const InputDecoration(
                          labelText: 'Primary usage time',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            UsageTime.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              );
                            }).toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => usageTime = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BudgetBracket>(
                        value: budget,
                        decoration: const InputDecoration(
                          labelText: 'Budget bracket',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            BudgetBracket.values.map((b) {
                              return DropdownMenuItem(
                                value: b,
                                child: Text(b.displayName),
                              );
                            }).toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => budget = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Renter Mode'),
                        subtitle: const Text(
                          'Focus on furniture and accessories',
                        ),
                        value: isRenterMode,
                        onChanged: (v) => setSheetState(() => isRenterMode = v),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final repo = ref.read(roomRepositoryProvider);
                          await repo.updateRoom(
                            RoomsCompanion(
                              id: Value(room.id),
                              name: Value(name),
                              direction: Value(direction),
                              usageTime: Value(usageTime),
                              moods: Value(room.moods),
                              budget: Value(budget),
                              isRenterMode: Value(isRenterMode),
                              heroColourHex: Value(room.heroColourHex),
                              betaColourHex: Value(room.betaColourHex),
                              surpriseColourHex: Value(room.surpriseColourHex),
                              wallColourHex: Value(room.wallColourHex),
                              sortOrder: Value(room.sortOrder),
                              createdAt: Value(room.createdAt),
                              updatedAt: Value(DateTime.now()),
                            ),
                          );
                          ref
                            ..invalidate(roomByIdProvider(room.id))
                            ..invalidate(allRoomsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

class _HeroColourSwatch extends ConsumerWidget {
  const _HeroColourSwatch({required this.hex, required this.label});

  final String hex;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPaintsAsync = ref.watch(allPaintColoursProvider);
    final paintName = allPaintsAsync.whenOrNull(
      data: (paints) {
        final lab = hexToLab(hex);
        PaintColour? closest;
        var bestDe = 10.0;
        for (final paint in paints) {
          final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
          final dE = deltaE2000(lab, paintLab);
          if (dE < bestDe) {
            bestDe = dE;
            closest = paint;
          }
        }
        return closest?.name;
      },
    );

    final isLight = _isLightColour(hex);
    final fgPrimary = isLight ? Colors.black87 : Colors.white;
    final fgSecondary = isLight ? Colors.black54 : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hexToColor(hex),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.palette, size: 20, color: fgSecondary),
          const SizedBox(width: 8),
          Text(
            paintName ?? hex.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: fgPrimary,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: fgSecondary),
          ),
        ],
      ),
    );
  }
}

class _WallContextRow extends ConsumerWidget {
  const _WallContextRow({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPaintsAsync = ref.watch(allPaintColoursProvider);
    final paintName = allPaintsAsync.whenOrNull(
      data: (paints) {
        final lab = hexToLab(hex);
        PaintColour? closest;
        var bestDe = 10.0;
        for (final paint in paints) {
          final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
          final dE = deltaE2000(lab, paintLab);
          if (dE < bestDe) {
            bestDe = dE;
            closest = paint;
          }
        }
        return closest?.name;
      },
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PaletteColours.divider),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your walls \u00b7 ${paintName ?? hex.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
          ),
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: PaletteColours.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PaletteColours.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: PaletteColours.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _LightDirectionCompact extends StatelessWidget {
  const _LightDirectionCompact({
    required this.direction,
    required this.usageTime,
  });

  final CompassDirection direction;
  final UsageTime usageTime;

  @override
  Widget build(BuildContext context) {
    final summary = getLightDirectionSummary(direction);
    final rec = getLightRecommendation(
      direction: direction,
      usageTime: usageTime,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                size: 18,
                color: PaletteColours.softGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _UndertoneChip(
                label: 'Prefer: ${rec.preferredUndertone.displayName}',
                isPositive: true,
              ),
              if (rec.avoidUndertone != null)
                _UndertoneChip(
                  label: 'Avoid: ${rec.avoidUndertone!.displayName}',
                  isPositive: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UndertoneChip extends StatelessWidget {
  const _UndertoneChip({required this.label, required this.isPositive});

  final String label;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isPositive
                ? PaletteColours.sageGreenLight
                : PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              isPositive
                  ? PaletteColours.sageGreenDark
                  : PaletteColours.textSecondary,
        ),
      ),
    );
  }
}

class _ColourHarmonyInsight extends StatelessWidget {
  const _ColourHarmonyInsight({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final harmony = analyseColourPlanHarmony(
      heroHex: room.heroColourHex!,
      betaHex: room.betaColourHex,
      surpriseHex: room.surpriseColourHex,
    );

    final hasWarning = harmony.hasWarning;
    final bgColor =
        hasWarning
            ? PaletteColours.softGoldLight
            : PaletteColours.sageGreenLight;
    final fgColor =
        hasWarning ? PaletteColours.softGoldDark : PaletteColours.sageGreenDark;
    final icon = hasWarning ? Icons.lightbulb_outline : Icons.auto_awesome;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Text(
                harmony.verdict,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            harmony.explanation,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: fgColor),
          ),
          if (harmony.warning != null) ...[
            const SizedBox(height: 6),
            Text(
              harmony.warning!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.softGoldDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColourPlanSection extends ConsumerWidget {
  const _ColourPlanSection({required this.room});

  final Room room;

  String? _lookupPaintName(List<PaintColour>? allPaints, String? hex) {
    if (allPaints == null || hex == null) return null;
    final lab = hexToLab(hex);
    PaintColour? closest;
    var bestDe = 10.0;
    for (final paint in allPaints) {
      final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
      final dE = deltaE2000(lab, paintLab);
      if (dE < bestDe) {
        bestDe = dE;
        closest = paint;
      }
    }
    return closest?.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roomModeConfigProvider(room.isRenterMode));
    final hasHero = room.heroColourHex != null;
    final allPaints = ref
        .watch(allPaintColoursProvider)
        .whenOrNull(data: (p) => p);

    return Column(
      children: [
        if (!hasHero) ...[
          Text(
            config.heroPrompt,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          if (config.showLandlordPresets) ...[
            const SizedBox(height: 12),
            Text(
              'Common landlord colours',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _landlordPresets.map((preset) {
                    return _LandlordPresetChip(
                      label: preset.name,
                      hex: preset.hex,
                      onTap:
                          () => _applyLandlordPreset(context, ref, preset.hex),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showHeroColourPicker(context, ref),
            icon: const Icon(Icons.palette_outlined, size: 18),
            label: Text(config.heroButtonLabel),
          ),
        ] else ...[
          _ColourTierRow(
            label: config.heroLabel,
            description: config.heroDescription,
            hex: room.heroColourHex,
            paintName: _lookupPaintName(allPaints, room.heroColourHex),
            onTap: () => _showHeroColourPicker(context, ref),
          ),
          const SizedBox(height: 8),
          _ColourTierRow(
            label: config.betaLabel,
            description: config.betaDescription,
            hex: room.betaColourHex,
            paintName: _lookupPaintName(allPaints, room.betaColourHex),
            onTap: () => _showSwapPicker(context, ref, 'beta'),
          ),
          const SizedBox(height: 8),
          _ColourTierRow(
            label: config.surpriseLabel,
            description: config.surpriseDescription,
            hex: room.surpriseColourHex,
            paintName: _lookupPaintName(allPaints, room.surpriseColourHex),
            onTap: () => _showSwapPicker(context, ref, 'surprise'),
          ),
          _DashColourRow(room: room),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _regeneratePlan(context, ref),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Regenerate suggestions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletteColours.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  static const _landlordPresets = [
    (name: 'Magnolia', hex: '#F5E6CC'),
    (name: 'Brilliant White', hex: '#FAFAFA'),
    (name: 'Jasmine White', hex: '#F8F0E3'),
    (name: 'Cotton White', hex: '#F5F2EA'),
    (name: 'Barley White', hex: '#F0E8D0'),
  ];

  Future<void> _applyLandlordPreset(
    BuildContext context,
    WidgetRef ref,
    String hex,
  ) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    final dnaResult = await ref.read(latestColourDnaProvider.future);

    // Find the closest real paint to the preset
    final heroPaint =
        allPaints.map((p) {
            final lab = hexToLab(hex);
            final pLab = LabColour(p.labL, p.labA, p.labB);
            return (paint: p, dE: deltaE2000(lab, pLab));
          }).toList()
          ..sort((a, b) => a.dE.compareTo(b.dE));

    if (heroPaint.isEmpty) return;
    final selected = heroPaint.first.paint;

    final furniture = await ref.read(furnitureForRoomProvider(room.id).future);
    final redThreadHexes = await ref.read(threadHexesProvider.future);

    final plan = generateColourPlan(
      heroColour: selected,
      allPaintColours: allPaints,
      direction: room.direction,
      usageTime: room.usageTime,
      redThreadHexes: redThreadHexes,
      lockedFurniture: furniture,
      budget: room.budget,
      dnaUndertone: dnaResult?.undertoneTemperature,
    );

    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoom(
      RoomsCompanion(
        id: Value(room.id),
        name: Value(room.name),
        direction: Value(room.direction),
        usageTime: Value(room.usageTime),
        moods: Value(room.moods),
        budget: Value(room.budget),
        isRenterMode: Value(room.isRenterMode),
        heroColourHex: Value(selected.hex),
        betaColourHex: Value(plan?.betaColour.hex),
        surpriseColourHex: Value(plan?.surpriseColour.hex),
        wallColourHex: Value(selected.hex),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref
      ..invalidate(roomByIdProvider(room.id))
      ..invalidate(allRoomsProvider);

    // Log interaction: hero selected (landlord preset)
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: _uuid.v4(),
          interactionType: 'heroSelected',
          hex: selected.hex,
          contextScreen: 'planner',
          paintId: selected.id,
          contextRoomId: room.id,
        );

    if (plan != null && plan.warnings.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(plan.warnings.first)));
    }
  }

  Future<void> _showHeroColourPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    final dnaResult = await ref.read(latestColourDnaProvider.future);
    final redThreadHexList = await ref.read(threadHexesProvider.future);

    if (!context.mounted) return;

    // Build DNA anchors from system palette if available
    DnaAnchors? dnaAnchors;
    if (dnaResult?.systemPaletteJson != null) {
      final palette = SystemPalette.fromJson(dnaResult!.systemPaletteJson!);
      dnaAnchors = DnaAnchors.fromSystemPalette(palette);
    }

    final suggestions = generateSuggestions(
      context: PickerContext(
        pickerRole: PickerRole.hero,
        direction: room.direction,
        usageTime: room.usageTime,
        budget: room.budget,
        moods: room.moods,
        dnaHexes: dnaResult?.colourHexes ?? [],
        redThreadHexes: redThreadHexList,
        undertoneTemperature: dnaResult?.undertoneTemperature,
        dnaAnchors: dnaAnchors,
      ),
      allPaints: allPaints,
    );

    final config = ref.read(roomModeConfigProvider(room.isRenterMode));
    final selected = await showModalBottomSheet<PaintColour>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => SmartPaintColourPicker(
            title: config.heroButtonLabel,
            paintColours: allPaints,
            suggestions: suggestions,
          ),
    );

    if (selected == null || !context.mounted) return;

    // Fetch furniture and red thread data for the algorithm
    final furniture = await ref.read(furnitureForRoomProvider(room.id).future);
    final redThreadHexes = await ref.read(threadHexesProvider.future);

    // Generate full plan from hero
    final plan = generateColourPlan(
      heroColour: selected,
      allPaintColours: allPaints,
      direction: room.direction,
      usageTime: room.usageTime,
      redThreadHexes: redThreadHexes,
      lockedFurniture: furniture,
      budget: room.budget,
      dnaUndertone: dnaResult?.undertoneTemperature,
    );

    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoom(
      RoomsCompanion(
        id: Value(room.id),
        name: Value(room.name),
        direction: Value(room.direction),
        usageTime: Value(room.usageTime),
        moods: Value(room.moods),
        budget: Value(room.budget),
        isRenterMode: Value(room.isRenterMode),
        heroColourHex: Value(selected.hex),
        betaColourHex: Value(plan?.betaColour.hex),
        surpriseColourHex: Value(plan?.surpriseColour.hex),
        wallColourHex: Value(
          room.isRenterMode ? selected.hex : room.wallColourHex,
        ),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref
      ..invalidate(roomByIdProvider(room.id))
      ..invalidate(allRoomsProvider);

    // Log interaction: hero selected
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: _uuid.v4(),
          interactionType: 'heroSelected',
          hex: selected.hex,
          contextScreen: 'planner',
          paintId: selected.id,
          contextRoomId: room.id,
        );

    if (plan != null && plan.warnings.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(plan.warnings.first)));
    }
  }

  Future<void> _showSwapPicker(
    BuildContext context,
    WidgetRef ref,
    String tier,
  ) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);

    if (!context.mounted) return;

    final pickerRole = tier == 'beta' ? PickerRole.beta : PickerRole.surprise;
    final suggestions = generateSuggestions(
      context: PickerContext(
        pickerRole: pickerRole,
        heroColourHex: room.heroColourHex,
        betaColourHex: room.betaColourHex,
        direction: room.direction,
        usageTime: room.usageTime,
        budget: room.budget,
        moods: room.moods,
      ),
      allPaints: allPaints,
    );

    // Build context banner describing current colour's relationship to hero
    String? banner;
    final currentHex =
        tier == 'beta' ? room.betaColourHex : room.surpriseColourHex;
    if (currentHex != null && room.heroColourHex != null) {
      final heroLab = hexToLab(room.heroColourHex!);
      final currentLab = hexToLab(currentHex);
      final rel = classifyHuePair(heroLab, currentLab);
      final tierName = tier == 'beta' ? 'supporting' : 'accent';
      banner = switch (rel) {
        ColourRelationship.complementary =>
          'Your current $tierName is complementary to the hero — they create vibrant contrast.',
        ColourRelationship.analogous =>
          'Your current $tierName is analogous to the hero — they harmonise naturally.',
        ColourRelationship.triadic =>
          'Your current $tierName forms a triadic relationship with the hero — balanced vibrancy.',
        ColourRelationship.splitComplementary =>
          'Your current $tierName is split-complementary to the hero — softer contrast.',
        null =>
          'Your current $tierName creates a bold, eclectic pairing with the hero.',
      };
    }

    final selected = await showModalBottomSheet<PaintColour>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => SmartPaintColourPicker(
            title:
                'Swap ${tier == 'beta' ? 'Supporting (20%)' : 'Surprise (10%)'} colour',
            paintColours: allPaints,
            suggestions: suggestions,
            contextBanner: banner,
          ),
    );

    if (selected == null || !context.mounted) return;

    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoom(
      RoomsCompanion(
        id: Value(room.id),
        name: Value(room.name),
        direction: Value(room.direction),
        usageTime: Value(room.usageTime),
        moods: Value(room.moods),
        budget: Value(room.budget),
        isRenterMode: Value(room.isRenterMode),
        heroColourHex: Value(room.heroColourHex),
        betaColourHex: Value(
          tier == 'beta' ? selected.hex : room.betaColourHex,
        ),
        surpriseColourHex: Value(
          tier == 'surprise' ? selected.hex : room.surpriseColourHex,
        ),
        wallColourHex: Value(room.wallColourHex),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref.invalidate(roomByIdProvider(room.id));

    // Log interaction: colour swapped
    final previousHex =
        tier == 'beta' ? room.betaColourHex : room.surpriseColourHex;
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: _uuid.v4(),
          interactionType: 'colourSwapped',
          hex: selected.hex,
          contextScreen: 'planner',
          paintId: selected.id,
          contextRoomId: room.id,
          previousHex: previousHex,
        );
  }

  Future<void> _regeneratePlan(BuildContext context, WidgetRef ref) async {
    if (room.heroColourHex == null) return;

    final allPaints = await ref.read(allPaintColoursProvider.future);
    final dnaResult = await ref.read(latestColourDnaProvider.future);
    final heroPaint = allPaints.firstWhere(
      (p) => p.hex.toLowerCase() == room.heroColourHex!.toLowerCase(),
      orElse: () => allPaints.first,
    );

    // Fetch furniture and red thread data for the algorithm
    final furniture = await ref.read(furnitureForRoomProvider(room.id).future);
    final redThreadHexes = await ref.read(threadHexesProvider.future);

    final plan = generateColourPlan(
      heroColour: heroPaint,
      allPaintColours: allPaints,
      direction: room.direction,
      usageTime: room.usageTime,
      redThreadHexes: redThreadHexes,
      lockedFurniture: furniture,
      budget: room.budget,
      dnaUndertone: dnaResult?.undertoneTemperature,
    );

    if (plan == null) return;

    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoom(
      RoomsCompanion(
        id: Value(room.id),
        name: Value(room.name),
        direction: Value(room.direction),
        usageTime: Value(room.usageTime),
        moods: Value(room.moods),
        budget: Value(room.budget),
        isRenterMode: Value(room.isRenterMode),
        heroColourHex: Value(plan.heroColour.hex),
        betaColourHex: Value(plan.betaColour.hex),
        surpriseColourHex: Value(plan.surpriseColour.hex),
        wallColourHex: Value(room.wallColourHex),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref.invalidate(roomByIdProvider(room.id));
    if (plan.warnings.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(plan.warnings.first)));
    }
  }
}

class _ColourTierRow extends StatelessWidget {
  const _ColourTierRow({
    required this.label,
    required this.description,
    this.hex,
    this.paintName,
    this.onTap,
  });

  final String label;
  final String description;
  final String? hex;
  final String? paintName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletteColours.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PaletteColours.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      hex != null ? _hexToColor(hex!) : PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
                child:
                    hex == null
                        ? const Icon(
                          Icons.add,
                          color: PaletteColours.textTertiary,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hex != null && (paintName != null)
                          ? '$description \u2022 $paintName'
                          : description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: PaletteColours.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomPsychologyTip extends StatelessWidget {
  const _RoomPsychologyTip({required this.roomName});

  final String roomName;

  @override
  Widget build(BuildContext context) {
    final guidance = getGuidanceForRoom(roomName);
    if (guidance == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PaletteColours.softCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 16,
                  color: PaletteColours.sageGreenDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'Colour psychology',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: PaletteColours.sageGreenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              guidance.insight,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              guidance.avoid,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrimWhiteSuggestion extends ConsumerWidget {
  const _TrimWhiteSuggestion({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (room.heroColourHex == null) return const SizedBox.shrink();

    final dnaAsync = ref.watch(latestColourDnaProvider);

    return dnaAsync.when(
      data: (dnaResult) {
        if (dnaResult?.systemPaletteJson == null) {
          return const SizedBox.shrink();
        }

        final palette = SystemPalette.fromJson(dnaResult!.systemPaletteJson!);
        final trim = palette.trimWhite;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hexToColor(trim.hex),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PaletteColours.divider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested trim white',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${trim.name} by ${trim.brand}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LightSimulation extends StatelessWidget {
  const _LightSimulation({required this.hex, required this.direction});

  final String hex;
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    final morningHex = simulateLightOnColour(
      hex,
      getKelvinForRoom(direction, UsageTime.morning),
    );
    final middayHex = simulateLightOnColour(
      hex,
      getKelvinForRoom(direction, UsageTime.afternoon),
    );
    final eveningHex = simulateLightOnColour(
      hex,
      getKelvinForRoom(direction, UsageTime.evening),
    );

    return Row(
      children: [
        _LightSwatchColumn(label: 'Morning', hex: morningHex),
        const SizedBox(width: 8),
        _LightSwatchColumn(label: 'Midday', hex: middayHex),
        const SizedBox(width: 8),
        _LightSwatchColumn(label: 'Evening', hex: eveningHex),
      ],
    );
  }
}

class _LightSwatchColumn extends StatelessWidget {
  const _LightSwatchColumn({required this.label, required this.hex});

  final String label;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final isLight = _isLightColour(hex);
    return Expanded(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: _hexToColor(hex),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaletteColours.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isLight ? Colors.black54 : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FurnitureLockSection extends ConsumerWidget {
  const _FurnitureLockSection({required this.roomId, this.heroColourHex});

  final String roomId;
  final String? heroColourHex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furnitureAsync = ref.watch(furnitureForRoomProvider(roomId));

    return furnitureAsync.when(
      data: (items) {
        return Column(
          children: [
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hexToColor(item.colourHex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PaletteColours.divider),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            item.role.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        final repo = ref.read(roomRepositoryProvider);
                        await repo.deleteFurniture(item.id);
                        ref.invalidate(furnitureForRoomProvider(roomId));
                      },
                    ),
                  ],
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => _showAddFurnitureDialog(context, ref, items.length),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Lock existing furniture'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.textSecondary,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static const _commonColours = {
    'White': '#FFFFFF',
    'Cream': '#FFFDD0',
    'Beige': '#F5F5DC',
    'Light Grey': '#D3D3D3',
    'Dark Grey': '#505050',
    'Black': '#1A1A1A',
    'Brown': '#8B4513',
    'Tan': '#D2B48C',
    'Navy': '#1B2A4A',
    'Olive': '#556B2F',
    'Burgundy': '#722F37',
    'Terracotta': '#CC6644',
  };

  void _showAddFurnitureDialog(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) {
    final nameController = TextEditingController();
    var selectedHex = '#D3D3D3';
    var role = FurnitureRole.beta;

    showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Lock Furniture'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          hintText: 'e.g. Brown leather sofa',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Approximate colour',
                          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _commonColours.entries.map((e) {
                              final isSelected = selectedHex == e.value;
                              return GestureDetector(
                                onTap:
                                    () => setDialogState(
                                      () => selectedHex = e.value,
                                    ),
                                child: Tooltip(
                                  message: e.key,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _hexToColor(e.value),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? PaletteColours.sageGreen
                                                : PaletteColours.divider,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? Icon(
                                              Icons.check,
                                              size: 16,
                                              color:
                                                  _isLightColour(e.value)
                                                      ? PaletteColours
                                                          .textPrimary
                                                      : Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final allPaints = await ref.read(
                            allPaintColoursProvider.future,
                          );
                          if (!ctx.mounted) return;
                          final picked =
                              await showModalBottomSheet<PaintColour>(
                                context: ctx,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder:
                                    (_) => SmartPaintColourPicker(
                                      title: 'Find exact colour',
                                      paintColours: allPaints,
                                    ),
                              );
                          if (picked != null) {
                            setDialogState(() => selectedHex = picked.hex);
                          }
                        },
                        icon: const Icon(Icons.palette_outlined, size: 16),
                        label: const Text('Find exact colour'),
                        style: TextButton.styleFrom(
                          foregroundColor: PaletteColours.sageGreenDark,
                        ),
                      ),
                      // Colour relationship hint
                      if (heroColourHex != null) ...[
                        Builder(
                          builder: (ctx) {
                            final heroLab = hexToLab(heroColourHex!);
                            final furnitureLab = hexToLab(selectedHex);
                            final dE = deltaE2000(heroLab, furnitureLab);
                            final hint =
                                dE < 5
                                    ? 'Very close to your hero — will blend in'
                                    : dE < 20
                                    ? 'Tonal variation — cohesive and calm'
                                    : dE > 45
                                    ? 'High contrast — will stand out boldly'
                                    : 'Moderate contrast with your hero';
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: PaletteColours.sageGreenDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hint,
                                      style: Theme.of(
                                        ctx,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: PaletteColours.sageGreenDark,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<FurnitureRole>(
                        value: role,
                        decoration: InputDecoration(
                          labelText: 'Role in room',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            FurnitureRole.values.map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName),
                              );
                            }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => role = v);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final repo = ref.read(roomRepositoryProvider);
                        await repo.insertFurniture(
                          LockedFurnitureItemsCompanion.insert(
                            id: const Uuid().v4(),
                            roomId: roomId,
                            name: name,
                            colourHex: selectedHex,
                            role: role,
                            sortOrder: currentCount,
                          ),
                        );
                        ref.invalidate(furnitureForRoomProvider(roomId));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Lock'),
                    ),
                  ],
                ),
          ),
    );
  }
}

class _DashColourRow extends ConsumerWidget {
  const _DashColourRow({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadHexesAsync = ref.watch(threadHexesProvider);

    return threadHexesAsync.when(
      data: (threadHexes) {
        if (threadHexes.isEmpty) return const SizedBox.shrink();

        final allPaintsAsync = ref.watch(allPaintColoursProvider);
        return allPaintsAsync.when(
          data: (allPaints) {
            final excludeHexes =
                {
                  room.heroColourHex,
                  room.betaColourHex,
                  room.surpriseColourHex,
                }.whereType<String>().toSet();

            // Find the closest paint to any thread hex, excluding plan colours
            PaintColour? dashPaint;
            var bestDeltaE = double.infinity;
            for (final threadHex in threadHexes) {
              final threadLab = hexToLab(threadHex);
              for (final pc in allPaints) {
                if (excludeHexes.contains(pc.hex)) continue;
                final lab = LabColour(pc.labL, pc.labA, pc.labB);
                final dE = deltaE2000(threadLab, lab);
                if (dE < bestDeltaE) {
                  bestDeltaE = dE;
                  dashPaint = pc;
                }
              }
            }

            if (dashPaint == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ColourTierRow(
                label: 'Dash',
                description: 'Red thread tie-in',
                hex: dashPaint.hex,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LandlordPresetChip extends StatelessWidget {
  const _LandlordPresetChip({
    required this.label,
    required this.hex,
    required this.onTap,
  });

  final String label;
  final String hex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _hexToColor(hex),
          shape: BoxShape.circle,
          border: Border.all(color: PaletteColours.divider),
        ),
      ),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

final _furnitureSectionKey = GlobalKey();

bool _isLightColour(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse(cleaned, radix: 16);
  final r = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final b = value & 0xFF;
  return (0.299 * r + 0.587 * g + 0.114 * b) > 160;
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

// ---------------------------------------------------------------------------
// Room Checklist
// ---------------------------------------------------------------------------

class _RoomChecklist extends ConsumerWidget {
  const _RoomChecklist({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roomModeConfigProvider(room.isRenterMode));
    final furnitureAsync = ref.watch(furnitureForRoomProvider(room.id));
    final coherenceAsync = ref.watch(coherenceReportProvider);

    final hasFurniture = furnitureAsync.when(
      data: (items) => items.isNotEmpty,
      loading: () => false,
      error: (_, __) => false,
    );
    final hasRedThread = coherenceAsync.when(
      data:
          (report) =>
              report.results.any((r) => r.roomId == room.id && r.isConnected),
      loading: () => false,
      error: (_, __) => false,
    );

    final items = [
      _ChecklistItem(
        label: 'Direction set',
        done: room.direction != null,
        actionLabel: 'Set',
        onAction: () => _showEditRoomSheet(context, ref),
      ),
      _ChecklistItem(
        label: 'Mood selected',
        done: room.moods.isNotEmpty,
        actionLabel: 'Set',
        onAction: () => _showEditRoomSheet(context, ref),
      ),
      _ChecklistItem(
        label: config.checklistHeroLabel,
        done: room.heroColourHex != null,
      ),
      _ChecklistItem(
        label: config.checklistPlanLabel,
        done: room.betaColourHex != null && room.surpriseColourHex != null,
      ),
      _ChecklistItem(
        label: config.checklistWhiteLabel,
        done: false,
        actionLabel: config.checklistWhiteAction,
        onAction: () => context.push('/explore/white-finder?roomId=${room.id}'),
        isInformational: true,
      ),
      _ChecklistItem(
        label: 'Furniture locked',
        done: hasFurniture,
        actionLabel: 'Lock',
        onAction: () {
          final ctx = _furnitureSectionKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
      ),
      _ChecklistItem(
        label: 'Red Thread connected',
        done: hasRedThread,
        actionLabel: 'Connect',
        onAction: () => context.push('/red-thread'),
      ),
    ];

    final completed = items.where((i) => i.done).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Room checklist',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '$completed/${items.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: completed / items.length,
              minHeight: 6,
              backgroundColor: PaletteColours.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                PaletteColours.sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildChecklistRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(BuildContext context, _ChecklistItem item) {
    final icon =
        item.done
            ? const Icon(
              Icons.check_circle,
              size: 18,
              color: PaletteColours.sageGreen,
            )
            : const Icon(
              Icons.circle_outlined,
              size: 18,
              color: PaletteColours.textTertiary,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    item.done
                        ? PaletteColours.textPrimary
                        : PaletteColours.textSecondary,
              ),
            ),
          ),
          if (!item.done && item.actionLabel != null && item.onAction != null)
            GestureDetector(
              onTap: item.onAction,
              child: Text(
                item.actionLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.sageGreenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditRoomSheet(BuildContext context, WidgetRef ref) {
    _showRoomEditSheet(context, ref, room);
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.label,
    required this.done,
    this.actionLabel,
    this.onAction,
    this.isInformational = false,
  });

  final String label;
  final bool done;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isInformational;
}

// ---------------------------------------------------------------------------
// Why This Room Works Card
// ---------------------------------------------------------------------------

class _WhyThisRoomWorksCard extends ConsumerWidget {
  const _WhyThisRoomWorksCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roomModeConfigProvider(room.isRenterMode));
    final allPaintsAsync = ref.watch(allPaintColoursProvider);
    final heroName = allPaintsAsync.when(
      data: (paints) => _findPaintName(paints, room.heroColourHex!),
      loading: () => null,
      error: (_, __) => null,
    );

    final story = generateRoomStory(
      roomName: room.name,
      direction: room.direction,
      usageTime: room.usageTime,
      moods: room.moods,
      heroHex: room.heroColourHex,
      betaHex: room.betaColourHex,
      surpriseHex: room.surpriseColourHex,
      isRenterMode: room.isRenterMode,
      heroName: heroName,
      renterMoodTemplate: config.moodSentenceTemplate,
    );

    if (story.summary.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.sageGreenLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: PaletteColours.sageGreenDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'Why this works',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: PaletteColours.sageGreenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              story.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _findPaintName(List<PaintColour> paints, String hex) {
    final lab = hexToLab(hex);
    PaintColour? closest;
    var bestDe = 10.0;
    for (final paint in paints) {
      final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
      final dE = deltaE2000(lab, paintLab);
      if (dE < bestDe) {
        bestDe = dE;
        closest = paint;
      }
    }
    return closest?.name;
  }
}

// ---------------------------------------------------------------------------
// Contextual Tool Links
// ---------------------------------------------------------------------------

class _ContextualToolLinks extends StatelessWidget {
  const _ContextualToolLinks({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push('/red-thread'),
      icon: const Icon(Icons.hub_outlined, size: 16),
      label: const Text('Check whole-home coherence'),
      style: OutlinedButton.styleFrom(
        foregroundColor: PaletteColours.sageGreenDark,
        side: const BorderSide(color: PaletteColours.sageGreen),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared edit sheet (used by checklist)
// ---------------------------------------------------------------------------

void _showRoomEditSheet(BuildContext context, WidgetRef ref, Room room) {
  var name = room.name;
  var direction = room.direction;
  var usageTime = room.usageTime;
  var budget = room.budget;
  var isRenterMode = room.isRenterMode;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Room',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Room name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CompassDirection>(
                      value: direction,
                      decoration: const InputDecoration(
                        labelText: 'Window direction',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          CompassDirection.values.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d.displayName),
                            );
                          }).toList(),
                      onChanged: (v) => setSheetState(() => direction = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UsageTime>(
                      value: usageTime,
                      decoration: const InputDecoration(
                        labelText: 'Primary usage time',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          UsageTime.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            );
                          }).toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => usageTime = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BudgetBracket>(
                      value: budget,
                      decoration: const InputDecoration(
                        labelText: 'Budget bracket',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          BudgetBracket.values.map((b) {
                            return DropdownMenuItem(
                              value: b,
                              child: Text(b.displayName),
                            );
                          }).toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => budget = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Renter Mode'),
                      subtitle: const Text(
                        'Focus on furniture and accessories',
                      ),
                      value: isRenterMode,
                      onChanged: (v) => setSheetState(() => isRenterMode = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final repo = ref.read(roomRepositoryProvider);
                        await repo.updateRoom(
                          RoomsCompanion(
                            id: Value(room.id),
                            name: Value(name),
                            direction: Value(direction),
                            usageTime: Value(usageTime),
                            moods: Value(room.moods),
                            budget: Value(budget),
                            isRenterMode: Value(isRenterMode),
                            updatedAt: Value(DateTime.now()),
                          ),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
        ),
  );
}
