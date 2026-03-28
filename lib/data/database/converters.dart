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
    return fromDb
        .split(',')
        .map((e) => _safeByName(RoomMood.values, e))
        .nonNulls
        .toList();
  }

  @override
  String toSql(List<RoomMood> value) {
    return value.map((e) => e.name).join(',');
  }
}

/// Converts a [List<ProductMaterial>] to/from a comma-separated [String].
class ProductMaterialListConverter
    extends TypeConverter<List<ProductMaterial>, String> {
  const ProductMaterialListConverter();

  @override
  List<ProductMaterial> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb
        .split(',')
        .map((e) => _safeByName(ProductMaterial.values, e))
        .nonNulls
        .toList();
  }

  @override
  String toSql(List<ProductMaterial> value) {
    return value.map((e) => e.name).join(',');
  }
}

/// Converts a [List<ProductStyle>] to/from a comma-separated [String].
class ProductStyleListConverter
    extends TypeConverter<List<ProductStyle>, String> {
  const ProductStyleListConverter();

  @override
  List<ProductStyle> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb
        .split(',')
        .map((e) => _safeByName(ProductStyle.values, e))
        .nonNulls
        .toList();
  }

  @override
  String toSql(List<ProductStyle> value) {
    return value.map((e) => e.name).join(',');
  }
}

/// Safely look up an enum value by name, returning null if not found.
T? _safeByName<T extends Enum>(List<T> values, String name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
