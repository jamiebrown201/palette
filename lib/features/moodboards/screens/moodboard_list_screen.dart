import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/app_constants.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/features/moodboards/providers/moodboard_providers.dart';
import 'package:palette/features/moodboards/widgets/moodboard_card.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Lists all moodboards with create button.
/// Free: 1 moodboard. Premium: unlimited.
class MoodboardListScreen extends ConsumerWidget {
  const MoodboardListScreen({this.roomId, super.key});

  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodboards =
        roomId != null
            ? ref.watch(roomMoodboardsProvider(roomId!))
            : ref.watch(allMoodboardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roomId != null ? 'Room Moodboards' : 'My Moodboards',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: PaletteColours.warmWhite,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: PaletteColours.warmWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createMoodboard(context, ref),
        backgroundColor: PaletteColours.sageGreen,
        foregroundColor: PaletteColours.textOnAccent,
        tooltip: 'Create moodboard',
        child: const Icon(Icons.add),
      ),
      body: moodboards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: PaletteColours.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load moodboards',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        data:
            (boards) =>
                boards.isEmpty
                    ? _EmptyState(onTap: () => _createMoodboard(context, ref))
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        return MoodboardCard(
                          moodboard: board,
                          onTap: () => context.push('/moodboards/${board.id}'),
                          onDelete:
                              () => _deleteMoodboard(context, ref, board.id),
                        );
                      },
                    ),
      ),
    );
  }

  Future<void> _createMoodboard(BuildContext context, WidgetRef ref) async {
    final tier = ref.read(subscriptionTierProvider);
    final count = await ref.read(moodboardRepositoryProvider).count();

    if (!(tier >= SubscriptionTier.plus) &&
        count >= AppConstants.maxFreeMoodboards) {
      if (context.mounted) {
        context.push('/paywall');
      }
      return;
    }

    if (!context.mounted) return;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _CreateMoodboardDialog(roomId: roomId),
    );

    if (name == null || name.trim().isEmpty) return;

    final id = const Uuid().v4();
    final now = DateTime.now();
    await ref
        .read(moodboardRepositoryProvider)
        .create(
          MoodboardsCompanion.insert(
            id: id,
            name: name.trim(),
            roomId: Value(roomId),
            roomName: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );

    if (context.mounted) {
      context.push('/moodboards/$id');
    }
  }

  Future<void> _deleteMoodboard(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete moodboard?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: PaletteColours.destructive,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ref.read(moodboardRepositoryProvider).delete(id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 64,
              color: PaletteColours.sageGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No moodboards yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Collect colour swatches, images, and product ideas\ninto a visual board for each room.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Create moodboard'),
              style: FilledButton.styleFrom(
                backgroundColor: PaletteColours.sageGreen,
                foregroundColor: PaletteColours.textOnAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateMoodboardDialog extends StatefulWidget {
  const _CreateMoodboardDialog({this.roomId});

  final String? roomId;

  @override
  State<_CreateMoodboardDialog> createState() => _CreateMoodboardDialogState();
}

class _CreateMoodboardDialogState extends State<_CreateMoodboardDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New moodboard'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 100,
        decoration: const InputDecoration(
          hintText: 'e.g. Living Room Ideas',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
