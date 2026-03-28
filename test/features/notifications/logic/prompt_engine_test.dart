import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/sample_list_item.dart';
import 'package:palette/data/models/user_profile.dart';
import 'package:palette/features/notifications/logic/prompt_engine.dart';

UserProfile _profile({
  bool? notificationsEnabled,
  NotificationFrequency? notificationFrequency,
  DateTime? notificationOptInPromptShownAt,
  DateTime? lastPromptDismissedAt,
  DateTime? movingDate,
  DateTime? updatedAt,
}) {
  return UserProfile(
    id: 'default',
    hasCompletedOnboarding: true,
    subscriptionTier: SubscriptionTier.free,
    colourBlindMode: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 3, 15),
    notificationsEnabled: notificationsEnabled,
    notificationFrequency: notificationFrequency,
    notificationOptInPromptShownAt: notificationOptInPromptShownAt,
    lastPromptDismissedAt: lastPromptDismissedAt,
    movingDate: movingDate,
  );
}

Room _room({
  String id = 'r1',
  String name = 'Living Room',
  String? heroColourHex = '#C4A882',
}) {
  return Room(
    id: id,
    name: name,
    usageTime: UsageTime.evening,
    moods: [RoomMood.cocooning],
    budget: BudgetBracket.midRange,
    isRenterMode: false,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    heroColourHex: heroColourHex,
  );
}

SampleListItem _sample({DateTime? orderedAt, DateTime? arrivedAt}) {
  return SampleListItem(
    id: 's1',
    paintColourId: 'pc1',
    colourName: 'Savage Ground',
    colourCode: 'SG',
    brand: 'Farrow & Ball',
    hex: '#C4A882',
    addedAt: DateTime(2026, 3, 1),
    orderedAt: orderedAt,
    arrivedAt: arrivedAt,
  );
}

void main() {
  const engine = PromptEngine();

  group('PromptEngine', () {
    test('shows opt-in prompt after first room completion', () {
      final prompt = engine.evaluate(
        profile: _profile(),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 3, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.notificationOptIn);
    });

    test('does not show opt-in if already shown', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationOptInPromptShownAt: DateTime(2026, 3, 10),
          notificationsEnabled: true,
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 6, 15), // Not a seasonal month
      );

      // Should not be opt-in prompt.
      if (prompt != null) {
        expect(prompt.type, isNot(PromptType.notificationOptIn));
      }
    });

    test('does not show opt-in if no completed rooms', () {
      final prompt = engine.evaluate(
        profile: _profile(updatedAt: DateTime(2026, 6, 14)),
        rooms: [_room(heroColourHex: null)],
        samples: [],
        now: DateTime(2026, 6, 15),
      );

      // No completed room → no opt-in. No other prompts should fire either
      // (no samples, no moving date, no milestone, not Saturday, not seasonal,
      // recently active so no re-engagement).
      expect(prompt, isNull);
    });

    test('shows sample follow-up 3-5 days after ordering', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.sampleFollowUp);
    });

    test('no sample follow-up if samples already arrived', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room()],
        samples: [
          _sample(
            orderedAt: DateTime(2026, 3, 12),
            arrivedAt: DateTime(2026, 3, 14),
          ),
        ],
        now: DateTime(2026, 6, 15),
      );

      // Should not be sample follow-up.
      if (prompt != null) {
        expect(prompt.type, isNot(PromptType.sampleFollowUp));
      }
    });

    test('shows moving countdown within 90 days', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          movingDate: DateTime(2026, 7, 1),
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 6, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.movingCountdown);
      expect(prompt.message, contains('16 days'));
    });

    test('no moving countdown if date passed', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          movingDate: DateTime(2026, 1, 1),
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 6, 15),
      );

      if (prompt != null) {
        expect(prompt.type, isNot(PromptType.movingCountdown));
      }
    });

    test('shows progress celebration at 3 rooms', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [
          _room(id: 'r1'),
          _room(id: 'r2', name: 'Bedroom'),
          _room(id: 'r3', name: 'Kitchen'),
        ],
        samples: [],
        now: DateTime(2026, 6, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.progressCelebration);
      expect(prompt.title, contains('3 rooms'));
    });

    test('shows weekend project on Saturday morning', () {
      // Saturday March 21, 2026 at 9am.
      final saturday = DateTime(2026, 3, 21, 9);
      expect(saturday.weekday, DateTime.saturday);

      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room(heroColourHex: null)],
        samples: [],
        now: saturday,
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.weekendProject);
    });

    test('no weekend prompt on a Tuesday', () {
      // Tuesday June 16, 2026 at 9am.
      final tuesday = DateTime(2026, 6, 16, 9);
      expect(tuesday.weekday, DateTime.tuesday);

      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room(heroColourHex: null)],
        samples: [],
        now: tuesday,
      );

      if (prompt != null) {
        expect(prompt.type, isNot(PromptType.weekendProject));
      }
    });

    // BUG 1 fix: declined users still see in-app prompts.
    test('shows prompts even when notifications disabled (opted out)', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: false,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15),
      );

      // Should still show sample follow-up even though push is off.
      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.sampleFollowUp);
    });

    test('suppresses all prompts when frequency is off', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationFrequency: NotificationFrequency.off,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15),
      );

      expect(prompt, isNull);
    });

    // BUG 2 fix: weekly frequency extends suppress window to 7 days.
    test('weekly frequency extends suppress window to 7 days', () {
      // Dismissed 2 days ago → within 7-day window for weekly users.
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationFrequency: NotificationFrequency.weekly,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          lastPromptDismissedAt: DateTime(2026, 3, 13),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15),
      );

      expect(prompt, isNull);
    });

    test('weekly frequency allows prompts after 7 days', () {
      // Dismissed 8 days ago → outside 7-day window.
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationFrequency: NotificationFrequency.weekly,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          lastPromptDismissedAt: DateTime(2026, 3, 7),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.sampleFollowUp);
    });

    test('rate-limits prompts within 24h of last dismissal', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          lastPromptDismissedAt: DateTime(2026, 3, 15, 10),
        ),
        rooms: [_room()],
        samples: [_sample(orderedAt: DateTime(2026, 3, 12))],
        now: DateTime(2026, 3, 15, 12),
      );

      expect(prompt, isNull);
    });

    test('shows seasonal spring prompt in March', () {
      // With a non-milestone room count (2 rooms, not 3 or 5).
      final prompt2 = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room(id: 'r1'), _room(id: 'r2', name: 'Bedroom')],
        samples: [],
        now: DateTime(2026, 3, 15),
      );

      // With 2 rooms (no milestone), seasonal spring should surface.
      expect(prompt2, isNotNull);
      expect(prompt2!.type, PromptType.seasonalRefresh);
      expect(prompt2.title, contains('Spring'));
    });

    test('shows autumn prompt in October', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 10, 15),
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.seasonalRefresh);
      expect(prompt.title, contains('Autumn'));
    });

    // Re-engagement prompt.
    test('shows re-engagement after 14 days of inactivity', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 6, 15), // 45 days since last active
      );

      expect(prompt, isNotNull);
      expect(prompt!.type, PromptType.reEngagement);
    });

    test('no re-engagement if recently active', () {
      final prompt = engine.evaluate(
        profile: _profile(
          notificationsEnabled: true,
          notificationOptInPromptShownAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 6, 14),
        ),
        rooms: [_room()],
        samples: [],
        now: DateTime(2026, 6, 15), // 1 day since last active — not inactive
      );

      // Should not be re-engagement (too recent).
      if (prompt != null) {
        expect(prompt.type, isNot(PromptType.reEngagement));
      }
    });
  });
}
