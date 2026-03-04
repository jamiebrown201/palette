import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/onboarding/logic/dna_drift.dart';
import 'package:palette/features/onboarding/providers/dna_drift_provider.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/database_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dnaAsync = ref.watch(latestColourDnaProvider);
    final roomsAsync = ref.watch(allRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Palette'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'My Palette',
            onPressed: () => context.push('/palette'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your colour companion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            // Colour DNA card
            dnaAsync.when(
              data: (dna) {
                if (dna == null) {
                  return _ActionCard(
                    icon: Icons.auto_awesome,
                    title: 'Discover Your Colour DNA',
                    subtitle: 'Take a quick quiz to unlock your personal palette',
                    actionLabel: 'Start Quiz',
                    onAction: () => context.push('/onboarding'),
                  );
                }
                final archetypeName = dna.archetype != null
                    ? archetypeDefinitions[dna.archetype]?.name
                    : null;
                return _ColourDnaCard(
                  primaryFamily: archetypeName ??
                      dna.primaryFamily.displayName,
                  colourCount: dna.colourHexes.length,
                  hexes: dna.colourHexes.take(6).toList(),
                  onTap: () => context.push('/palette'),
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Drift prompt (below DNA card)
            _DriftPromptCard(),
            const SizedBox(height: 20),

            // My Rooms section
            const SectionHeader(title: 'My Rooms'),
            const SizedBox(height: 8),
            roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return _ActionCard(
                    icon: Icons.meeting_room_outlined,
                    title: 'Create Your First Room',
                    subtitle: 'Get personalised colour recommendations',
                    actionLabel: 'Create Room',
                    onAction: () => context.go('/rooms'),
                  );
                }
                return _RoomsSummary(rooms: rooms);
              },
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Quick actions
            const SectionHeader(title: 'Explore'),
            const SizedBox(height: 8),
            _QuickActionsRow(
              actions: [
                _QuickAction(
                  icon: Icons.palette_outlined,
                  label: 'Colour Wheel',
                  accentColour: PaletteColours.sageGreenLight,
                  onTap: () => context.go('/explore/wheel'),
                ),
                _QuickAction(
                  icon: Icons.format_paint_outlined,
                  label: 'White Finder',
                  accentColour: PaletteColours.softCream,
                  onTap: () => context.go('/explore/white-finder'),
                ),
                _QuickAction(
                  icon: Icons.linear_scale,
                  label: 'Red Thread',
                  accentColour: const Color(0xFFF0E0E0),
                  onTap: () => context.push('/red-thread'),
                ),
                _QuickAction(
                  icon: Icons.search,
                  label: 'Paint Library',
                  accentColour: PaletteColours.warmGrey,
                  onTap: () => context.go('/explore/paint-library'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your Colour DNA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7), size: 20),
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
              Row(
                children: [
                  ...hexes
                      .map((hex) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _hexToColor(hex),
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
                          )),
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

class _RoomsSummary extends StatelessWidget {
  const _RoomsSummary({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...rooms.take(3).map((room) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
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
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: room.heroColourHex != null
                              ? _hexToColor(room.heroColourHex!)
                              : PaletteColours.warmGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _buildRoomSubtitle(room),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: PaletteColours.textSecondary),
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
        }),
        if (rooms.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => context.go('/rooms'),
              child: Text(
                'See all ${rooms.length} rooms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.push('/rooms/create'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PaletteColours.sageGreen.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 18, color: PaletteColours.sageGreenDark),
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
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: PaletteColours.sageGreen),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColour,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accentColour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: PaletteColours.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColour ?? PaletteColours.softCream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: PaletteColours.sageGreenDark),
                ),
                const Spacer(),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
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
                                horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Retake Quiz'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final profileRepo =
                                ref.read(userProfileRepositoryProvider);
                            await profileRepo.dismissDriftPrompt();
                            ref.invalidate(shouldShowDriftPromptProvider);
                          },
                          child: Text(
                            'Dismiss',
                            style: TextStyle(
                              color: PaletteColours.softGoldDark
                                  .withValues(alpha: 0.7),
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

String _buildRoomSubtitle(Room room) {
  final parts = <String>[];
  if (room.direction != null) parts.add(room.direction!.displayName);
  parts.add(room.usageTime.displayName);
  return parts.join(' \u2022 ');
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
