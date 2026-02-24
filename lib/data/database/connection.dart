import 'dart:io';

import 'package:drift/native.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the Drift database using a native SQLite file.
Future<PaletteDatabase> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'palette.sqlite'));
  final executor = NativeDatabase.createInBackground(file);
  return PaletteDatabase(executor);
}
