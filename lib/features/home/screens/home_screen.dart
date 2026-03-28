import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/progress_bar.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/home/logic/next_action.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/onboarding/logic/dna_drift.dart';
import 'package:palette/features/onboarding/providers/dna_drift_provider.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/logic/seasonal_refresh.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/rooms/screens/create_room_screen.dart';
import 'package:palette/features/shopping_list/providers/shopping_list_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dnaAsync = ref.watch(latestColourDnaProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final threadsAsync = ref.watch(threadColoursProvider);
    final coherenceAsync = ref.watch(coherenceReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Design Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'My Palette',
            onPressed: () => context.push('/palette'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colour DNA card
            dnaAsync.when(
              data: (dna) {
                if (dna == null) {
                  return _ActionCard(
                    icon: Icons.auto_awesome,
                    iconColor: PaletteColours.softGold,
                    title: 'Discover Your ${BrandedTerms.colourDna}',
                    subtitle:
                        '${BrandedTerms.colourDnaSubtitle} — take a quick quiz',
                    actionLabel: 'Start Quiz',
                    onAction: () => context.push('/onboarding'),
                  );
                }
                final archetypeName =
                    dna.archetype != null
                        ? archetypeDefinitions[dna.archetype]?.name
                        : null;
                return _ColourDnaCard(
                  primaryFamily: archetypeName ?? dna.primaryFamily.displayName,
                  colourCount: dna.colourHexes.length,
                  hexes: dna.colourHexes.take(6).toList(),
                  onTap: () => context.push('/palette'),
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Drift prompt
            _DriftPromptCard(),
            const SizedBox(height: 16),

            // Next Recommended Action
            roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Next Step'),
                    const SizedBox(height: 4),
                    _NextActionSection(
                      rooms: rooms,
                      coherenceReport: coherenceAsync.valueOrNull,
                      threadColours: threadsAsync.valueOrNull ?? [],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // My Rooms with progress
            SectionHeader(
              title: 'My Rooms',
              actionLabel:
                  roomsAsync.valueOrNull != null &&
                          roomsAsync.valueOrNull!.length > 3
                      ? 'See all'
                      : null,
              onAction: () => context.go('/rooms'),
            ),
            const SizedBox(height: 8),
            roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return _ActionCard(
                    icon: Icons.meeting_room_outlined,
                    title: 'Create Your First Room',
                    subtitle: 'Get personalised colour recommendations',
                    actionLabel: 'Create Room',
                    onAction:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (context) => const CreateRoomScreen(),
                          ),
                        ),
                  );
                }
                return _RoomProgressList(rooms: rooms);
              },
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Shopping List summary
            const _ShoppingListSummary(),
            const SizedBox(height: 20),

            // Seasonal Refresh Suggestions
            const _SeasonalRefreshSection(),
            const SizedBox(height: 20),

            // Whole-Home Coherence
            ...threadsAsync.when(
              data: (threads) {
                if (threads.isEmpty) return <Widget>[];
                return <Widget>[
                  const SectionHeader(title: 'Whole-Home Coherence'),
                  const SizedBox(height: 4),
                  coherenceAsync.when(
                    data:
                        (report) => _CoherenceSummary(
                          threadColours: threads,
                          coherenceReport: report,
                        ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                ];
              },
              loading: () => <Widget>[],
              error: (_, __) => <Widget>[],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colour DNA Card (kept from previous version)
// ---------------------------------------------------------------------------

class _ColourDnaCard extends StatelessWidget {
  const _ColourDnaCard({
    required this.primaryFamily,
    required this.colourCount,
    required this.hexes,
    required this.onTap,
  });

  final String primaryFamily;
  final int colourCount;
  final List<String> hexes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PaletteColours.premiumGradientStart,
                PaletteColours.premiumGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your ${BrandedTerms.colourDna}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          BrandedTerms.colourDnaSubtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$primaryFamily \u2022 $colourCount colours',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...hexes.map(
                    (hex) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hexToColor(hex),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (colourCount > hexes.length)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+${colourCount - hexes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next Recommended Action
// ---------------------------------------------------------------------------

class _NextActionSection extends ConsumerWidget {
  const _NextActionSection({
    required this.rooms,
    required this.coherenceReport,
    required this.threadColours,
  });

  final List<Room> rooms;
  final CoherenceReport? coherenceReport;
  final List<RedThreadColour> threadColours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furnitureMap = <String, bool>{};
    var anyLoading = false;

    for (final room in rooms) {
      final furnitureAsync = ref.watch(furnitureForRoomProvider(room.id));
      furnitureAsync.when(
        data: (items) => furnitureMap[room.id] = items.isNotEmpty,
        loading: () => anyLoading = true,
        error: (_, __) => furnitureMap[room.id] = false,
      );
    }

    if (anyLoading) return const SizedBox.shrink();

    final action = computeNextAction(
      rooms: rooms,
      coherenceReport: coherenceReport,
      threadColours: threadColours,
      roomHasFurniture: furnitureMap,
    );

    return _NextActionCard(action: action);
  }
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({required this.action});

  final NextAction action;

  @override
  Widget build(BuildContext context) {
    if (action.type == NextActionType.allDone) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.sageGreenLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 24,
              color: PaletteColours.sageGreenDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PaletteColours.sageGreenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final icon = switch (action.type) {
      NextActionType.completeRoomSetup => Icons.edit_outlined,
      NextActionType.defineRedThread => Icons.linear_scale,
      NextActionType.resolveCoherence => Icons.link_off,
      NextActionType.findWhite => Icons.format_paint_outlined,
      NextActionType.completeColourPlan => Icons.palette_outlined,
      NextActionType.lockFurniture => Icons.chair_outlined,
      NextActionType.allDone => Icons.check_circle_outline,
    };

    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push(action.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PaletteColours.sageGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: PaletteColours.sageGreenDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: PaletteColours.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Room Progress
// ---------------------------------------------------------------------------

class _RoomProgressList extends ConsumerWidget {
  const _RoomProgressList({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coherenceAsync = ref.watch(coherenceReportProvider);
    final coherenceReport = coherenceAsync.valueOrNull;

    return Column(
      children: [
        ...rooms.map(
          (room) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RoomProgressCard(
              room: room,
              coherenceReport: coherenceReport,
            ),
          ),
        ),
        const _AddRoomButton(),
      ],
    );
  }
}

class _RoomProgressCard extends ConsumerWidget {
  const _RoomProgressCard({required this.room, required this.coherenceReport});

  final Room room;
  final CoherenceReport? coherenceReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furnitureAsync = ref.watch(furnitureForRoomProvider(room.id));

    final hasFurniture = furnitureAsync.when(
      data: (items) => items.isNotEmpty,
      loading: () => false,
      error: (_, __) => false,
    );

    final isRedThreadConnected =
        coherenceReport?.results.any(
          (r) => r.roomId == room.id && r.isConnected,
        ) ??
        false;

    final progress = computeRoomProgress(
      room: room,
      hasFurniture: hasFurniture,
      isRedThreadConnected: isRedThreadConnected,
    );

    return Material(
      color: PaletteColours.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go('/rooms/${room.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PaletteColours.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          room.heroColourHex != null
                              ? hexToColor(room.heroColourHex!)
                              : PaletteColours.warmGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress.summary,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PaletteColours.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: PaletteColours.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SteppedProgressBar(
                totalSteps: progress.total,
                currentStep: progress.completed,
                activeColour:
                    room.heroColourHex != null
                        ? hexToColor(room.heroColourHex!)
                        : null,
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.completed} of ${progress.total} steps complete',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddRoomButton extends StatelessWidget {
  const _AddRoomButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (context) => const CreateRoomScreen(),
                ),
              ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaletteColours.sageGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add,
                  size: 18,
                  color: PaletteColours.sageGreenDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add Room',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.sageGreenDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Whole-Home Coherence Summary
// ---------------------------------------------------------------------------

class _CoherenceSummary extends StatelessWidget {
  const _CoherenceSummary({
    required this.threadColours,
    required this.coherenceReport,
  });

  final List<RedThreadColour> threadColours;
  final CoherenceReport coherenceReport;

  @override
  Widget build(BuildContext context) {
    final isCoherent = coherenceReport.overallCoherent;
    final bgColour =
        isCoherent
            ? PaletteColours.sageGreenLight
            : PaletteColours.softGoldLight;
    final accentColour =
        isCoherent ? PaletteColours.sageGreenDark : PaletteColours.softGoldDark;

    final count = coherenceReport.disconnectedCount;
    final verdict =
        isCoherent
            ? 'All rooms connected'
            : '$count room${count == 1 ? '' : 's'} not yet connected';

    return Material(
      color: bgColour,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/red-thread'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ...threadColours
                  .take(4)
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: hexToColor(t.hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BrandedTerms.redThread,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColour,
                      ),
                    ),
                    Text(
                      BrandedTerms.redThreadSubtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentColour.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      verdict,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: accentColour),
                    ),
                  ],
                ),
              ),
              Icon(
                isCoherent
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                size: 20,
                color: accentColour,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets (kept from previous version)
// ---------------------------------------------------------------------------

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.iconColor = PaletteColours.sageGreen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// Drift Prompt (kept from previous version)
// ---------------------------------------------------------------------------

class _DriftPromptCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(shouldShowDriftPromptProvider);

    return showAsync.when(
      data: (show) {
        if (!show) return const SizedBox.shrink();

        final driftAsync = ref.watch(dnaDriftProvider);
        return driftAsync.when(
          data: (drift) {
            if (drift == null) return const SizedBox.shrink();

            final description = _buildDriftDescription(drift);
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PaletteColours.softGoldLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PaletteColours.softGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: PaletteColours.softGoldDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your style is evolving',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: PaletteColours.softGoldDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.softGoldDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => context.push('/onboarding'),
                          style: FilledButton.styleFrom(
                            backgroundColor: PaletteColours.softGoldDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Retake Quiz'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final profileRepo = ref.read(
                              userProfileRepositoryProvider,
                            );
                            await profileRepo.dismissDriftPrompt();
                            ref.invalidate(shouldShowDriftPromptProvider);
                          },
                          child: Text(
                            'Dismiss',
                            style: TextStyle(
                              color: PaletteColours.softGoldDark.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  static String _buildDriftDescription(DnaDrift drift) {
    final parts = <String>[];

    if (drift.suggestedUndertone != null) {
      parts.add(drift.suggestedUndertone!.displayName.toLowerCase());
    }
    if (drift.suggestedSaturation != null) {
      parts.add(drift.suggestedSaturation!.displayName.toLowerCase());
    }
    if (drift.suggestedFamily != null) {
      parts.add(drift.suggestedFamily!.displayName.toLowerCase());
    }

    if (parts.isEmpty) {
      return 'Your recent colour choices suggest your taste may be shifting. '
          'Consider retaking the quiz to update your palette.';
    }

    final leanDescription = parts.join(', ');
    return 'Your recent colour choices lean more $leanDescription '
        'than your original DNA. Retake the quiz to refresh your palette.';
  }
}

// ---------------------------------------------------------------------------
// Shopping List summary (Phase 2B.2)
// ---------------------------------------------------------------------------

class _ShoppingListSummary extends ConsumerWidget {
  const _ShoppingListSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final total = items.fold<double>(0, (s, i) => s + i.priceGbp);
        final retailers = items.map((i) => i.retailer).toSet().length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Shopping List',
              actionLabel: 'View all',
              onAction: () => GoRouter.of(context).push('/shopping-list'),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/shopping-list'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PaletteColours.warmGrey),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 2),
                      blurRadius: 8,
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PaletteColours.sageGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: PaletteColours.sageGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'} saved',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$retailers ${retailers == 1 ? 'retailer' : 'retailers'} · est. £${total.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: PaletteColours.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Seasonal Refresh Suggestions (2B.5)
// ---------------------------------------------------------------------------

class _SeasonalRefreshSection extends ConsumerStatefulWidget {
  const _SeasonalRefreshSection();

  @override
  ConsumerState<_SeasonalRefreshSection> createState() =>
      _SeasonalRefreshSectionState();
}

class _SeasonalRefreshSectionState
    extends ConsumerState<_SeasonalRefreshSection> {
  bool _tracked = false;

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(seasonalSuggestionsProvider);

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();

        final season = seasonFromDate(DateTime.now());

        // Track viewed once per widget lifecycle
        if (!_tracked) {
          _tracked = true;
          ref.read(analyticsProvider).track(
            AnalyticsEvents.seasonalRefreshViewed,
            {'season': season.name, 'suggestion_count': suggestions.length},
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '${season.displayName} Refresh',
              subtitle: 'Small changes that make a big difference',
            ),
            const SizedBox(height: 4),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SeasonalSuggestionCard(suggestion: s),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SeasonalSuggestionCard extends ConsumerWidget {
  const _SeasonalSuggestionCard({required this.suggestion});

  final SeasonalSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.read(analyticsProvider);
    final season = suggestion.season;
    final product = suggestion.matchedProduct;

    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:
              product != null
                  ? () {
                    analytics
                        .track(AnalyticsEvents.seasonalRefreshProductTapped, {
                          'season': season.name,
                          'room_id': suggestion.room.id,
                          'room_name': suggestion.room.name,
                          'product_id': product.id,
                          'product_category': product.category.name,
                        });
                    context.push('/rooms/${suggestion.room.id}');
                  }
                  : () => context.push('/rooms/${suggestion.room.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colour swatch + season icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hexToColor(suggestion.colourHint),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PaletteColours.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      season.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.headline,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product != null) ...[
                        const SizedBox(height: 8),
                        _ProductChip(product: product),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: PaletteColours.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: hexToColor(product.primaryColourHex),
              shape: BoxShape.circle,
              border: Border.all(color: PaletteColours.divider, width: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${product.name} · £${product.priceGbp.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: PaletteColours.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
