import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/services/seed_data_service.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seed_data_providers.g.dart';

@Riverpod(keepAlive: true)
SeedDataService seedDataService(Ref ref) {
  final db = ref.watch(paletteDatabaseProvider);
  final paintRepo = ref.watch(paintColourRepositoryProvider);
  return SeedDataService(db, paintRepo);
}
