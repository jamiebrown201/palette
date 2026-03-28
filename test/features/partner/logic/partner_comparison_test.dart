import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/features/partner/logic/partner_comparison.dart';

void main() {
  final userDna = ColourDnaResult(
    id: 'user-dna',
    primaryFamily: PaletteFamily.earthTones,
    secondaryFamily: PaletteFamily.warmNeutrals,
    colourHexes: ['#C4A882', '#8B6F47', '#D4C4A8', '#5C4033'],
    completedAt: DateTime.now(),
    isComplete: true,
    archetype: ColourArchetype.theCocooner,
    undertoneTemperature: Undertone.warm,
    saturationPreference: ChromaBand.muted,
  );

  group('comparePartnerDna', () {
    test('identical profiles produce high compatibility', () {
      final partner = PartnerProfile(
        id: 'p1',
        name: 'Partner',
        inviteCode: 'ABC123',
        archetype: ColourArchetype.theCocooner,
        primaryFamily: PaletteFamily.earthTones,
        secondaryFamily: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
        colourHexes: ['#C4A882', '#8B6F47'],
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      expect(result.compatibilityScore, greaterThanOrEqualTo(70));
      expect(result.sharedFamilies, isNotEmpty);
      expect(result.undertoneMatch, isTrue);
      expect(result.summaryText, contains('aligned'));
    });

    test('opposite profiles produce low compatibility', () {
      final partner = PartnerProfile(
        id: 'p2',
        name: 'Partner',
        inviteCode: 'XYZ789',
        archetype: ColourArchetype.theMinimalist,
        primaryFamily: PaletteFamily.coolNeutrals,
        undertone: Undertone.cool,
        saturation: ChromaBand.bold,
        colourHexes: ['#9CA3AB', '#B8BFC7'],
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      expect(result.compatibilityScore, lessThan(40));
      expect(result.sharedFamilies, isEmpty);
      expect(result.undertoneMatch, isFalse);
      expect(result.userOnlyFamilies, isNotEmpty);
      expect(result.partnerOnlyFamilies, isNotEmpty);
    });

    test('partial overlap produces medium compatibility', () {
      final partner = PartnerProfile(
        id: 'p3',
        name: 'Partner',
        inviteCode: 'MID456',
        archetype: ColourArchetype.theNatureLover,
        primaryFamily: PaletteFamily.earthTones,
        secondaryFamily: PaletteFamily.pastels,
        undertone: Undertone.cool,
        saturation: ChromaBand.mid,
        colourHexes: ['#8B6F47', '#E8C4D0'],
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      // Earth Tones shared
      expect(result.sharedFamilies, contains(PaletteFamily.earthTones));
      expect(result.compatibilityScore, greaterThan(20));
      expect(result.compatibilityScore, lessThan(80));
    });

    test('tips always include at least one entry', () {
      final partner = PartnerProfile(
        id: 'p4',
        name: 'Partner',
        inviteCode: 'TIP000',
        primaryFamily: PaletteFamily.brights,
        undertone: Undertone.warm,
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      expect(result.tips, isNotEmpty);
    });

    test('summary text varies by score range', () {
      // High score
      final highPartner = PartnerProfile(
        id: 'p5',
        name: 'High',
        inviteCode: 'HI',
        archetype: ColourArchetype.theCocooner,
        primaryFamily: PaletteFamily.earthTones,
        secondaryFamily: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
      );
      final highResult = comparePartnerDna(
        userDna: userDna,
        partner: highPartner,
      );
      expect(highResult.summaryText, contains('aligned'));

      // Low score
      final lowPartner = PartnerProfile(
        id: 'p6',
        name: 'Low',
        inviteCode: 'LO',
        archetype: ColourArchetype.theMinimalist,
        primaryFamily: PaletteFamily.coolNeutrals,
        undertone: Undertone.cool,
        saturation: ChromaBand.bold,
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
      );
      final lowResult = comparePartnerDna(
        userDna: userDna,
        partner: lowPartner,
      );
      expect(lowResult.summaryText, contains('different'));
    });

    test('overlap colours detected with exact hex match', () {
      final partner = PartnerProfile(
        id: 'p7',
        name: 'Overlap',
        inviteCode: 'OVR',
        primaryFamily: PaletteFamily.earthTones,
        colourHexes: ['#C4A882', '#AAAAAA'],
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      expect(result.overlapColours, contains('#C4A882'));
    });

    test('score is clamped to 0-100', () {
      final partner = PartnerProfile(
        id: 'p8',
        name: 'Max',
        inviteCode: 'MAX',
        archetype: ColourArchetype.theCocooner,
        primaryFamily: PaletteFamily.earthTones,
        secondaryFamily: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
        colourHexes: userDna.colourHexes,
        hasCompletedQuiz: true,
        invitedAt: DateTime.now(),
      );

      final result = comparePartnerDna(userDna: userDna, partner: partner);

      expect(result.compatibilityScore, lessThanOrEqualTo(100));
      expect(result.compatibilityScore, greaterThanOrEqualTo(0));
    });
  });
}
