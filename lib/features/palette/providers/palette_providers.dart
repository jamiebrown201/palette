import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/palette_colour.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of the latest Colour DNA result.
final latestColourDnaProvider = StreamProvider<ColourDnaResult?>((ref) {
  return ref.watch(colourDnaRepositoryProvider).watchLatest();
});

/// Stream of palette colours for the current DNA result.
final paletteColoursProvider =
    StreamProvider.family<List<PaletteColour>, String>((ref, resultId) {
  return ref.watch(paletteRepositoryProvider).watchForResult(resultId);
});
