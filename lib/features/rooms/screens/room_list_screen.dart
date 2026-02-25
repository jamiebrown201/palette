import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/rooms/screens/create_room_screen.dart';

class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(allRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Rooms')),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return _EmptyRoomView(
              onCreateRoom: () => _showCreateRoom(context),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) => _RoomCard(
              room: rooms[index],
              onTap: () => context.go('/rooms/${rooms[index].id}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: roomsAsync.valueOrNull?.isNotEmpty ?? false
          ? FloatingActionButton(
              onPressed: () => _showCreateRoom(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateRoom(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const CreateRoomScreen(),
      ),
    );
  }
}

class _EmptyRoomView extends StatelessWidget {
  const _EmptyRoomView({required this.onCreateRoom});

  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: PaletteColours.softCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 40,
                color: PaletteColours.sageGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No rooms yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first room to get personalised '
              'colour recommendations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateRoom,
              icon: const Icon(Icons.add),
              label: const Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onTap,
  });

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                    color: room.heroColourHex != null
                        ? _hexToColor(room.heroColourHex!)
                        : PaletteColours.warmGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PaletteColours.divider),
                  ),
                  child: room.heroColourHex == null
                      ? const Icon(
                          Icons.palette_outlined,
                          size: 20,
                          color: PaletteColours.textTertiary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(room),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
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
      ),
    );
  }

  String _buildSubtitle(Room room) {
    final parts = <String>[];
    if (room.direction != null) parts.add(room.direction!.displayName);
    parts.add(room.usageTime.displayName);
    if (room.isRenterMode) parts.add('Renter');
    return parts.join(' \u2022 ');
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
