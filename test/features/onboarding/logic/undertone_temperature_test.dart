import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/undertone_temperature.dart';

void main() {
  group('deriveUndertoneTemperature', () {
    test('empty tally returns neutral', () {
      expect(deriveUndertoneTemperature({}), Undertone.neutral);
    });

    test('single entry returns that undertone', () {
      expect(deriveUndertoneTemperature({Undertone.warm: 5}), Undertone.warm);
    });

    test('clear warm winner returns warm', () {
      expect(
        deriveUndertoneTemperature({Undertone.warm: 10, Undertone.cool: 3}),
        Undertone.warm,
      );
    });

    test('clear cool winner returns cool', () {
      expect(
        deriveUndertoneTemperature({Undertone.cool: 8, Undertone.warm: 2}),
        Undertone.cool,
      );
    });

    test('gap of exactly 2 returns neutral', () {
      expect(
        deriveUndertoneTemperature({Undertone.warm: 7, Undertone.cool: 5}),
        Undertone.neutral,
      );
    });

    test('gap of 1 returns neutral', () {
      expect(
        deriveUndertoneTemperature({Undertone.warm: 6, Undertone.cool: 5}),
        Undertone.neutral,
      );
    });

    test('tied scores return neutral', () {
      expect(
        deriveUndertoneTemperature({Undertone.warm: 5, Undertone.cool: 5}),
        Undertone.neutral,
      );
    });

    test('gap of 3 returns the winner', () {
      expect(
        deriveUndertoneTemperature({Undertone.cool: 8, Undertone.warm: 5}),
        Undertone.cool,
      );
    });

    test('three entries with clear winner', () {
      expect(
        deriveUndertoneTemperature({
          Undertone.warm: 10,
          Undertone.neutral: 3,
          Undertone.cool: 2,
        }),
        Undertone.warm,
      );
    });
  });

  group('deriveSaturationPreference', () {
    test('empty tally returns mid', () {
      expect(deriveSaturationPreference({}), ChromaBand.mid);
    });

    test('single muted entry returns muted', () {
      expect(
        deriveSaturationPreference({ChromaBand.muted: 5}),
        ChromaBand.muted,
      );
    });

    test('single bold entry returns bold', () {
      expect(deriveSaturationPreference({ChromaBand.bold: 3}), ChromaBand.bold);
    });

    test('clear muted winner returns muted', () {
      expect(
        deriveSaturationPreference({
          ChromaBand.muted: 8,
          ChromaBand.mid: 3,
          ChromaBand.bold: 1,
        }),
        ChromaBand.muted,
      );
    });

    test('clear bold winner returns bold', () {
      expect(
        deriveSaturationPreference({ChromaBand.bold: 7, ChromaBand.muted: 2}),
        ChromaBand.bold,
      );
    });

    test('tied top two returns mid', () {
      expect(
        deriveSaturationPreference({ChromaBand.muted: 5, ChromaBand.bold: 5}),
        ChromaBand.mid,
      );
    });

    test('tied muted and mid returns mid', () {
      expect(
        deriveSaturationPreference({ChromaBand.muted: 4, ChromaBand.mid: 4}),
        ChromaBand.mid,
      );
    });

    test('deterministic tiebreaker uses enum index', () {
      // If bold and muted are tied, mid is returned (not dependent on index)
      expect(
        deriveSaturationPreference({ChromaBand.bold: 6, ChromaBand.muted: 6}),
        ChromaBand.mid,
      );
    });
  });
}
