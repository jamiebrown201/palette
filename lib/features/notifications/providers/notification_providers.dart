import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/user_profile.dart';
import 'package:palette/features/notifications/logic/prompt_engine.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/samples/providers/sample_list_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

/// The prompt engine singleton.
@Riverpod(keepAlive: true)
PromptEngine promptEngine(Ref ref) => const PromptEngine();

/// Reactive stream of the user profile (for notification settings UI).
@riverpod
Stream<UserProfile> userProfileStream(Ref ref) =>
    ref.watch(userProfileRepositoryProvider).watchProfile();

/// The current highest-priority in-app prompt (or null).
@riverpod
Future<InAppPrompt?> currentPrompt(Ref ref) async {
  final profile = await ref.watch(userProfileRepositoryProvider).getOrCreate();
  final rooms = ref.watch(allRoomsProvider).valueOrNull ?? [];
  final samples = ref.watch(sampleListProvider).valueOrNull ?? [];
  final engine = ref.watch(promptEngineProvider);

  return engine.evaluate(
    profile: profile,
    rooms: rooms,
    samples: samples,
    now: DateTime.now(),
  );
}
