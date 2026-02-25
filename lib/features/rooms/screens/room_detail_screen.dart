import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/colour/kelvin_simulation.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';
import 'package:palette/features/rooms/logic/seventy_twenty_ten.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

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
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
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
                ...room.moods.map((m) => _InfoChip(
                      icon: Icons.mood_outlined,
                      label: m.displayName,
                    )),
                if (room.isRenterMode)
                  const _InfoChip(
                    icon: Icons.vpn_key_outlined,
                    label: 'Renter',
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Light direction (free: educational, premium: full recs)
            if (room.direction != null) ...[
              const SectionHeader(title: 'Light & Direction'),
              const SizedBox(height: 8),
              _LightDirectionFreeSection(direction: room.direction!),
              const SizedBox(height: 8),
              PremiumGate(
                requiredTier: SubscriptionTier.plus,
                upgradeMessage: 'Unlock personalised light recommendations',
                child: _LightDirectionPremiumSection(
                  direction: room.direction!,
                  usageTime: room.usageTime,
                ),
              ),
              const SizedBox(height: 12),
              // White Finder link (context-aware)
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/explore/white-finder?roomId=${room.id}',
                ),
                icon: const Icon(Icons.format_paint_outlined, size: 16),
                label: const Text('Find the right white for this room'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PaletteColours.sageGreenDark,
                  side: const BorderSide(color: PaletteColours.sageGreen),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Furniture Lock
            const SectionHeader(title: 'Existing Furniture'),
            const SizedBox(height: 4),
            Text(
              "Lock items you're keeping so colour suggestions adapt around them.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            _FurnitureLockSection(roomId: room.id),
            const SizedBox(height: 24),

            // 70/20/10 Planner
            const SectionHeader(title: '70/20/10 Colour Plan'),
            const SizedBox(height: 8),
            PremiumGate(
              requiredTier: SubscriptionTier.plus,
              upgradeMessage: 'Unlock the 70/20/10 colour planner',
              child: _ColourPlanSection(room: room),
            ),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                initialValue: direction,
                decoration: const InputDecoration(
                  labelText: 'Window direction',
                  border: OutlineInputBorder(),
                ),
                items: CompassDirection.values.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(d.displayName),
                  );
                }).toList(),
                onChanged: (v) => setSheetState(() => direction = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UsageTime>(
                initialValue: usageTime,
                decoration: const InputDecoration(
                  labelText: 'Primary usage time',
                  border: OutlineInputBorder(),
                ),
                items: UsageTime.values.map((t) {
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
                initialValue: budget,
                decoration: const InputDecoration(
                  labelText: 'Budget bracket',
                  border: OutlineInputBorder(),
                ),
                items: BudgetBracket.values.map((b) {
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
                subtitle: const Text('Focus on furniture and accessories'),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _LightDirectionFreeSection extends StatelessWidget {
  const _LightDirectionFreeSection({required this.direction});

  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    final summary = getLightDirectionSummary(direction);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: PaletteColours.softGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightDirectionPremiumSection extends StatelessWidget {
  const _LightDirectionPremiumSection({
    required this.direction,
    required this.usageTime,
  });

  final CompassDirection direction;
  final UsageTime usageTime;

  @override
  Widget build(BuildContext context) {
    final rec = getLightRecommendation(
      direction: direction,
      usageTime: usageTime,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.sageGreenLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 16, color: PaletteColours.sageGreen),
              const SizedBox(width: 8),
              Text(
                rec.summary,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.recommendation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _UndertoneChip(
                label: 'Prefer: ${rec.preferredUndertone.displayName}',
                isPositive: true,
              ),
              if (rec.avoidUndertone != null) ...[
                const SizedBox(width: 8),
                _UndertoneChip(
                  label: 'Avoid: ${rec.avoidUndertone!.displayName}',
                  isPositive: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UndertoneChip extends StatelessWidget {
  const _UndertoneChip({
    required this.label,
    required this.isPositive,
  });

  final String label;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? PaletteColours.sageGreenLight
            : PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPositive
                  ? PaletteColours.sageGreenDark
                  : PaletteColours.textSecondary,
            ),
      ),
    );
  }
}

class _ColourPlanSection extends ConsumerWidget {
  const _ColourPlanSection({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHero = room.heroColourHex != null;

    return Column(
      children: [
        if (!hasHero) ...[
          Text(
            room.isRenterMode
                ? 'Match your existing wall colour and we will build a plan '
                    'around furniture and accessories you can change.'
                : 'Pick one colour you love for this room and we will suggest '
                    'the rest.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showHeroColourPicker(context, ref),
            icon: const Icon(Icons.palette_outlined, size: 18),
            label: Text(
              room.isRenterMode
                  ? 'Match your wall colour'
                  : 'Choose your hero colour',
            ),
          ),
        ] else ...[
          _ColourTierRow(
            label: room.isRenterMode ? 'Wall (fixed)' : 'Hero (70%)',
            description: room.isRenterMode
                ? 'Your existing wall colour'
                : 'Walls & dominant surfaces',
            hex: room.heroColourHex,
            onTap: () => _showHeroColourPicker(context, ref),
          ),
          const SizedBox(height: 8),
          _ColourTierRow(
            label: room.isRenterMode ? 'Furnishings' : 'Beta (20%)',
            description: room.isRenterMode
                ? 'Large items you can swap or add'
                : 'Large furnishings & upholstery',
            hex: room.betaColourHex,
            onTap: () => _showSwapPicker(context, ref, 'beta'),
          ),
          const SizedBox(height: 8),
          _ColourTierRow(
            label: room.isRenterMode ? 'Accents' : 'Surprise (10%)',
            description: room.isRenterMode
                ? 'Cushions, throws & accessories'
                : 'Accessories, artwork & accents',
            hex: room.surpriseColourHex,
            onTap: () => _showSwapPicker(context, ref, 'surprise'),
          ),
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

  Future<void> _showHeroColourPicker(
      BuildContext context, WidgetRef ref) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<PaintColour>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaintColourPicker(
        title: room.isRenterMode
            ? 'Match your existing wall colour'
            : 'Choose your hero colour',
        paintColours: allPaints,
      ),
    );

    if (selected == null || !context.mounted) return;

    // Fetch furniture and red thread data for the algorithm
    final furniture =
        await ref.read(furnitureForRoomProvider(room.id).future);
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
        wallColourHex: Value(room.isRenterMode ? selected.hex : room.wallColourHex),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref
      ..invalidate(roomByIdProvider(room.id))
      ..invalidate(allRoomsProvider);
  }

  Future<void> _showSwapPicker(
      BuildContext context, WidgetRef ref, String tier) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<PaintColour>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaintColourPicker(
        title: 'Swap ${tier == 'beta' ? 'Beta (20%)' : 'Surprise (10%)'} colour',
        paintColours: allPaints,
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
        betaColourHex:
            Value(tier == 'beta' ? selected.hex : room.betaColourHex),
        surpriseColourHex:
            Value(tier == 'surprise' ? selected.hex : room.surpriseColourHex),
        wallColourHex: Value(room.wallColourHex),
        sortOrder: Value(room.sortOrder),
        createdAt: Value(room.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
    ref.invalidate(roomByIdProvider(room.id));
  }

  Future<void> _regeneratePlan(BuildContext context, WidgetRef ref) async {
    if (room.heroColourHex == null) return;

    final allPaints = await ref.read(allPaintColoursProvider.future);
    final heroPaint = allPaints.firstWhere(
      (p) => p.hex.toLowerCase() == room.heroColourHex!.toLowerCase(),
      orElse: () => allPaints.first,
    );

    // Fetch furniture and red thread data for the algorithm
    final furniture =
        await ref.read(furnitureForRoomProvider(room.id).future);
    final redThreadHexes = await ref.read(threadHexesProvider.future);

    final plan = generateColourPlan(
      heroColour: heroPaint,
      allPaintColours: allPaints,
      direction: room.direction,
      usageTime: room.usageTime,
      redThreadHexes: redThreadHexes,
      lockedFurniture: furniture,
      budget: room.budget,
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
  }
}

/// A paint colour picker shown as a bottom sheet with search.
class _PaintColourPicker extends StatefulWidget {
  const _PaintColourPicker({
    required this.title,
    required this.paintColours,
  });

  final String title;
  final List<PaintColour> paintColours;

  @override
  State<_PaintColourPicker> createState() => _PaintColourPickerState();
}

class _PaintColourPickerState extends State<_PaintColourPicker> {
  String _query = '';

  List<PaintColour> get _filtered {
    if (_query.isEmpty) return widget.paintColours;
    final q = _query.toLowerCase();
    return widget.paintColours
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.hex.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    widget.title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, brand, or hex',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemBuilder: (ctx, i) {
                  final pc = _filtered[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hexToColor(pc.hex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PaletteColours.divider),
                      ),
                    ),
                    title: Text(pc.name),
                    subtitle: Text(pc.brand),
                    trailing: Text(
                      pc.hex.toUpperCase(),
                      style: Theme.of(ctx).textTheme.labelSmall,
                    ),
                    onTap: () => Navigator.pop(ctx, pc),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColourTierRow extends StatelessWidget {
  const _ColourTierRow({
    required this.label,
    required this.description,
    this.hex,
    this.onTap,
  });

  final String label;
  final String description;
  final String? hex;
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
                  color: hex != null
                      ? _hexToColor(hex!)
                      : PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
                child: hex == null
                    ? const Icon(Icons.add, color: PaletteColours.textTertiary)
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
                      hex != null
                          ? '$description \u2022 ${hex!.toUpperCase()}'
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

class _LightSimulation extends StatelessWidget {
  const _LightSimulation({
    required this.hex,
    required this.direction,
  });

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
  const _LightSwatchColumn({
    required this.label,
    required this.hex,
  });

  final String label;
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PaletteColours.divider),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FurnitureLockSection extends ConsumerWidget {
  const _FurnitureLockSection({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furnitureAsync = ref.watch(furnitureForRoomProvider(roomId));

    return furnitureAsync.when(
      data: (items) {
        return Column(
          children: [
            ...items.map((item) => Padding(
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
                        child: const Icon(Icons.lock,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Text(
                              item.role.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: PaletteColours.textSecondary,
                                  ),
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
                )),
            OutlinedButton.icon(
              onPressed: () =>
                  _showAddFurnitureDialog(context, ref, items.length),
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
      BuildContext context, WidgetRef ref, int currentCount) {
    final nameController = TextEditingController();
    var selectedHex = '#D3D3D3';
    var role = FurnitureRole.beta;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                children: _commonColours.entries.map((e) {
                  final isSelected = selectedHex == e.value;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedHex = e.value),
                    child: Tooltip(
                      message: e.key,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(e.value),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? PaletteColours.sageGreen
                                : PaletteColours.divider,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: _isLightColour(e.value)
                                    ? PaletteColours.textPrimary
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FurnitureRole>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: 'Role in room',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: FurnitureRole.values.map((r) {
                  return DropdownMenuItem(
                      value: r, child: Text(r.displayName));
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

  static bool _isLightColour(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse(cleaned, radix: 16);
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    return (0.299 * r + 0.587 * g + 0.114 * b) > 160;
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
