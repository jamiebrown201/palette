import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/data/models/diary_entry.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

// ── Providers ────────────────────────────────────────────────────────────

final diaryEntriesProvider = StreamProvider.family<List<DiaryEntry>, String>((
  ref,
  roomId,
) {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.watchForRoom(roomId);
});

final allDiaryEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.watchAll();
});

// ── Screen ───────────────────────────────────────────────────────────────

class DesignDiaryScreen extends ConsumerStatefulWidget {
  const DesignDiaryScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<DesignDiaryScreen> createState() => _DesignDiaryScreenState();
}

class _DesignDiaryScreenState extends ConsumerState<DesignDiaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider).track(AnalyticsEvents.screenViewed, {
        'screen': 'design_diary',
        'room_id': widget.roomId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Design Diary')),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }
          return PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage:
                "Unlock the Design Diary to capture your room's "
                'transformation journey',
            child: _DiaryContent(
              roomId: widget.roomId,
              roomName: room.name,
              heroColourHex: room.heroColourHex,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}

// ── Content ──────────────────────────────────────────────────────────────

class _DiaryContent extends ConsumerWidget {
  const _DiaryContent({
    required this.roomId,
    required this.roomName,
    required this.heroColourHex,
  });

  final String roomId;
  final String roomName;
  final String? heroColourHex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(diaryEntriesProvider(roomId));

    return entriesAsync.when(
      data: (entries) {
        final beforeEntries = entries.where((e) => e.isBefore).toList();
        final afterEntries = entries.where((e) => e.isAfter).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _HeaderCard(
                roomName: roomName,
                beforeCount: beforeEntries.length,
                afterCount: afterEntries.length,
              ),
              const SizedBox(height: 24),

              // Before / After comparison (if both exist)
              if (beforeEntries.isNotEmpty && afterEntries.isNotEmpty) ...[
                _ComparisonCard(
                  beforeEntry: beforeEntries.first,
                  afterEntry: afterEntries.last,
                ),
                const SizedBox(height: 24),
              ],

              // Add photo buttons
              _AddPhotoButtons(
                roomId: roomId,
                roomName: roomName,
                heroColourHex: heroColourHex,
              ),
              const SizedBox(height: 24),

              // Before section
              if (beforeEntries.isNotEmpty) ...[
                Text(
                  'Before',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Where it all started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...beforeEntries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DiaryEntryCard(entry: e),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // After section
              if (afterEntries.isNotEmpty) ...[
                Text('After', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Your transformation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...afterEntries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DiaryEntryCard(entry: e),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Empty state
              if (entries.isEmpty)
                _EmptyState(
                  roomId: roomId,
                  roomName: roomName,
                  heroColourHex: heroColourHex,
                ),

              // Share button (visible when at least one before + one after)
              if (beforeEntries.isNotEmpty && afterEntries.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ShareButton(
                  roomName: roomName,
                  beforeEntry: beforeEntries.first,
                  afterEntry: afterEntries.last,
                ),
              ],

              // Educational footer
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PaletteColours.warmWhite,
                  border: Border.all(color: PaletteColours.warmGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          size: 18,
                          color: PaletteColours.sageGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Design Diary tips',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take your "before" photo from the same angle each time '
                      'for the most dramatic comparison. Natural daylight gives '
                      'the most accurate colours. Share your transformation to '
                      'inspire others on their decorating journey.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: ErrorCard()),
    );
  }
}

// ── Header Card ──────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.roomName,
    required this.beforeCount,
    required this.afterCount,
  });

  final String roomName;
  final int beforeCount;
  final int afterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(roomName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Your transformation journey',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountChip(
                icon: Icons.history,
                label: '$beforeCount before',
                colour: PaletteColours.softGoldDark,
              ),
              _CountChip(
                icon: Icons.auto_awesome,
                label: '$afterCount after',
                colour: PaletteColours.sageGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.colour,
  });

  final IconData icon;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colour,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Comparison Card ──────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.beforeEntry, required this.afterEntry});

  final DiaryEntry beforeEntry;
  final DiaryEntry afterEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletteColours.sageGreen.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.compare_outlined,
                  size: 18,
                  color: PaletteColours.sageGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Before & After',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ComparisonPhoto(entry: beforeEntry, label: 'Before'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonPhoto(entry: afterEntry, label: 'After'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonPhoto extends StatelessWidget {
  const _ComparisonPhoto({required this.entry, required this.label});

  final DiaryEntry entry;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: _PhotoImage(photoPath: entry.photoPath),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (entry.heroColourHex != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _hexToColor(entry.heroColourHex!),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PaletteColours.warmGrey,
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: PaletteColours.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Add Photo Buttons ────────────────────────────────────────────────────

class _AddPhotoButtons extends ConsumerWidget {
  const _AddPhotoButtons({
    required this.roomId,
    required this.roomName,
    required this.heroColourHex,
  });

  final String roomId;
  final String roomName;
  final String? heroColourHex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addPhoto(context, ref, 'before'),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Add Before'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletteColours.softGoldDark,
              side: const BorderSide(color: PaletteColours.softGold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addPhoto(context, ref, 'after'),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Add After'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletteColours.sageGreenDark,
              side: const BorderSide(color: PaletteColours.sageGreen),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addPhoto(
    BuildContext context,
    WidgetRef ref,
    String phase,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take photo'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Copy to app documents directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final diaryDir = Directory('${appDir.path}/diary');
    if (!diaryDir.existsSync()) {
      diaryDir.createSync(recursive: true);
    }

    final id = const Uuid().v4();
    final ext = picked.path.split('.').last;
    final destPath = '${diaryDir.path}/$id.$ext';
    await File(picked.path).copy(destPath);

    final entry = DiaryEntry(
      id: id,
      roomId: roomId,
      roomName: roomName,
      photoPath: destPath,
      phase: phase,
      heroColourHex: heroColourHex,
      createdAt: DateTime.now(),
    );

    await ref.read(diaryRepositoryProvider).insert(entry);
    ref.read(analyticsProvider).track(AnalyticsEvents.diaryEntryAdded, {
      'room_id': roomId,
      'phase': phase,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${phase == 'before' ? 'Before' : 'After'} photo added',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Diary Entry Card ─────────────────────────────────────────────────────

class _DiaryEntryCard extends ConsumerWidget {
  const _DiaryEntryCard({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.warmGrey),
        boxShadow: const [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _PhotoImage(photoPath: entry.photoPath),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Hero colour swatch
                if (entry.heroColourHex != null) ...[
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _hexToColor(entry.heroColourHex!),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: PaletteColours.warmGrey,
                        width: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Date
                Text(
                  _formatDate(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),

                // Caption
                if (entry.caption != null) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '\u2022',
                    style: TextStyle(color: PaletteColours.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.caption!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDelete(context, ref),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  color: PaletteColours.textSecondary,
                  tooltip: 'Delete photo',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete photo?'),
            content: const Text(
              'This will permanently remove this photo from your diary.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Delete the file
      final file = File(entry.photoPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      await ref.read(diaryRepositoryProvider).delete(entry.id);
      ref.read(analyticsProvider).track(AnalyticsEvents.diaryEntryDeleted, {
        'room_id': entry.roomId,
        'phase': entry.phase,
      });
    }
  }
}

// ── Empty State ──────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  const _EmptyState({
    required this.roomId,
    required this.roomName,
    required this.heroColourHex,
  });

  final String roomId;
  final String roomName;
  final String? heroColourHex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletteColours.softGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: PaletteColours.softGold,
          ),
          const SizedBox(height: 16),
          Text(
            'Start your Design Diary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture a "before" photo of your room now, then add '
            '"after" photos as you decorate. Share your transformation '
            'to inspire others.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share Button ─────────────────────────────────────────────────────────

class _ShareButton extends ConsumerWidget {
  const _ShareButton({
    required this.roomName,
    required this.beforeEntry,
    required this.afterEntry,
  });

  final String roomName;
  final DiaryEntry beforeEntry;
  final DiaryEntry afterEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _share(context, ref),
        icon: const Icon(Icons.share_outlined, size: 18),
        label: const Text('Share your transformation'),
        style: FilledButton.styleFrom(
          backgroundColor: PaletteColours.sageGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final files = <XFile>[];

    final beforeFile = File(beforeEntry.photoPath);
    if (beforeFile.existsSync()) {
      files.add(XFile(beforeEntry.photoPath));
    }

    final afterFile = File(afterEntry.photoPath);
    if (afterFile.existsSync()) {
      files.add(XFile(afterEntry.photoPath));
    }

    if (files.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos not found on device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await Share.shareXFiles(
      files,
      text: 'My $roomName transformation, powered by Palette',
    );

    ref.read(analyticsProvider).track(AnalyticsEvents.diaryShared, {
      'room_name': roomName,
      'photo_count': files.length,
    });
  }
}

// ── Photo Image Widget ───────────────────────────────────────────────────

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    if (!file.existsSync()) {
      return const ColoredBox(
        color: PaletteColours.warmGrey,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: PaletteColours.textSecondary,
            size: 32,
          ),
        ),
      );
    }
    return Image.file(file, fit: BoxFit.cover);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

Color _hexToColor(String hex) {
  return hexToColor(hex);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
