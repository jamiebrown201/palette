import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';

/// Converts a [List<String>] to/from a comma-separated [String] for storage.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    return value.join(',');
  }
}

/// Converts a [List<RoomMood>] to/from a comma-separated [String] for storage.
class RoomMoodListConverter extends TypeConverter<List<RoomMood>, String> {
  const RoomMoodListConverter();

  @override
  List<RoomMood> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',').map((e) => RoomMood.values.byName(e)).toList();
  }

  @override
  String toSql(List<RoomMood> value) {
    return value.map((e) => e.name).join(',');
  }
}
