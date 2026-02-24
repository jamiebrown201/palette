import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                return _ColourDnaCard(
                  primaryFamily: dna.primaryFamily.displayName,
                  colourCount: dna.colourHexes.length,
                  hexes: dna.colourHexes.take(5).toList(),
                  onTap: () => context.push('/palette'),
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Quick actions
            const SectionHeader(title: 'Explore'),
            const SizedBox(height: 8),
            _QuickActionsGrid(
              actions: [
                _QuickAction(
                  icon: Icons.palette_outlined,
                  label: 'Colour Wheel',
                  onTap: () => context.go('/explore/wheel'),
                ),
                _QuickAction(
                  icon: Icons.format_paint_outlined,
                  label: 'White Finder',
                  onTap: () => context.go('/explore/white-finder'),
                ),
                _QuickAction(
                  icon: Icons.linear_scale,
                  label: 'Red Thread',
                  onTap: () => context.push('/red-thread'),
                ),
                _QuickAction(
                  icon: Icons.search,
                  label: 'Paint Library',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$primaryFamily \u2022 $colourCount colours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: hexes
                  .map((hex) => Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
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
      children: rooms.take(3).map((room) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                  color: room.heroColourHex != null
                      ? _hexToColor(room.heroColourHex!)
                      : PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  room.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: PaletteColours.textTertiary,
              ),
            ],
          ),
        );
      }).toList(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: PaletteColours.sageGreen),
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
                  color: PaletteColours.textSecondary,
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 44) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaletteColours.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: PaletteColours.sageGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
