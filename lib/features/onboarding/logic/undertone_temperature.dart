import 'package:palette/core/constants/enums.dart';

/// Derive the user's undertone temperature preference from their quiz tally.
///
/// Winner takes all; if the gap between the top two is ≤ 2, returns
/// [Undertone.neutral] as a flexible default.
Undertone deriveUndertoneTemperature(Map<Undertone, int> tally) {
  if (tally.isEmpty) return Undertone.neutral;

  final sorted = tally.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = sorted.first;

  // If only one entry or clear winner
  if (sorted.length < 2) return top.key;

  final second = sorted[1];
  final gap = top.value - second.value;

  if (gap <= 2) return Undertone.neutral;
  return top.key;
}

/// Derive the user's saturation/chroma preference from their quiz tally.
///
/// Winner takes all. If tied between two bands, defaults to [ChromaBand.mid]
/// as a safe middle ground.
ChromaBand deriveSaturationPreference(Map<ChromaBand, int> tally) {
  if (tally.isEmpty) return ChromaBand.mid;

  final sorted = tally.entries.toList()
    ..sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      // Deterministic tiebreaker: enum index
      return cmp != 0 ? cmp : a.key.index.compareTo(b.key.index);
    });

  final top = sorted.first;

  // If only one entry, clear winner
  if (sorted.length < 2) return top.key;

  final second = sorted[1];

  // If tied, default to mid
  if (top.value == second.value) return ChromaBand.mid;

  return top.key;
}
