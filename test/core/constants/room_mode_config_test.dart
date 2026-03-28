import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/renter_constraints.dart';
import 'package:palette/core/constants/room_mode_config.dart';

void main() {
  group('RoomModeConfig.forRoom', () {
    test('returns owner config when isRenterMode is false', () {
      final config = RoomModeConfig.forRoom(
        isRenterMode: false,
        constraints: RenterConstraints.none,
      );
      expect(identical(config, RoomModeConfig.owner), isTrue);
    });

    test('returns owner config even when constraints say renter', () {
      // The room's isRenterMode flag takes precedence — a room can be
      // set to owner mode regardless of the user's global tenure.
      final config = RoomModeConfig.forRoom(
        isRenterMode: false,
        constraints: const RenterConstraints(isRenter: true, canPaint: false),
      );
      expect(identical(config, RoomModeConfig.owner), isTrue);
    });

    test('returns renterCanPaint when renter can paint', () {
      final config = RoomModeConfig.forRoom(
        isRenterMode: true,
        constraints: const RenterConstraints(isRenter: true, canPaint: true),
      );
      expect(identical(config, RoomModeConfig.renterCanPaint), isTrue);
    });

    test('returns renterCanPaint when canPaint is null (unanswered)', () {
      final config = RoomModeConfig.forRoom(
        isRenterMode: true,
        constraints: const RenterConstraints(isRenter: true),
      );
      // wallsAreLocked requires canPaint == false, null doesn't lock.
      expect(identical(config, RoomModeConfig.renterCanPaint), isTrue);
    });

    test('returns renterCantPaint when walls are locked', () {
      final config = RoomModeConfig.forRoom(
        isRenterMode: true,
        constraints: const RenterConstraints(isRenter: true, canPaint: false),
      );
      expect(identical(config, RoomModeConfig.renterCantPaint), isTrue);
    });

    test(
      'returns renterCanPaint when isRenter is false but room is renter',
      () {
        // Edge case: room toggled to renter mode but user hasn't set tenure.
        // wallsAreLocked requires isRenter && canPaint == false.
        final config = RoomModeConfig.forRoom(
          isRenterMode: true,
          constraints: const RenterConstraints(
            isRenter: false,
            canPaint: false,
          ),
        );
        expect(identical(config, RoomModeConfig.renterCanPaint), isTrue);
      },
    );
  });

  group('RoomModeConfig.owner', () {
    test('has no mode badge', () {
      expect(RoomModeConfig.owner.modeBadge, isNull);
    });

    test('does not show wall as fixed context', () {
      expect(RoomModeConfig.owner.showWallAsFixedContext, isFalse);
    });

    test('does not show landlord presets', () {
      expect(RoomModeConfig.owner.showLandlordPresets, isFalse);
    });

    test('uses White Finder title', () {
      expect(RoomModeConfig.owner.finderTitle, 'White Finder');
    });
  });

  group('RoomModeConfig.renterCanPaint', () {
    test('has Renter badge', () {
      expect(RoomModeConfig.renterCanPaint.modeBadge, 'Renter');
    });

    test('shows landlord presets', () {
      expect(RoomModeConfig.renterCanPaint.showLandlordPresets, isTrue);
    });

    test('does not show wall as fixed context', () {
      expect(RoomModeConfig.renterCanPaint.showWallAsFixedContext, isFalse);
    });

    test('uses White Finder title', () {
      expect(RoomModeConfig.renterCanPaint.finderTitle, 'White Finder');
    });
  });

  group('RoomModeConfig.renterCantPaint', () {
    test('has Renter Edition badge', () {
      expect(RoomModeConfig.renterCantPaint.modeBadge, 'Renter Edition');
    });

    test('shows wall as fixed context', () {
      expect(RoomModeConfig.renterCantPaint.showWallAsFixedContext, isTrue);
    });

    test('does not show landlord presets', () {
      expect(RoomModeConfig.renterCantPaint.showLandlordPresets, isFalse);
    });

    test('uses Neutral Finder title', () {
      expect(RoomModeConfig.renterCantPaint.finderTitle, 'Neutral Finder');
    });

    test('uses textile hero label', () {
      expect(RoomModeConfig.renterCantPaint.heroLabel, 'Key textile (70 %)');
    });

    test('uses textile red thread medium', () {
      expect(
        RoomModeConfig.renterCantPaint.redThreadMedium,
        'furnishings and textiles',
      );
    });

    test('has textile-focused preview labels', () {
      expect(
        RoomModeConfig.renterCantPaint.previewHeroLabel,
        'Rug, sofa or bedding',
      );
      expect(
        RoomModeConfig.renterCantPaint.previewBetaLabel,
        'Cushions & throws',
      );
      expect(
        RoomModeConfig.renterCantPaint.previewSurpriseLabel,
        'Art & accessories',
      );
    });
  });

  group('RoomModeConfig preview labels', () {
    test('owner has room-surface preview labels', () {
      expect(RoomModeConfig.owner.previewHeroLabel, 'Walls & curtains');
      expect(RoomModeConfig.owner.previewBetaLabel, 'Sofa & rug');
      expect(RoomModeConfig.owner.previewSurpriseLabel, 'Cushions & art');
    });

    test('renterCanPaint has fixed-walls preview labels', () {
      expect(RoomModeConfig.renterCanPaint.previewHeroLabel, 'Fixed walls');
      expect(RoomModeConfig.renterCanPaint.previewBetaLabel, 'Furnishings');
      expect(
        RoomModeConfig.renterCanPaint.previewSurpriseLabel,
        'Accents & throws',
      );
    });
  });

  group('RenterConstraints', () {
    test('wallsAreLocked is true when renter and canPaint is false', () {
      const c = RenterConstraints(isRenter: true, canPaint: false);
      expect(c.wallsAreLocked, isTrue);
    });

    test('wallsAreLocked is false when canPaint is true', () {
      const c = RenterConstraints(isRenter: true, canPaint: true);
      expect(c.wallsAreLocked, isFalse);
    });

    test('wallsAreLocked is false when canPaint is null', () {
      const c = RenterConstraints(isRenter: true);
      expect(c.wallsAreLocked, isFalse);
    });

    test('wallsAreLocked is false for non-renters', () {
      const c = RenterConstraints(isRenter: false, canPaint: false);
      expect(c.wallsAreLocked, isFalse);
    });

    test('none has isRenter false', () {
      expect(RenterConstraints.none.isRenter, isFalse);
      expect(RenterConstraints.none.wallsAreLocked, isFalse);
    });
  });
}
