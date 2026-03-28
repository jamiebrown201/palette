import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/moodboard.dart';
import 'package:palette/data/models/moodboard_item.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all moodboards, auto-updates on changes.
final allMoodboardsProvider = StreamProvider<List<Moodboard>>((ref) {
  return ref.watch(moodboardRepositoryProvider).watchAll();
});

/// Stream of moodboards for a specific room.
final roomMoodboardsProvider = StreamProvider.family<List<Moodboard>, String>((
  ref,
  roomId,
) {
  return ref.watch(moodboardRepositoryProvider).watchForRoom(roomId);
});

/// Stream of items for a specific moodboard.
final moodboardItemsProvider =
    StreamProvider.family<List<MoodboardItem>, String>((ref, moodboardId) {
      return ref.watch(moodboardRepositoryProvider).watchItems(moodboardId);
    });

/// Total moodboard count (for free-tier limit check).
final moodboardCountProvider = FutureProvider<int>((ref) {
  return ref.watch(moodboardRepositoryProvider).count();
});

/// Single moodboard by ID.
final moodboardByIdProvider = FutureProvider.family<Moodboard?, String>((
  ref,
  id,
) {
  return ref.watch(moodboardRepositoryProvider).getById(id);
});
