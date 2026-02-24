import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/app.dart';
import 'package:palette/data/database/connection.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/services/seed_data_service.dart';
import 'package:palette/providers/database_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await openDatabase();

  // Seed paint colour data on first launch.
  final paintRepo = PaintColourRepository(db);
  final seedService = SeedDataService(db, paintRepo);
  await seedService.seedIfNeeded();

  runApp(
    ProviderScope(
      overrides: [
        paletteDatabaseProvider.overrideWithValue(db),
      ],
      child: const PaletteApp(),
    ),
  );
}
