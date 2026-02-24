import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'colour_wheel_providers.g.dart';

/// All paint colours, cached for wheel matching.
@Riverpod(keepAlive: true)
Future<List<PaintColour>> allPaintColours(Ref ref) {
  return ref.watch(paintColourRepositoryProvider).getAll();
}

/// White paint colours (LRV > 70 or name contains "white").
@riverpod
Future<List<PaintColour>> whitePaintColours(Ref ref) async {
  final all = await ref.watch(allPaintColoursProvider.future);
  return all.where((pc) => pc.lrv > 70 || pc.name.toLowerCase().contains('white')).toList();
}

/// White paint colours grouped by undertone family.
@riverpod
Future<Map<WhiteUndertone, List<PaintColour>>> whitesByUndertone(Ref ref) async {
  final whites = await ref.watch(whitePaintColoursProvider.future);
  final grouped = <WhiteUndertone, List<PaintColour>>{
    WhiteUndertone.blue: [],
    WhiteUndertone.pink: [],
    WhiteUndertone.yellow: [],
    WhiteUndertone.grey: [],
  };

  for (final white in whites) {
    final family = _classifyWhiteUndertone(white);
    grouped[family]!.add(white);
  }

  return grouped;
}

/// Classify a white paint into its undertone family based on Lab a*/b*.
WhiteUndertone _classifyWhiteUndertone(PaintColour colour) {
  final a = colour.labA;
  final b = colour.labB;

  // Blue undertone: negative b* (blue-ish)
  if (b < -2) return WhiteUndertone.blue;

  // Pink undertone: positive a* (reddish)
  if (a > 2) return WhiteUndertone.pink;

  // Yellow undertone: positive b* (yellowish)
  if (b > 3) return WhiteUndertone.yellow;

  // Grey undertone: low chroma near neutral
  return WhiteUndertone.grey;
}
