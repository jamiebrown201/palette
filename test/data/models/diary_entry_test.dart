import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/models/diary_entry.dart';

void main() {
  group('DiaryEntry', () {
    test('isBefore returns true for before phase', () {
      final entry = DiaryEntry(
        id: '1',
        roomId: 'r1',
        roomName: 'Living Room',
        photoPath: '/path/to/photo.jpg',
        phase: 'before',
        createdAt: DateTime(2026, 3, 1),
      );

      expect(entry.isBefore, isTrue);
      expect(entry.isAfter, isFalse);
    });

    test('isAfter returns true for after phase', () {
      final entry = DiaryEntry(
        id: '2',
        roomId: 'r1',
        roomName: 'Living Room',
        photoPath: '/path/to/photo.jpg',
        phase: 'after',
        createdAt: DateTime(2026, 3, 15),
      );

      expect(entry.isAfter, isTrue);
      expect(entry.isBefore, isFalse);
    });

    test('optional fields are nullable', () {
      final entry = DiaryEntry(
        id: '3',
        roomId: 'r1',
        roomName: 'Kitchen',
        photoPath: '/path/to/kitchen.jpg',
        phase: 'before',
        createdAt: DateTime(2026, 3, 1),
      );

      expect(entry.caption, isNull);
      expect(entry.heroColourHex, isNull);
    });

    test('preserves hero colour hex snapshot', () {
      final entry = DiaryEntry(
        id: '4',
        roomId: 'r1',
        roomName: 'Bedroom',
        photoPath: '/path/to/bedroom.jpg',
        phase: 'after',
        heroColourHex: '#8FAE8B',
        caption: 'After painting with Sage Green',
        createdAt: DateTime(2026, 3, 20),
      );

      expect(entry.heroColourHex, '#8FAE8B');
      expect(entry.caption, 'After painting with Sage Green');
    });

    test('entries for same room can have different phases', () {
      final before = DiaryEntry(
        id: 'b1',
        roomId: 'r1',
        roomName: 'Living Room',
        photoPath: '/path/before.jpg',
        phase: 'before',
        createdAt: DateTime(2026, 3, 1),
      );

      final after = DiaryEntry(
        id: 'a1',
        roomId: 'r1',
        roomName: 'Living Room',
        photoPath: '/path/after.jpg',
        phase: 'after',
        heroColourHex: '#C9A96E',
        createdAt: DateTime(2026, 3, 28),
      );

      expect(before.roomId, equals(after.roomId));
      expect(before.isBefore, isTrue);
      expect(after.isAfter, isTrue);
    });
  });
}
