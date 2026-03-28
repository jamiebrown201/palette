import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/sample_list_item.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all sample list items, auto-updates on changes.
final sampleListProvider = StreamProvider<List<SampleListItem>>((ref) {
  return ref.watch(sampleListRepositoryProvider).watchAll();
});

/// Whether a specific paint colour is already in the sample list.
final isInSampleListProvider = FutureProvider.family<bool, String>((
  ref,
  paintColourId,
) {
  return ref.watch(sampleListRepositoryProvider).isInList(paintColourId);
});
