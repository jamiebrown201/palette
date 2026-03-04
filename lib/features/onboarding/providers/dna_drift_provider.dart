import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/features/onboarding/logic/dna_drift.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dna_drift_provider.g.dart';

/// Computes the current DNA drift from recent colour interactions.
/// Returns null if DNA is unavailable or there are too few interactions.
@riverpod
Future<DnaDrift?> dnaDrift(Ref ref) async {
  final dna = await ref.watch(latestColourDnaProvider.future);
  if (dna == null) return null;

  final repo = ref.watch(colourInteractionRepositoryProvider);
  final interactions = await repo.getRecentInteractions(limit: 50);
  if (interactions.isEmpty) return null;

  return computeDrift(dna, interactions);
}

/// Whether the drift prompt should be shown on the home screen.
///
/// Conditions:
/// - DNA exists
/// - Overall drift > 0.6
/// - At least 20 interactions
/// - Last prompt dismissal > 30 days ago (or never dismissed)
@riverpod
Future<bool> shouldShowDriftPrompt(Ref ref) async {
  final dna = await ref.watch(latestColourDnaProvider.future);
  if (dna == null) return false;

  final interactionRepo = ref.watch(colourInteractionRepositoryProvider);
  final interactions = await interactionRepo.getRecentInteractions(limit: 50);
  if (interactions.length < 20) return false;

  final drift = computeDrift(dna, interactions);
  if (drift.overallDrift <= 0.6) return false;

  // Check if prompt was recently dismissed
  final profileRepo = ref.watch(userProfileRepositoryProvider);
  final profile = await profileRepo.getOrCreate();
  if (profile.driftPromptDismissedAt != null) {
    final daysSinceDismissal =
        DateTime.now().difference(profile.driftPromptDismissedAt!).inDays;
    if (daysSinceDismissal < 30) return false;
  }

  return true;
}
