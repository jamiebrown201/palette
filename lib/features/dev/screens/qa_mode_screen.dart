import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/dev/services/qa_seed_service.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/rooms/screens/create_room_screen.dart';
import 'package:palette/providers/app_providers.dart';

/// Debug-only QA Mode screen for quick navigation and state control.
///
/// Provides state toggles, data seeding, and one-tap navigation to every
/// screen in the app for fast screenshot QA cycles.
class QaModeScreen extends ConsumerStatefulWidget {
  const QaModeScreen({super.key});

  @override
  ConsumerState<QaModeScreen> createState() => _QaModeScreenState();
}

class _QaModeScreenState extends ConsumerState<QaModeScreen> {
  String? _selectedRoomId;
  bool _seeding = false;
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'QaModeScreen should only be used in debug builds');

    final tier = ref.watch(subscriptionTierProvider);
    final onboarded = ref.watch(hasCompletedOnboardingProvider);
    final colourBlind = ref.watch(colourBlindModeProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final dnaAsync = ref.watch(latestColourDnaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QA Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === STATE CONTROLS ===
          Text('State Controls',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Subscription:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<SubscriptionTier>(
                          value: tier,
                          isExpanded: true,
                          items: SubscriptionTier.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.displayName),
                                  ))
                              .toList(),
                          onChanged: (t) {
                            if (t != null) {
                              ref
                                  .read(subscriptionTierProvider.notifier)
                                  .state = t;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Onboarding completed'),
                    value: onboarded,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => ref
                        .read(hasCompletedOnboardingProvider.notifier)
                        .state = v,
                  ),
                  SwitchListTile(
                    title: const Text('Colour blind mode'),
                    value: colourBlind,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) =>
                        ref.read(colourBlindModeProvider.notifier).state = v,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === DATA STATUS ===
          Text('Data',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dnaAsync.when(
                    data: (dna) => Text(dna != null
                        ? 'Colour DNA: ${dna.primaryFamily.displayName} (${dna.colourHexes.length} colours)'
                        : 'Colour DNA: none'),
                    loading: () => const Text('Colour DNA: loading...'),
                    error: (_, __) => const Text('Colour DNA: error'),
                  ),
                  const SizedBox(height: 4),
                  roomsAsync.when(
                    data: (rooms) => Text('Rooms: ${rooms.length}'),
                    loading: () => const Text('Rooms: loading...'),
                    error: (_, __) => const Text('Rooms: error'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _seeding
                              ? null
                              : () async {
                                  setState(() => _seeding = true);
                                  await QaSeedService.seedDemoData(ref);
                                  if (mounted) {
                                    setState(() => _seeding = false);
                                  }
                                },
                          icon: _seeding
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.dataset),
                          label: const Text('Seed Demo Data'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearing
                              ? null
                              : () async {
                                  setState(() => _clearing = true);
                                  await QaSeedService.clearAllData(ref);
                                  if (mounted) {
                                    setState(() {
                                      _clearing = false;
                                      _selectedRoomId = null;
                                    });
                                  }
                                },
                          icon: _clearing
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.delete_sweep),
                          label: const Text('Clear All'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === ROOM SELECTOR (for Room Detail) ===
          roomsAsync.when(
            data: (rooms) {
              if (rooms.isEmpty) return const SizedBox.shrink();
              // Auto-select first room if none selected
              if (_selectedRoomId == null && rooms.isNotEmpty) {
                _selectedRoomId = rooms.first.id;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room for Detail View',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: rooms.any((r) => r.id == _selectedRoomId)
                            ? _selectedRoomId
                            : rooms.first.id,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: rooms
                            .map((r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(r.name),
                                ))
                            .toList(),
                        onChanged: (id) =>
                            setState(() => _selectedRoomId = id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // === SCREEN NAVIGATOR ===
          Text('Screens',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          _buildScreenGrid(context, roomsAsync),
        ],
      ),
    );
  }

  Widget _buildScreenGrid(
      BuildContext context, AsyncValue<List<dynamic>> roomsAsync) {
    final screens = [
      _ScreenEntry(
        label: 'Onboarding',
        icon: Icons.quiz,
        onTap: () {
          ref.read(hasCompletedOnboardingProvider.notifier).state = false;
          context.go('/onboarding');
        },
      ),
      _ScreenEntry(
        label: 'Home',
        icon: Icons.home,
        onTap: () => context.go('/home'),
      ),
      _ScreenEntry(
        label: 'Room List',
        icon: Icons.meeting_room,
        onTap: () => context.go('/rooms'),
      ),
      _ScreenEntry(
        label: 'Room Detail',
        icon: Icons.room_preferences,
        enabled: _selectedRoomId != null,
        onTap: () {
          if (_selectedRoomId != null) {
            context.go('/rooms/$_selectedRoomId');
          }
        },
      ),
      _ScreenEntry(
        label: 'Create Room',
        icon: Icons.add_home,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (context) => const CreateRoomScreen(),
            ),
          );
        },
      ),
      _ScreenEntry(
        label: 'Capture',
        icon: Icons.camera_alt,
        onTap: () => context.go('/capture'),
      ),
      _ScreenEntry(
        label: 'Explore',
        icon: Icons.explore,
        onTap: () => context.go('/explore'),
      ),
      _ScreenEntry(
        label: 'Colour Wheel',
        icon: Icons.palette,
        onTap: () => context.go('/explore/wheel'),
      ),
      _ScreenEntry(
        label: 'White Finder',
        icon: Icons.format_paint,
        onTap: () {
          final path = _selectedRoomId != null
              ? '/explore/white-finder?roomId=$_selectedRoomId'
              : '/explore/white-finder';
          context.go(path);
        },
      ),
      _ScreenEntry(
        label: 'Paint Library',
        icon: Icons.color_lens,
        onTap: () => context.go('/explore/paint-library'),
      ),
      _ScreenEntry(
        label: 'My Palette',
        icon: Icons.auto_awesome,
        onTap: () => context.push('/palette'),
      ),
      _ScreenEntry(
        label: 'Profile',
        icon: Icons.person,
        onTap: () => context.go('/profile'),
      ),
      _ScreenEntry(
        label: 'Red Thread',
        icon: Icons.linear_scale,
        onTap: () => context.push('/red-thread'),
      ),
      _ScreenEntry(
        label: 'Paywall',
        icon: Icons.workspace_premium,
        onTap: () => context.push('/paywall'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: screens.length,
      itemBuilder: (context, index) {
        final entry = screens[index];
        return _ScreenCard(entry: entry);
      },
    );
  }
}

class _ScreenEntry {
  const _ScreenEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
}

class _ScreenCard extends StatelessWidget {
  const _ScreenCard({required this.entry});

  final _ScreenEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.enabled ? entry.onTap : null,
        child: Opacity(
          opacity: entry.enabled ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entry.icon, size: 28),
              const SizedBox(height: 6),
              Text(
                entry.label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
