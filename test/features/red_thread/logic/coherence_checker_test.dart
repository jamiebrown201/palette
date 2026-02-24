import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';

Room _makeRoom({
  required String id,
  required String name,
  String? heroHex,
  String? betaHex,
  String? surpriseHex,
}) {
  return Room(
    id: id,
    name: name,
    usageTime: UsageTime.allDay,
    moods: const [],
    budget: BudgetBracket.midRange,
    isRenterMode: false,
    sortOrder: 0,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    heroColourHex: heroHex,
    betaColourHex: betaHex,
    surpriseColourHex: surpriseHex,
  );
}

void main() {
  group('checkCoherence', () {
    test('returns coherent when no rooms or threads', () {
      final report = checkCoherence(
        rooms: [],
        threadColours: [],
      );
      expect(report.overallCoherent, isTrue);
      expect(report.results, isEmpty);
    });

    test('returns coherent when threads empty', () {
      final report = checkCoherence(
        rooms: [_makeRoom(id: '1', name: 'Living', heroHex: '#FF0000')],
        threadColours: [],
      );
      expect(report.results, isEmpty);
    });

    test('room with matching hero colour is connected', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Living', heroHex: '#8FAE8B'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      expect(report.results.length, 1);
      expect(report.results[0].isConnected, isTrue);
      expect(report.results[0].matchingThreadHex, '#8FAE8B');
      expect(report.overallCoherent, isTrue);
    });

    test('room with similar (not exact) colour is connected within delta-E', () {
      // Slightly different shade — should still be within delta-E 15
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Living', heroHex: '#92B18E'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      expect(report.results[0].isConnected, isTrue);
    });

    test('room with no colours is disconnected', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Empty Room'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      expect(report.results[0].isConnected, isFalse);
      expect(report.overallCoherent, isFalse);
    });

    test('room with very different colour is disconnected', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Red Room', heroHex: '#FF0000'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#0000FF', sortOrder: 0),
        ],
      );

      expect(report.results[0].isConnected, isFalse);
      expect(report.overallCoherent, isFalse);
    });

    test('mixed results: some connected, some not', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Connected', heroHex: '#8FAE8B'),
          _makeRoom(id: '2', name: 'Disconnected', heroHex: '#FF0000'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      expect(report.connectedCount, 1);
      expect(report.disconnectedCount, 1);
      expect(report.overallCoherent, isFalse);
    });

    test('beta or surprise colour can connect a room', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(
            id: '1',
            name: 'Room',
            heroHex: '#FF0000',
            betaHex: '#8FAE8B',
          ),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      expect(report.results[0].isConnected, isTrue);
    });

    test('multiple thread colours checked against each room', () {
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Room A', heroHex: '#FF0000'),
          _makeRoom(id: '2', name: 'Room B', heroHex: '#0000FF'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#FF0505', sortOrder: 0),
          RedThreadColour(id: 't2', hex: '#0505FF', sortOrder: 1),
        ],
      );

      expect(report.results[0].isConnected, isTrue);
      expect(report.results[1].isConnected, isTrue);
      expect(report.overallCoherent, isTrue);
    });

    test('custom threshold changes results', () {
      // With tight threshold, similar colours may not match
      final report = checkCoherence(
        rooms: [
          _makeRoom(id: '1', name: 'Room', heroHex: '#8FAE8B'),
        ],
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#6B8A67', sortOrder: 0),
        ],
        threshold: 2.0, // Very tight
      );

      expect(report.results[0].isConnected, isFalse);
    });
  });
}
