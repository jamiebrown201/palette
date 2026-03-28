import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';

/// Displays a room-context badge at the top of a tool when accessed from a
/// room: "Showing results for: Living Room (south-facing, evening)".
///
/// Part of the Applied State System (Feature 1E.10).
class RoomContextBadge extends ConsumerWidget {
  const RoomContextBadge({required this.roomId, this.onClear, super.key});

  final String roomId;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));

    return roomAsync.when(
      data: (room) {
        if (room == null) return const SizedBox.shrink();
        return _RoomBadgeContent(room: room, onClear: onClear);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RoomBadgeContent extends StatelessWidget {
  const _RoomBadgeContent({required this.room, this.onClear});

  final Room room;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (room.direction != null) {
      parts.add('${room.direction!.displayName}-facing');
    }
    parts.add(room.usageTime.displayName.toLowerCase());

    final subtitle = parts.join(', ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PaletteColours.accessibleBlueLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaletteColours.accessibleBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            size: 18,
            color: PaletteColours.accessibleBlueDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showing results for:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PaletteColours.accessibleBlueDark,
                  ),
                ),
                Text(
                  '${room.name} ($subtitle)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.accessibleBlueDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: PaletteColours.accessibleBlueDark,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Clear room context',
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
