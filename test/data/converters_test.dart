import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/converters.dart';

void main() {
  group('RoomMoodListConverter', () {
    const converter = RoomMoodListConverter();

    test('round-trips valid moods', () {
      final moods = [RoomMood.calm, RoomMood.energising];
      final sql = converter.toSql(moods);
      final result = converter.fromSql(sql);
      expect(result, moods);
    });

    test('returns empty list for empty string', () {
      expect(converter.fromSql(''), isEmpty);
    });

    test('skips unknown enum values without crashing', () {
      final result = converter.fromSql('calm,unknownMood,energising');
      expect(result, [RoomMood.calm, RoomMood.energising]);
    });

    test('handles all-unknown values gracefully', () {
      final result = converter.fromSql('foo,bar');
      expect(result, isEmpty);
    });
  });

  group('ProductMaterialListConverter', () {
    const converter = ProductMaterialListConverter();

    test('round-trips valid materials', () {
      final materials = [ProductMaterial.woodOak, ProductMaterial.leather];
      final sql = converter.toSql(materials);
      final result = converter.fromSql(sql);
      expect(result, materials);
    });

    test('skips unknown enum values without crashing', () {
      final result = converter.fromSql('woodOak,deletedMaterial,leather');
      expect(result, [ProductMaterial.woodOak, ProductMaterial.leather]);
    });
  });

  group('ProductStyleListConverter', () {
    const converter = ProductStyleListConverter();

    test('round-trips valid styles', () {
      final styles = [ProductStyle.modern, ProductStyle.scandi];
      final sql = converter.toSql(styles);
      final result = converter.fromSql(sql);
      expect(result, styles);
    });

    test('skips unknown enum values without crashing', () {
      final result = converter.fromSql('modern,retro,scandi');
      expect(result, [ProductStyle.modern, ProductStyle.scandi]);
    });
  });

  group('StringListConverter', () {
    const converter = StringListConverter();

    test('round-trips string list', () {
      final strings = ['a', 'b', 'c'];
      final sql = converter.toSql(strings);
      final result = converter.fromSql(sql);
      expect(result, strings);
    });

    test('returns empty list for empty string', () {
      expect(converter.fromSql(''), isEmpty);
    });
  });
}
