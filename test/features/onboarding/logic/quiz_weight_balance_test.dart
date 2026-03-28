import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';

void main() {
  late Map<String, dynamic> quizData;
  late List<dynamic> memoryPrompts;
  late List<dynamic> visualPreferences;

  setUpAll(() {
    final file = File('assets/data/quiz_content.json');
    quizData = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    memoryPrompts = quizData['memoryPrompts'] as List<dynamic>;
    visualPreferences = quizData['visualPreferences'] as List<dynamic>;
  });

  /// Collect all cards from all memory prompts into a flat list.
  List<Map<String, dynamic>> allMemoryCards() {
    final cards = <Map<String, dynamic>>[];
    for (final prompt in memoryPrompts) {
      for (final card in (prompt as Map<String, dynamic>)['cards'] as List) {
        cards.add(card as Map<String, dynamic>);
      }
    }
    return cards;
  }

  /// Sum total weight per family across all cards (memory + visual).
  Map<PaletteFamily, int> totalWeightDistribution() {
    final totals = <PaletteFamily, int>{};

    void addWeights(Map<String, dynamic> card) {
      final weights = card['familyWeights'] as Map<String, dynamic>;
      for (final entry in weights.entries) {
        final family = PaletteFamily.values.byName(entry.key);
        totals[family] = (totals[family] ?? 0) + (entry.value as int);
      }
    }

    for (final card in allMemoryCards()) {
      addWeights(card);
    }
    for (final card in visualPreferences) {
      addWeights(card as Map<String, dynamic>);
    }

    return totals;
  }

  group('quiz content weight balance', () {
    test('no family exceeds 25% of total weight', () {
      final totals = totalWeightDistribution();
      final grandTotal = totals.values.fold<int>(0, (a, b) => a + b);

      for (final entry in totals.entries) {
        final percent = entry.value / grandTotal * 100;
        expect(
          percent,
          lessThanOrEqualTo(25),
          reason:
              '${entry.key.name} is ${percent.toStringAsFixed(1)}% '
              '(${entry.value}/$grandTotal) — exceeds 25% limit',
        );
      }
    });

    test('no family falls below 10% of total weight', () {
      final totals = totalWeightDistribution();
      final grandTotal = totals.values.fold<int>(0, (a, b) => a + b);

      for (final family in PaletteFamily.values) {
        final weight = totals[family] ?? 0;
        final percent = weight / grandTotal * 100;
        expect(
          percent,
          greaterThanOrEqualTo(10),
          reason:
              '${family.name} is ${percent.toStringAsFixed(1)}% '
              '($weight/$grandTotal) — below 10% minimum',
        );
      }
    });

    test('every family appears in at least 4 cards', () {
      final familyCardCounts = <PaletteFamily, int>{};

      void countCard(Map<String, dynamic> card) {
        final weights = card['familyWeights'] as Map<String, dynamic>;
        for (final key in weights.keys) {
          final family = PaletteFamily.values.byName(key);
          familyCardCounts[family] = (familyCardCounts[family] ?? 0) + 1;
        }
      }

      for (final card in allMemoryCards()) {
        countCard(card);
      }
      for (final card in visualPreferences) {
        countCard(card as Map<String, dynamic>);
      }

      for (final family in PaletteFamily.values) {
        final count = familyCardCounts[family] ?? 0;
        expect(
          count,
          greaterThanOrEqualTo(4),
          reason:
              '${family.name} appears in only $count cards '
              '(need at least 4 for viable quiz paths)',
        );
      }
    });

    test('all memory prompt cards have required fields', () {
      for (final card in allMemoryCards()) {
        expect(
          card.containsKey('id'),
          isTrue,
          reason: 'Card missing id: $card',
        );
        expect(
          card.containsKey('label'),
          isTrue,
          reason: 'Card missing label: ${card['id']}',
        );
        expect(
          card.containsKey('hex'),
          isTrue,
          reason: 'Card missing hex: ${card['id']}',
        );
        expect(
          card.containsKey('undertoneTemp'),
          isTrue,
          reason: 'Card missing undertoneTemp: ${card['id']}',
        );
        expect(
          card.containsKey('chromaBand'),
          isTrue,
          reason: 'Card missing chromaBand: ${card['id']}',
        );
        expect(
          card.containsKey('familyWeights'),
          isTrue,
          reason: 'Card missing familyWeights: ${card['id']}',
        );
      }
    });

    test('all visual preference cards have required fields', () {
      for (final card in visualPreferences) {
        final c = card as Map<String, dynamic>;
        expect(c.containsKey('id'), isTrue, reason: 'Card missing id: $c');
        expect(
          c.containsKey('description'),
          isTrue,
          reason: 'Card missing description: ${c['id']}',
        );
        expect(
          c.containsKey('undertoneTemp'),
          isTrue,
          reason: 'Card missing undertoneTemp: ${c['id']}',
        );
        expect(
          c.containsKey('chromaBand'),
          isTrue,
          reason: 'Card missing chromaBand: ${c['id']}',
        );
        expect(
          c.containsKey('familyWeights'),
          isTrue,
          reason: 'Card missing familyWeights: ${c['id']}',
        );
      }
    });
  });

  group('quiz pure-path viability', () {
    test('every PaletteFamily can become primary via plausible quiz path', () {
      // For each family, pick the best card from each memory prompt
      // plus the best visual preference cards, and verify the family wins.
      for (final targetFamily in PaletteFamily.values) {
        // Pick the card with the highest weight for targetFamily from each prompt
        final selectedWeights = <Map<String, int>>[];

        for (final prompt in memoryPrompts) {
          final cards =
              (prompt as Map<String, dynamic>)['cards'] as List<dynamic>;
          Map<String, dynamic>? bestCard;
          var bestWeight = 0;

          for (final card in cards) {
            final c = card as Map<String, dynamic>;
            final weights = c['familyWeights'] as Map<String, dynamic>;
            final w = (weights[targetFamily.name] as int?) ?? 0;
            if (w > bestWeight) {
              bestWeight = w;
              bestCard = c;
            }
          }

          if (bestCard != null) {
            final weights = bestCard['familyWeights'] as Map<String, dynamic>;
            selectedWeights.add(weights.map((k, v) => MapEntry(k, v as int)));
          }
        }

        // Also pick the best 2 visual preference cards
        final vpScored = <(int, Map<String, dynamic>)>[];
        for (final card in visualPreferences) {
          final c = card as Map<String, dynamic>;
          final weights = c['familyWeights'] as Map<String, dynamic>;
          final w = (weights[targetFamily.name] as int?) ?? 0;
          vpScored.add((w, c));
        }
        vpScored.sort((a, b) => b.$1.compareTo(a.$1));

        for (final entry in vpScored.take(2)) {
          if (entry.$1 > 0) {
            final weights = entry.$2['familyWeights'] as Map<String, dynamic>;
            selectedWeights.add(weights.map((k, v) => MapEntry(k, v as int)));
          }
        }

        // Tally the weights
        final familyWeights = tallyFamilyWeights(selectedWeights);

        // Find the top family
        final sorted =
            familyWeights.entries.toList()..sort((a, b) {
              final cmp = b.value.compareTo(a.value);
              return cmp != 0 ? cmp : a.key.index.compareTo(b.key.index);
            });

        expect(
          sorted.isNotEmpty && sorted.first.key == targetFamily,
          isTrue,
          reason:
              '${targetFamily.name} could not become primary. '
              'Best path produced: ${sorted.map((e) => "${e.key.name}:${e.value}").join(", ")}',
        );
      }
    });
  });
}
