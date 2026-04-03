import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_suggestions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/kelvin_simulation.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/constants/room_mode_config.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/core/widgets/smart_paint_colour_picker.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/onboarding/models/dna_anchors.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/data/room_colour_psychology.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';
import 'package:palette/features/rooms/logic/paint_finish_recommender.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';
import 'package:palette/features/rooms/logic/room_paint_recommendations.dart';
import 'package:palette/features/rooms/logic/room_story.dart';
import 'package:palette/features/rooms/logic/seventy_twenty_ten.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/shopping_list/providers/shopping_list_providers.dart';
import 'package:palette/features/visualiser/providers/visualiser_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:url_launcher/url_launcher.dart';
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
      error: (e, _) => Scaffold(appBar: AppBar(), body: const ErrorCard()),
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
                if (room.roomSize != null)
                  _InfoChip(
                    icon: Icons.square_foot_outlined,
                    label: room.roomSize!.displayName,
                  ),
                if (config.modeBadge != null)
                  _InfoChip(
                    icon: Icons.vpn_key_outlined,
                    label: config.modeBadge!,
                  ),
              ],
            ),

            // "Why This Room Works" card — spec position #2
            if (room.heroColourHex != null && room.direction != null) ...[
              const SizedBox(height: 16),
              _WhyThisRoomWorksCard(room: room),
            ],

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
            const SizedBox(height: 12),

            // Moodboard quick link
            OutlinedButton.icon(
              onPressed: () => context.push('/moodboards?roomId=${room.id}'),
              icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
              label: const Text('Room moodboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.sageGreenDark,
                side: const BorderSide(color: PaletteColours.sageGreen),
              ),
            ),
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

            // Lighting Planner CTA (Phase 4)
            OutlinedButton.icon(
              onPressed:
                  () => context.push('/lighting-planner?roomId=${room.id}'),
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: const Text('Lighting Planner'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.softGoldDark,
                side: const BorderSide(color: PaletteColours.softGold),
              ),
            ),
            const SizedBox(height: 8),

            // Room Audit CTA (Phase 4)
            OutlinedButton.icon(
              onPressed: () => context.push('/room-audit?roomId=${room.id}'),
              icon: const Icon(Icons.checklist_outlined, size: 16),
              label: const Text('Room Audit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.softGoldDark,
                side: const BorderSide(color: PaletteColours.softGold),
              ),
            ),
            const SizedBox(height: 8),

            // Renovation Guide CTA (Phase 4)
            OutlinedButton.icon(
              onPressed:
                  () => context.push('/renovation-guide?roomId=${room.id}'),
              icon: const Icon(Icons.format_list_numbered, size: 16),
              label: const Text('Renovation Guide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.softGoldDark,
                side: const BorderSide(color: PaletteColours.softGold),
              ),
            ),
            const SizedBox(height: 8),

            // Design Diary CTA (Phase 4)
            OutlinedButton.icon(
              onPressed: () => context.push('/design-diary?roomId=${room.id}'),
              icon: const Icon(Icons.auto_stories_outlined, size: 16),
              label: const Text('Design Diary'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.softGoldDark,
                side: const BorderSide(color: PaletteColours.softGold),
              ),
            ),
            const SizedBox(height: 20),

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
            const SectionHeader(
              title: '${BrandedTerms.seventyTwentyTen} Colour Plan',
              subtitle: BrandedTerms.seventyTwentyTenSubtitle,
            ),
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

            // Room Preview colour-block mockup
            if (room.heroColourHex != null &&
                room.betaColourHex != null &&
                room.surpriseColourHex != null) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Room Preview'),
              const SizedBox(height: 4),
              Text(
                "Your room's colour balance",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _RoomPreviewMockup(room: room),
              const SizedBox(height: 12),
              _VisualiserCta(room: room),
              const SizedBox(height: 12),
              _AssistantCta(room: room),
            ],

            // Paint recommendations for this room
            if (room.heroColourHex != null) ...[
              const SizedBox(height: 24),
              _PaintRecommendationsSection(room: room),
            ],

            // Paint & Finish Recommender (Phase 2B.3)
            // Show for owners and renters who can paint; explain to
            // renters who can't paint why the section isn't available.
            if (room.heroColourHex != null) ...[
              if (config != RoomModeConfig.renterCantPaint) ...[
                const SizedBox(height: 24),
                _PaintFinishSection(room: room),
              ] else ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PaletteColours.warmGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: PaletteColours.textTertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Paint & finish recommendations are hidden '
                          'because painting isn\u2019t an option in this rental. '
                          'Consider peel-and-stick or removable wallpaper instead.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PaletteColours.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Room gap analysis — "What this room still needs"
            if (room.heroColourHex != null &&
                room.betaColourHex != null &&
                room.surpriseColourHex != null) ...[
              const SizedBox(height: 24),
              _RoomGapSection(roomId: room.id),
            ],

            // "Complete the Room" product recommendations (Pro)
            if (room.heroColourHex != null &&
                room.betaColourHex != null &&
                room.surpriseColourHex != null) ...[
              const SizedBox(height: 24),
              PremiumGate(
                requiredTier: SubscriptionTier.pro,
                upgradeMessage:
                    'Get personalised product recommendations for every room',
                child: _ProductRecommendationsSection(
                  roomId: room.id,
                  roomName: room.name,
                ),
              ),
            ],

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
              const SectionHeader(
                title: 'Light Simulation',
                subtitle: 'A helpful preview — not a photorealistic simulation',
              ),
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
    var roomSize = room.roomSize;
    final widthCtrl = TextEditingController(
      text: room.widthMetres?.toStringAsFixed(1) ?? '',
    );
    final lengthCtrl = TextEditingController(
      text: room.lengthMetres?.toStringAsFixed(1) ?? '',
    );

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
                  child: SingleChildScrollView(
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
                        DropdownButtonFormField<RoomSize>(
                          value: roomSize,
                          decoration: const InputDecoration(
                            labelText: 'Room size',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              RoomSize.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                );
                              }).toList(),
                          onChanged: (v) => setSheetState(() => roomSize = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: widthCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Width (m)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: lengthCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Length (m)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
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
                          onChanged:
                              (v) => setSheetState(() => isRenterMode = v),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            if (name.trim().isEmpty) return;
                            final repo = ref.read(roomRepositoryProvider);
                            final width = double.tryParse(widthCtrl.text);
                            final length = double.tryParse(lengthCtrl.text);
                            await repo.updateRoom(
                              RoomsCompanion(
                                id: Value(room.id),
                                name: Value(name),
                                direction: Value(direction),
                                usageTime: Value(usageTime),
                                moods: Value(room.moods),
                                budget: Value(budget),
                                isRenterMode: Value(isRenterMode),
                                roomSize: Value(roomSize),
                                widthMetres: Value(width),
                                lengthMetres: Value(length),
                                heroColourHex: Value(room.heroColourHex),
                                betaColourHex: Value(room.betaColourHex),
                                surpriseColourHex: Value(
                                  room.surpriseColourHex,
                                ),
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
        color: hexToColor(hex),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: fgSecondary),
              ),
              Text(
                BrandedTerms.heroColourSubtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fgSecondary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
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
              color: hexToColor(hex),
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

/// Colour-blocked room preview showing the 70/20/10 proportions
/// using the actual selected colours. Addresses the Visualisation Gap.
class _RoomPreviewMockup extends ConsumerWidget {
  const _RoomPreviewMockup({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roomModeConfigProvider(room.isRenterMode));
    final heroHex = room.heroColourHex!;
    final betaHex = room.betaColourHex!;
    final surpriseHex = room.surpriseColourHex!;

    // Check for a dash/thread colour
    final threadHexesAsync = ref.watch(threadHexesProvider);
    final dashHex = threadHexesAsync.whenOrNull(
      data: (hexes) => hexes.isNotEmpty ? hexes.first : null,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletteColours.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 70% Hero band
          _PreviewBand(
            hex: heroHex,
            label: config.previewHeroLabel,
            proportion: '70%',
            height: 100,
          ),
          // 20% Beta band
          _PreviewBand(
            hex: betaHex,
            label: config.previewBetaLabel,
            proportion: '20%',
            height: 56,
          ),
          // 10% Surprise band
          _PreviewBand(
            hex: surpriseHex,
            label: config.previewSurpriseLabel,
            proportion: '10%',
            height: 36,
          ),
          // Optional dash line for Red Thread
          if (dashHex != null) Container(height: 6, color: hexToColor(dashHex)),
        ],
      ),
    );
  }
}

class _PreviewBand extends StatelessWidget {
  const _PreviewBand({
    required this.hex,
    required this.label,
    required this.proportion,
    required this.height,
  });

  final String hex;
  final String label;
  final String proportion;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colour = hexToColor(hex);
    // Use white or dark text depending on luminance
    final textColour =
        colour.computeLuminance() > 0.5
            ? PaletteColours.textPrimary
            : Colors.white;

    return Container(
      height: height,
      color: colour,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColour,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            proportion,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColour.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// CTA card linking to the AI Room Visualiser (Phase 3.1).
class _VisualiserCta extends ConsumerWidget {
  const _VisualiserCta({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(visualiserCreditsProvider);
    final tier = ref.watch(subscriptionTierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PaletteColours.premiumGradientStart,
            PaletteColours.premiumGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See it in your room',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Photograph your walls and preview your colours',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              final hex = room.heroColourHex ?? '';
              context.push('/visualiser?roomId=${room.id}&colour=$hex');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: PaletteColours.sageGreenDark,
            ),
            child: Text(
              tier == SubscriptionTier.free
                  ? 'Unlock'
                  : credits > 0
                  ? 'Try it'
                  : 'Top up',
            ),
          ),
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
                      hex != null ? hexToColor(hex!) : PaletteColours.warmGrey,
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
                    color: hexToColor(trim.hex),
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
          color: hexToColor(hex),
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
        // Quality gate: prompt for more data
        final weakItems = items.where((i) => !i.hasEnhancedData).length;
        return Column(
          children: [
            ...items.map(
              (item) => _FurnitureItemTile(
                item: item,
                onDelete: () async {
                  final repo = ref.read(roomRepositoryProvider);
                  await repo.deleteFurniture(item.id);
                  ref.invalidate(furnitureForRoomProvider(roomId));
                },
                onEdit:
                    () => _showAddFurnitureDialog(
                      context,
                      ref,
                      items.length,
                      existingItem: item,
                    ),
              ),
            ),
            if (weakItems > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: PaletteColours.sageGreenDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Add materials to $weakItems item${weakItems > 1 ? 's' : ''} for better recommendations',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.sageGreenDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
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
    int currentCount, {
    LockedFurniture? existingItem,
  }) {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    var selectedHex = existingItem?.colourHex ?? '#D3D3D3';
    var role = existingItem?.role ?? FurnitureRole.beta;
    var category = existingItem?.category;
    var status = existingItem?.status ?? FurnitureStatus.keeping;
    var material = existingItem?.material;
    var woodTone = existingItem?.woodTone;
    var metalFinish = existingItem?.metalFinish;
    var style = existingItem?.style;
    var textureFeel = existingItem?.textureFeel;
    var visualWeight = existingItem?.visualWeight;
    var finishSheen = existingItem?.finishSheen;
    var showEnhanced = existingItem?.hasEnhancedData ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (ctx, scrollController) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: PaletteColours.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          existingItem != null
                              ? 'Edit Furniture'
                              : 'Lock Furniture',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record what you already own so recommendations work around it.',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Minimum viable: name, category, status ---
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

                        // Category chips
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Category',
                            style: Theme.of(ctx).textTheme.labelMedium
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              FurnitureCategory.values.map((c) {
                                final isSelected = category == c;
                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(c.icon, size: 16),
                                      const SizedBox(width: 4),
                                      Text(c.displayName),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: PaletteColours.sageGreen
                                      .withValues(alpha: 0.2),
                                  onSelected:
                                      (v) => setDialogState(
                                        () => category = v ? c : null,
                                      ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Status
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Status',
                            style: Theme.of(ctx).textTheme.labelMedium
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              FurnitureStatus.values.map((s) {
                                final isSelected = status == s;
                                return ChoiceChip(
                                  label: Text(s.displayName),
                                  selected: isSelected,
                                  selectedColor: PaletteColours.sageGreen
                                      .withValues(alpha: 0.2),
                                  onSelected:
                                      (v) => setDialogState(() => status = s),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Colour picker
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Approximate colour',
                            style: Theme.of(ctx).textTheme.labelMedium
                                ?.copyWith(color: PaletteColours.textSecondary),
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
                                        color: hexToColor(e.value),
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
                        Row(
                          children: [
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
                                  setDialogState(
                                    () => selectedHex = picked.hex,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.palette_outlined,
                                size: 16,
                              ),
                              label: const Text('Find exact colour'),
                              style: TextButton.styleFrom(
                                foregroundColor: PaletteColours.sageGreenDark,
                              ),
                            ),
                          ],
                        ),
                        // Colour relationship hint
                        if (heroColourHex != null)
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
                        const SizedBox(height: 16),

                        // Role dropdown
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
                        const SizedBox(height: 20),

                        // --- Enhanced section (expandable) ---
                        InkWell(
                          onTap:
                              () => setDialogState(
                                () => showEnhanced = !showEnhanced,
                              ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: PaletteColours.sageGreenDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add material details for better recommendations',
                                    style: Theme.of(
                                      ctx,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: PaletteColours.sageGreenDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  showEnhanced
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: PaletteColours.sageGreenDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showEnhanced) ...[
                          const SizedBox(height: 12),

                          // Material
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Primary material',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                FurnitureMaterial.values.map((m) {
                                  return ChoiceChip(
                                    label: Text(m.displayName),
                                    selected: material == m,
                                    selectedColor: PaletteColours.sageGreen
                                        .withValues(alpha: 0.2),
                                    onSelected:
                                        (v) => setDialogState(
                                          () => material = v ? m : null,
                                        ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Conditional: wood tone
                          if (material == FurnitureMaterial.wood) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Wood tone',
                                style: Theme.of(
                                  ctx,
                                ).textTheme.labelMedium?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  WoodTone.values.map((w) {
                                    return ChoiceChip(
                                      label: Text(w.displayName),
                                      selected: woodTone == w,
                                      selectedColor: PaletteColours.sageGreen
                                          .withValues(alpha: 0.2),
                                      onSelected:
                                          (v) => setDialogState(
                                            () => woodTone = v ? w : null,
                                          ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Conditional: metal finish
                          if (material == FurnitureMaterial.metal) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Metal finish',
                                style: Theme.of(
                                  ctx,
                                ).textTheme.labelMedium?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  MetalFinish.values.map((mf) {
                                    return ChoiceChip(
                                      label: Text(mf.displayName),
                                      selected: metalFinish == mf,
                                      selectedColor: PaletteColours.sageGreen
                                          .withValues(alpha: 0.2),
                                      onSelected:
                                          (v) => setDialogState(
                                            () => metalFinish = v ? mf : null,
                                          ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Style
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Style',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                FurnitureStyle.values.map((s) {
                                  return ChoiceChip(
                                    label: Text(s.displayName),
                                    selected: style == s,
                                    selectedColor: PaletteColours.sageGreen
                                        .withValues(alpha: 0.2),
                                    onSelected:
                                        (v) => setDialogState(
                                          () => style = v ? s : null,
                                        ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Texture, visual weight, sheen
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Texture feel',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                TextureFeel.values.map((t) {
                                  return ChoiceChip(
                                    label: Text(t.displayName),
                                    selected: textureFeel == t,
                                    selectedColor: PaletteColours.sageGreen
                                        .withValues(alpha: 0.2),
                                    onSelected:
                                        (v) => setDialogState(
                                          () => textureFeel = v ? t : null,
                                        ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Visual weight',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                VisualWeight.values.map((vw) {
                                  return ChoiceChip(
                                    label: Text(vw.displayName),
                                    selected: visualWeight == vw,
                                    selectedColor: PaletteColours.sageGreen
                                        .withValues(alpha: 0.2),
                                    onSelected:
                                        (v) => setDialogState(
                                          () => visualWeight = v ? vw : null,
                                        ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Finish / sheen',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                FinishSheen.values.map((f) {
                                  return ChoiceChip(
                                    label: Text(f.displayName),
                                    selected: finishSheen == f,
                                    selectedColor: PaletteColours.sageGreen
                                        .withValues(alpha: 0.2),
                                    onSelected:
                                        (v) => setDialogState(
                                          () => finishSheen = v ? f : null,
                                        ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;

                                  final repo = ref.read(roomRepositoryProvider);
                                  final companion =
                                      LockedFurnitureItemsCompanion.insert(
                                        id:
                                            existingItem?.id ??
                                            const Uuid().v4(),
                                        roomId: roomId,
                                        name: name,
                                        colourHex: selectedHex,
                                        role: role,
                                        sortOrder:
                                            existingItem?.sortOrder ??
                                            currentCount,
                                        category: Value(category),
                                        status: Value(status),
                                        material: Value(material),
                                        woodTone: Value(woodTone),
                                        metalFinish: Value(metalFinish),
                                        style: Value(style),
                                        textureFeel: Value(textureFeel),
                                        visualWeight: Value(visualWeight),
                                        finishSheen: Value(finishSheen),
                                      );

                                  if (existingItem != null) {
                                    await repo.deleteFurniture(existingItem.id);
                                  }
                                  await repo.insertFurniture(companion);
                                  ref.invalidate(
                                    furnitureForRoomProvider(roomId),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: Text(
                                  existingItem != null ? 'Update' : 'Lock',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}

/// Individual furniture item tile with enhanced display.
class _FurnitureItemTile extends StatelessWidget {
  const _FurnitureItemTile({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  final LockedFurniture item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hexToColor(item.colourHex),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PaletteColours.divider),
              ),
              child:
                  item.category != null
                      ? Icon(
                        item.category!.icon,
                        size: 16,
                        color:
                            _isLightColour(item.colourHex)
                                ? Colors.black54
                                : Colors.white,
                      )
                      : const Icon(Icons.lock, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    item.summaryLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.status == FurnitureStatus.replacing)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PaletteColours.softGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Replacing',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.softGoldDark,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDelete,
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
          color: hexToColor(hex),
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
  try {
    final colour = hexToColor(hex);
    return colour.computeLuminance() > 0.4;
  } catch (_) {
    return true;
  }
}

// ---------------------------------------------------------------------------
// Room Checklist
// ---------------------------------------------------------------------------

class _RoomChecklist extends ConsumerStatefulWidget {
  const _RoomChecklist({required this.room});

  final Room room;

  @override
  ConsumerState<_RoomChecklist> createState() => _RoomChecklistState();
}

class _RoomChecklistState extends ConsumerState<_RoomChecklist> {
  bool? _expandedOverride;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
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
        label: '${BrandedTerms.redThread} connected',
        done: hasRedThread,
        actionLabel: 'Connect',
        onAction: () => context.push('/red-thread'),
      ),
    ];

    final completed = items.where((i) => i.done).length;

    // Auto-collapse when 4+ items complete (spec 1B.2), user can toggle
    final isExpanded = _expandedOverride ?? completed < 4;

    // Hero colour for progress bar (spec 1E.5)
    final progressColour =
        room.heroColourHex != null
            ? hexToColor(room.heroColourHex!)
            : PaletteColours.sageGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap:
                completed >= 4
                    ? () => setState(() {
                      _expandedOverride = !isExpanded;
                    })
                    : null,
            child: Row(
              children: [
                Text(
                  'Room checklist',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completed/${items.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                if (completed >= 4) ...[
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: PaletteColours.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar with hero colour (spec 1E.5)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: completed / items.length,
              minHeight: 6,
              backgroundColor: PaletteColours.divider,
              valueColor: AlwaysStoppedAnimation<Color>(progressColour),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            ...items.map((item) => _buildChecklistRow(context, item)),
          ],
        ],
      ),
    );
  }

  void _showEditRoomSheet(BuildContext context, WidgetRef ref) {
    _showRoomEditSheet(context, ref, widget.room);
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
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  item.actionLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PaletteColours.sageGreenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
// Paint Recommendations for this Room
// ---------------------------------------------------------------------------

class _PaintRecommendationsSection extends ConsumerWidget {
  const _PaintRecommendationsSection({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(roomPaintRecommendationsProvider(room));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Paint for this room',
          actionLabel: 'Browse all',
          onAction:
              () => context.push('/explore/paint-library?roomId=${room.id}'),
        ),
        const SizedBox(height: 4),
        Text(
          room.direction != null
              ? 'Matched to your hero colour and '
                  '${room.direction!.displayName.toLowerCase()}-facing light'
              : 'Matched to your hero colour',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: PaletteColours.textSecondary),
        ),
        const SizedBox(height: 12),
        recsAsync.when(
          data: (recs) {
            if (recs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PaletteColours.softCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No paint matches found for this room yet. '
                  'Try adjusting your hero colour or budget bracket.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              );
            }
            return Column(
              children:
                  recs
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PaintRecommendationCard(
                            recommendation: rec,
                            roomName: room.name,
                          ),
                        ),
                      )
                      .toList(),
            );
          },
          loading:
              () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          error:
              (_, __) => Text(
                'Could not load paint recommendations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
        ),
      ],
    );
  }
}

class _PaintRecommendationCard extends ConsumerWidget {
  const _PaintRecommendationCard({
    required this.recommendation,
    required this.roomName,
  });

  final RoomPaintRecommendation recommendation;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paint = recommendation.paint;
    final matchPercent = deltaEToMatchPercentage(recommendation.deltaE);

    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colour swatch
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hexToColor(paint.hex),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PaletteColours.divider, width: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          // Paint details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paint.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  paint.brand,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // Match percentage + price row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PaletteColours.sageGreenLight.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${matchPercent.round()}% match',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PaletteColours.sageGreenDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (paint.approximatePricePerLitre != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '~£${paint.approximatePricePerLitre!.toStringAsFixed(0)}/L',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PaletteColours.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Buy button
          BuyThisPaintButton(
            brand: paint.brand,
            colourCode: paint.code,
            colourName: paint.name,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paint & Finish Recommender (Phase 2B.3)
// ---------------------------------------------------------------------------

class _PaintFinishSection extends ConsumerWidget {
  const _PaintFinishSection({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recsAsync = ref.watch(roomPaintRecommendationsProvider(room));

    // Get the best matching paint for finish + quantity calculations.
    final heroPaint = recsAsync.whenOrNull<PaintColour?>(
      data: (recs) => recs.isNotEmpty ? recs.first.paint : null,
    );

    final plan = generatePaintPlan(room: room, heroPaint: heroPaint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Paint finishes & quantities',
          subtitle: 'What finish for each surface, and how much to buy',
        ),
        const SizedBox(height: 8),

        // Light direction note
        if (plan.lightDirectionNote != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PaletteColours.statusInfo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaletteColours.statusInfo.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: PaletteColours.sageGreenDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.lightDirectionNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Colour interaction note
        if (plan.colourNote != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PaletteColours.statusWarning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaletteColours.statusWarning.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: PaletteColours.softGoldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.colourNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.softGoldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Finish recommendations per surface
        ...plan.finishRecommendations.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FinishCard(
              recommendation: rec,
              quantity: plan.quantities[rec.surface],
              paintName: heroPaint?.name,
              roomName: room.name,
            ),
          ),
        ),

        // Total estimated paint cost
        if (heroPaint?.approximatePricePerLitre != null) ...[
          const SizedBox(height: 4),
          _PaintCostSummary(
            quantities: plan.quantities,
            paintName: heroPaint!.name,
          ),
        ],

        // Disclaimer
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Quantities are estimates for two coats. Always buy a little '
            'extra for touch-ups.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: PaletteColours.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _FinishCard extends StatelessWidget {
  const _FinishCard({
    required this.recommendation,
    required this.roomName,
    this.quantity,
    this.paintName,
  });

  final FinishRecommendation recommendation;
  final PaintQuantity? quantity;
  final String? paintName;
  final String roomName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = recommendation;

    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surface + finish header
          Row(
            children: [
              Icon(
                _surfaceIcon(rec.surface),
                size: 18,
                color: PaletteColours.sageGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.surface.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PaletteColours.sageGreenLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.finish.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: PaletteColours.sageGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reason
          Text(
            rec.reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),

          // Alternative finish
          if (rec.alternativeFinish != null) ...[
            const SizedBox(height: 4),
            Text(
              'Alternative: ${rec.alternativeFinish!.displayName}'
              '${rec.alternativeReason != null ? ' — ${rec.alternativeReason}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: PaletteColours.textTertiary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Quantity
          if (quantity != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PaletteColours.softCream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    size: 14,
                    color: PaletteColours.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      paintName != null
                          ? '${quantity!.tinsNeeded}× ${quantity!.tinLabel} '
                              '$paintName in ${rec.finish.emulsionLabel}'
                          : '${quantity!.tinsNeeded}× ${quantity!.tinLabel} '
                              'in ${rec.finish.emulsionLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (quantity!.estimatedCost != null)
                    Text(
                      '~£${quantity!.estimatedCost!.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PaletteColours.sageGreenDark,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _surfaceIcon(PaintSurface surface) {
    switch (surface) {
      case PaintSurface.walls:
        return Icons.crop_square;
      case PaintSurface.woodwork:
        return Icons.vertical_split_outlined;
      case PaintSurface.ceiling:
        return Icons.roofing_outlined;
    }
  }
}

class _PaintCostSummary extends StatelessWidget {
  const _PaintCostSummary({required this.quantities, required this.paintName});

  final Map<PaintSurface, PaintQuantity> quantities;
  final String paintName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double total = 0;
    for (final q in quantities.values) {
      if (q.estimatedCost != null) total += q.estimatedCost!;
    }
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            color: PaletteColours.shadowLevel1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated paint cost',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                Text(
                  paintName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '~£${total.toStringAsFixed(0)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: PaletteColours.sageGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}

// Contextual Tool Links
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Room Gap Analysis — "What this room still needs"
// ---------------------------------------------------------------------------

class _RoomGapSection extends ConsumerStatefulWidget {
  const _RoomGapSection({required this.roomId});

  final String roomId;

  @override
  ConsumerState<_RoomGapSection> createState() => _RoomGapSectionState();
}

class _RoomGapSectionState extends ConsumerState<_RoomGapSection> {
  bool _gapsTracked = false;

  void _trackGaps(RoomGapReport report) {
    if (_gapsTracked || !report.hasGaps) return;
    _gapsTracked = true;
    final analytics = ref.read(analyticsProvider);
    for (final gap in report.gaps) {
      analytics.trackGapIdentified(
        gapType: gap.gapType.name,
        severity: gap.severity.name,
        roomId: widget.roomId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gapAsync = ref.watch(roomGapReportProvider(widget.roomId));
    final theme = Theme.of(context);

    return gapAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (report) {
        _trackGaps(report);
        if (!report.hasGaps) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'What this room still needs',
              subtitle: 'Based on your colour plan and furniture',
            ),
            if (report.dataQuality == DataQuality.none ||
                report.dataQuality == DataQuality.minimal) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: PaletteColours.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add your existing furniture for better suggestions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Primary gap — most prominent
            if (report.primaryGap != null) ...[
              _GapCard(gap: report.primaryGap!, isPrimary: true),
            ],
            // Secondary gaps — compact
            ...report.secondaryGaps.map(
              (gap) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _GapCard(gap: gap, isPrimary: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.gap, required this.isPrimary});

  final RoomGap gap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.warmGrey),
        boxShadow:
            isPrimary
                ? const [
                  BoxShadow(
                    offset: Offset(0, 4),
                    blurRadius: 12,
                    color: PaletteColours.shadowLevel2,
                  ),
                ]
                : const [
                  BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: PaletteColours.shadowLevel1,
                  ),
                ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForGap(gap.gapType),
                size: 20,
                color: _colourForSeverity(gap.severity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gap.title,
                      style:
                          isPrimary
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gap.whyItMatters,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ConfidenceBadge(label: gap.confidenceLabel),
              const SizedBox(width: 8),
              _SeverityBadge(severity: gap.severity),
            ],
          ),
          if (gap.blocker != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: PaletteColours.softGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    gap.blocker!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.softGold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForGap(GapType type) => switch (type) {
    GapType.rug => Icons.texture,
    GapType.taskLighting => Icons.desk_outlined,
    GapType.accentLighting => Icons.light_mode_outlined,
    GapType.ambientLighting => Icons.light_outlined,
    GapType.textureContrast => Icons.layers_outlined,
    GapType.accentColour => Icons.color_lens_outlined,
    GapType.storage => Icons.inventory_2_outlined,
    GapType.artwork => Icons.image_outlined,
    GapType.curtain => Icons.curtains_outlined,
    GapType.throwSoft => Icons.dry_cleaning_outlined,
    GapType.cushions => Icons.weekend_outlined,
    GapType.mirror => Icons.crop_square_outlined,
    GapType.warmMaterial => Icons.local_fire_department_outlined,
    GapType.coolMaterial => Icons.ac_unit_outlined,
    GapType.metalClash => Icons.warning_amber_outlined,
    GapType.woodClash => Icons.warning_amber_outlined,
    GapType.sheenBalance => Icons.blur_on_outlined,
    GapType.redThread => Icons.hub_outlined,
  };

  Color _colourForSeverity(GapSeverity severity) => switch (severity) {
    GapSeverity.high => PaletteColours.softGold,
    GapSeverity.medium => PaletteColours.sageGreen,
    GapSeverity.low => PaletteColours.textSecondary,
  };
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: PaletteColours.textSecondary),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final GapSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (severity) {
      GapSeverity.high => ('High impact', PaletteColours.softGold),
      GapSeverity.medium => ('Medium impact', PaletteColours.sageGreen),
      GapSeverity.low => ('Nice to have', PaletteColours.textTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colour,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── "Complete the Room" Product Recommendations ──

class _ProductRecommendationsSection extends ConsumerStatefulWidget {
  const _ProductRecommendationsSection({
    required this.roomId,
    required this.roomName,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<_ProductRecommendationsSection> createState() =>
      _ProductRecommendationsSectionState();
}

class _ProductRecommendationsSectionState
    extends ConsumerState<_ProductRecommendationsSection> {
  bool _recsTracked = false;

  void _trackRecsViewed(
    List<(RecommendationSlot, ScoredProduct)> recs,
    String? gapType,
  ) {
    if (_recsTracked) return;
    _recsTracked = true;
    final analytics = ref.read(analyticsProvider);
    for (var i = 0; i < recs.length; i++) {
      final (slot, scored) = recs[i];
      analytics.trackRecommendationViewed(
        gapType: gapType ?? 'unknown',
        productId: scored.product.id,
        position: i,
        roomId: widget.roomId,
        slot: slot.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(roomProductRecsProvider(widget.roomId));
    final gapAsync = ref.watch(roomGapReportProvider(widget.roomId));
    final theme = Theme.of(context);

    return recsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      error: (_, __) => const SizedBox.shrink(),
      data: (recs) {
        if (recs.isEmpty) {
          return gapAsync.when(
            data: (report) {
              if (!report.hasGaps) return const SizedBox.shrink();
              return _NoProductsMessage(gap: report.primaryGap);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        }

        final primaryGap = gapAsync.valueOrNull?.primaryGap;
        final gapTitle = primaryGap?.title;

        // Track recommendation views once
        _trackRecsViewed(recs, primaryGap?.gapType.name);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Complete the room',
              subtitle: 'Personalised product recommendations',
              actionLabel: 'Shopping list',
              onAction: () => GoRouter.of(context).push('/shopping-list'),
            ),
            // Commission disclosure
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'We may earn a commission if you buy through these links. '
                'This never affects which products we recommend.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
            if (gapTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: PaletteColours.sageGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: PaletteColours.sageGreenDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gapTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: PaletteColours.sageGreenDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...recs.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  slot: entry.$1,
                  scoredProduct: entry.$2,
                  roomId: widget.roomId,
                  roomName: widget.roomName,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoProductsMessage extends StatelessWidget {
  const _NoProductsMessage({this.gap});

  final RoomGap? gap;

  @override
  Widget build(BuildContext context) {
    if (gap == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Complete the room',
          subtitle: 'Personalised product recommendations',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PaletteColours.softCream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We need more information about this room to give you '
                'great recommendations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your existing furniture to improve results.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.sageGreenDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.slot,
    required this.scoredProduct,
    required this.roomId,
    required this.roomName,
  });

  final RecommendationSlot slot;
  final ScoredProduct scoredProduct;
  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = scoredProduct.product;
    final theme = Theme.of(context);
    final productColour = hexToColor(product.primaryColourHex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.warmGrey),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 8,
            color: PaletteColours.shadowLevel1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot badge + colour swatch header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PaletteColours.softCream.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Colour swatch
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: productColour,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PaletteColours.warmGrey,
                      width: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${product.brand} · ${product.category.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Slot badge
                _SlotBadge(slot: slot),
              ],
            ),
          ),

          // Body: reasons + price
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary reason
                Text(
                  scoredProduct.primaryReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Secondary reason
                Text(
                  scoredProduct.secondaryReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                // Finish note
                if (scoredProduct.finishNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    scoredProduct.finishNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                // Material note
                if (scoredProduct.materialNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    scoredProduct.materialNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                // Tradeoff note
                if (scoredProduct.tradeoffNote != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: PaletteColours.softGold,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          scoredProduct.tradeoffNote!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: PaletteColours.softGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Footer: price + confidence + buy button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                // Price
                Text(
                  '£${product.priceGbp.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  product.retailer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                  ),
                ),
                const Spacer(),
                // Confidence label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: PaletteColours.sageGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scoredProduct.confidenceLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Buy + Save + Dismiss buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                // Save to list
                _SaveToListButton(
                  product: product,
                  roomId: roomId,
                  roomName: roomName,
                ),
                const SizedBox(width: 8),
                // Buy
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openAffiliateLink(context, ref, product),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('Buy from ${product.retailer}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PaletteColours.sageGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Not for me
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _DismissButton(product: product, roomId: roomId),
          ),
        ],
      ),
    );
  }

  Future<void> _openAffiliateLink(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    ref
        .read(analyticsProvider)
        .trackRecommendationBuyTapped(
          productId: product.id,
          productCategory: product.category.name,
          price: product.priceGbp,
          retailer: product.retailer,
          roomId: roomId,
          slot: slot.name,
        );

    // Persist buy feedback for the feedback loop.
    _recordFeedback(ref, product, 'buy');

    final uri = Uri.tryParse(product.affiliateUrl);
    if (uri == null || uri.scheme != 'https') return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  void _recordFeedback(
    WidgetRef ref,
    Product product,
    String action, [
    String? dismissReason,
  ]) {
    final repo = ref.read(feedbackRepositoryProvider);
    repo.record(
      RecommendationFeedbacksCompanion.insert(
        id: _uuid.v4(),
        productId: product.id,
        roomId: roomId,
        productCategory: product.category.name,
        action: action,
        dismissReason: Value(dismissReason),
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.slot});

  final RecommendationSlot slot;

  @override
  Widget build(BuildContext context) {
    final (colour, icon) = switch (slot) {
      RecommendationSlot.recommended => (
        PaletteColours.sageGreen,
        Icons.star_rounded,
      ),
      RecommendationSlot.bestValue => (
        PaletteColours.softGold,
        Icons.savings_outlined,
      ),
      RecommendationSlot.somethingDifferent => (
        PaletteColours.accessibleBlue,
        Icons.auto_awesome,
      ),
      RecommendationSlot.safeChoice => (
        PaletteColours.textSecondary,
        Icons.verified_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colour),
          const SizedBox(width: 4),
          Text(
            slot.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colour,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveToListButton extends ConsumerWidget {
  const _SaveToListButton({
    required this.product,
    required this.roomId,
    required this.roomName,
  });

  final Product product;
  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inListAsync = ref.watch(
      isInShoppingListProvider((productId: product.id, roomId: roomId)),
    );
    final isInList = inListAsync.valueOrNull ?? false;

    return OutlinedButton.icon(
      onPressed: isInList ? null : () => _addToList(context, ref),
      icon: Icon(isInList ? Icons.check : Icons.add_shopping_cart, size: 16),
      label: Text(isInList ? 'Saved' : 'Save'),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isInList ? PaletteColours.textTertiary : PaletteColours.sageGreen,
        side: BorderSide(
          color: isInList ? PaletteColours.warmGrey : PaletteColours.sageGreen,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _addToList(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(shoppingListRepositoryProvider);
    final companion = ShoppingListItemsCompanion.insert(
      id: _uuid.v4(),
      productId: product.id,
      roomId: roomId,
      roomName: roomName,
      productName: product.name,
      brand: product.brand,
      retailer: product.retailer,
      priceGbp: product.priceGbp,
      affiliateUrl: product.affiliateUrl,
      primaryColourHex: product.primaryColourHex,
      categoryName: product.category.displayName,
      addedAt: DateTime.now(),
    );
    await repo.addItem(companion);

    // Invalidate the in-list check so the button updates
    ref.invalidate(
      isInShoppingListProvider((productId: product.id, roomId: roomId)),
    );

    ref.read(analyticsProvider).track('product_rec_saved', {
      'product_id': product.id,
      'product_category': product.category.name,
      'room_id': roomId,
    });

    // Persist save feedback for the feedback loop.
    ref
        .read(feedbackRepositoryProvider)
        .record(
          RecommendationFeedbacksCompanion.insert(
            id: _uuid.v4(),
            productId: product.id,
            roomId: roomId,
            productCategory: product.category.name,
            action: 'save',
            dismissReason: const Value.absent(),
            createdAt: DateTime.now(),
          ),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to shopping list'),
          action: SnackBarAction(
            label: 'View list',
            onPressed: () => GoRouter.of(context).push('/shopping-list'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// "Not for me" button with dismiss reason capture.
class _DismissButton extends ConsumerWidget {
  const _DismissButton({required this.product, required this.roomId});

  final Product product;
  final String roomId;

  static const _reasons = [
    ('style', 'Wrong style'),
    ('price', 'Too expensive'),
    ('colour', 'Wrong colour'),
    ('scale', 'Wrong size'),
    ('material', 'Wrong material'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showDismissSheet(context, ref),
      icon: const Icon(Icons.close, size: 14),
      label: const Text('Not for me'),
      style: TextButton.styleFrom(
        foregroundColor: PaletteColours.textTertiary,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  void _showDismissSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<String>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Why isn't this right?",
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      'This helps us improve your recommendations.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                  ),
                  for (final (code, label) in _reasons)
                    ListTile(
                      title: Text(label),
                      onTap: () => Navigator.pop(ctx, code),
                    ),
                ],
              ),
            ),
          ),
    ).then((reason) {
      if (reason == null) return;

      // Analytics event
      ref
          .read(analyticsProvider)
          .trackRecommendationDismissed(
            productId: product.id,
            reason: reason,
            roomId: roomId,
          );

      // Persist feedback for the loop.
      ref
          .read(feedbackRepositoryProvider)
          .record(
            RecommendationFeedbacksCompanion.insert(
              id: _uuid.v4(),
              productId: product.id,
              roomId: roomId,
              productCategory: product.category.name,
              action: 'dismiss',
              dismissReason: Value(reason),
              createdAt: DateTime.now(),
            ),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Noted — we'll improve your suggestions."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}

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
  var roomSize = room.roomSize;
  final widthCtrl = TextEditingController(
    text: room.widthMetres?.toStringAsFixed(1) ?? '',
  );
  final lengthCtrl = TextEditingController(
    text: room.lengthMetres?.toStringAsFixed(1) ?? '',
  );

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
                child: SingleChildScrollView(
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
                      DropdownButtonFormField<RoomSize>(
                        value: roomSize,
                        decoration: const InputDecoration(
                          labelText: 'Room size',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            RoomSize.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.displayName),
                              );
                            }).toList(),
                        onChanged: (v) => setSheetState(() => roomSize = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: widthCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Width (m)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lengthCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Length (m)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
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
                          final width = double.tryParse(widthCtrl.text);
                          final length = double.tryParse(lengthCtrl.text);
                          await repo.updateRoom(
                            RoomsCompanion(
                              id: Value(room.id),
                              name: Value(name),
                              direction: Value(direction),
                              usageTime: Value(usageTime),
                              moods: Value(room.moods),
                              budget: Value(budget),
                              isRenterMode: Value(isRenterMode),
                              roomSize: Value(roomSize),
                              widthMetres: Value(width),
                              lengthMetres: Value(length),
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
        ),
  );
}

/// CTA card for the AI Design Assistant (Phase 3.2).
class _AssistantCta extends StatelessWidget {
  const _AssistantCta({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final prompt = Uri.encodeComponent(
      'What colour should I paint my ${room.name}?',
    );

    return GestureDetector(
      onTap: () => context.push('/assistant?prompt=$prompt'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PaletteColours.softCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaletteColours.sageGreenLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: PaletteColours.sageGreen,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ask the Design Assistant about this room',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.sageGreenDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: PaletteColours.sageGreenDark,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
