import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/feature_flags/experiment.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/feature_flag_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({this.triggerSource, super.key});

  /// Where the paywall was opened from (e.g. 'room_detail', 'red_thread').
  final String? triggerSource;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _blurAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallViewed, {
      if (widget.triggerSource != null) 'trigger_source': widget.triggerSource,
    });
    // Track A/B experiment exposure once on mount (not in build)
    final flags = ref.read(featureFlagProvider);
    flags.trackExposure(Experiments.paywallCopy);
    flags.trackExposure(Experiments.defaultBillingPeriod);
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _blurAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _dismiss() {
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallDismissed);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = ref.watch(subscriptionTierProvider);
    final roomsAsync = ref.watch(allRoomsProvider);

    ref.listen<SubscriptionTier>(subscriptionTierProvider, (prev, next) {
      if (prev != null && prev != next) {
        ref.read(analyticsProvider).track(AnalyticsEvents.upgradeCompleted, {
          'tier': next.name,
        });
      }
    });

    // A/B test: paywall copy variant (spec 1E.2)
    final copyVariant = ref
        .read(featureFlagProvider)
        .variant(Experiments.paywallCopy);

    final (headline, subtitle) = _paywallCopyForVariant(copyVariant);

    return Scaffold(
      backgroundColor: PaletteColours.warmWhite,
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _dismiss),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          children: [
            // Visual hero — personalised blurred preview with reveal animation
            _VisualHero(
              rooms: roomsAsync.valueOrNull ?? [],
              blurAnimation: _blurAnimation,
              opacityAnimation: _opacityAnimation,
            ),
            const SizedBox(height: 24),

            // Outcome headline (A/B tested)
            Text(
              headline,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tier cards — Plus (recommended), Pro, Project Pass
            // Free tier omitted from paywall — users are already free
            _PlusTierCard(
              isCurrent: currentTier == SubscriptionTier.plus,
              onSelect: () {
                ref.read(analyticsProvider).track(
                  AnalyticsEvents.upgradeTapped,
                  {'tier': 'plus'},
                );
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.plus;
                context.pop();
              },
            ),
            const SizedBox(height: 12),

            _ProTierCard(
              isCurrent: currentTier == SubscriptionTier.pro,
              onSelect: () {
                ref.read(analyticsProvider).track(
                  AnalyticsEvents.upgradeTapped,
                  {'tier': 'pro'},
                );
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.pro;
                context.pop();
              },
            ),
            const SizedBox(height: 12),

            _ProjectPassCard(
              isCurrent: currentTier == SubscriptionTier.projectPass,
              onSelect: () {
                ref.read(analyticsProvider).track(
                  AnalyticsEvents.upgradeTapped,
                  {'tier': 'project_pass'},
                );
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.projectPass;
                context.pop();
              },
            ),
            const SizedBox(height: 20),

            // Price anchor
            Text(
              'Less than a Farrow & Ball sample pot per month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.softGoldDark,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscriptions are managed through your app store. '
              'Cancel anytime.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns (headline, subtitle) based on the paywall copy A/B variant.
  (String, String) _paywallCopyForVariant(String variant) {
    return switch (variant) {
      'feature_list' => (
        'Unlock your full design toolkit',
        'Light-matched recommendations, 70/20/10 planning, and '
            'whole-home colour flow for every room',
      ),
      'social_proof' => (
        'Join thousands planning with confidence',
        'Homeowners like you use Palette to avoid costly mistakes '
            'and create rooms they love',
      ),
      // 'outcome_led' (control) and fallback
      _ => (
        'Avoid expensive colour mistakes',
        'Get personalised recommendations for every room in your home',
      ),
    };
  }
}

/// Animated visual hero showing user's room data, blurred then partially revealed.
class _VisualHero extends StatelessWidget {
  const _VisualHero({
    required this.rooms,
    required this.blurAnimation,
    required this.opacityAnimation,
  });

  final List<Room> rooms;
  final Animation<double> blurAnimation;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    // Show rooms with hero colours, or a placeholder if no rooms yet
    final roomsWithColour =
        rooms.where((r) => r.heroColourHex != null).toList();

    return AnimatedBuilder(
      animation: Listenable.merge([blurAnimation, opacityAnimation]),
      builder: (context, child) {
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PaletteColours.softCream, PaletteColours.softGoldLight],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // The room data preview — initially visible, then blurred
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurAnimation.value,
                    sigmaY: blurAnimation.value,
                  ),
                  child:
                      roomsWithColour.isNotEmpty
                          ? _RoomPreviewContent(rooms: roomsWithColour)
                          : _PlaceholderPreview(),
                ),
              ),
              // CTA overlay — fades in as content blurs
              Positioned.fill(
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: PaletteColours.softCream.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 32,
                            color: PaletteColours.premiumGold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            roomsWithColour.isNotEmpty
                                ? 'Your personalised colour plan'
                                : 'Unlock your colour plan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Light-matched recommendations for every room',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows actual room data in the hero — room names, directions, hero colours.
class _RoomPreviewContent extends StatelessWidget {
  const _RoomPreviewContent({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your rooms',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: PaletteColours.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ...rooms.take(3).map((room) => _RoomPreviewRow(room: room)),
        ],
      ),
    );
  }
}

class _RoomPreviewRow extends StatelessWidget {
  const _RoomPreviewRow({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  room.heroColourHex != null
                      ? hexToColor(room.heroColourHex!)
                      : PaletteColours.warmGrey,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PaletteColours.divider),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              room.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (room.direction != null)
            Text(
              '${room.direction!.abbreviation}-facing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder when user has no rooms yet.
class _PlaceholderPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your colour plan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: PaletteColours.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _placeholderSwatch(PaletteColours.softGoldLight),
              const SizedBox(width: 8),
              _placeholderSwatch(PaletteColours.sageGreen),
              const SizedBox(width: 8),
              _placeholderSwatch(PaletteColours.softGold),
              const SizedBox(width: 8),
              _placeholderSwatch(PaletteColours.sageGreenDark),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: 140,
            decoration: BoxDecoration(
              color: PaletteColours.warmGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            width: 100,
            decoration: BoxDecoration(
              color: PaletteColours.warmGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholderSwatch(Color colour) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Plus tier — the recommended tier. Outcome-focused, warm accent CTA.
class _PlusTierCard extends StatelessWidget {
  const _PlusTierCard({required this.isCurrent, required this.onSelect});

  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletteColours.premiumGold, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Palette Plus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PaletteColours.premiumGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCurrent ? 'Current' : 'Recommended',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Plan every room with confidence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _featureBullet(context, 'Light-matched colour recommendations'),
          _featureBullet(
            context,
            '${BrandedTerms.seventyTwentyTen} colour planner',
          ),
          _featureBullet(context, '${BrandedTerms.redThread} whole-home flow'),
          _featureBullet(context, 'Edit & customise your palette'),
          _featureBullet(context, 'Export room plans as PDF'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\u00A33.99',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PaletteColours.textPrimary,
                ),
              ),
              Text(
                '/month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'or \u00A329.99/year (save 37%)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
              ),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: PaletteColours.softGoldDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start 14-day free trial',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'After your free trial, Plus renews at £3.99/month '
              '(billed annually at £47.88). Cancel any time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: PaletteColours.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pro tier — shorter, outcome-focused.
class _ProTierCard extends StatelessWidget {
  const _ProTierCard({required this.isCurrent, required this.onSelect});

  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Palette Pro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PaletteColours.sageGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Current',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Know exactly what to buy for every room',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _featureBullet(context, 'Everything in Plus'),
          _featureBullet(
            context,
            'Product recommendations per room',
            comingSoon: true,
          ),
          _featureBullet(context, 'AI Room Visualiser', comingSoon: true),
          _featureBullet(
            context,
            'Paint & Finish Recommender',
            comingSoon: true,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\u00A37.99',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PaletteColours.textPrimary,
                ),
              ),
              Text(
                '/month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'or \u00A359.99/year (save 37%)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
              ),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSelect,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Choose Pro'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Project Pass — compact card.
class _ProjectPassCard extends StatelessWidget {
  const _ProjectPassCard({required this.isCurrent, required this.onSelect});

  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Project Pass',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PaletteColours.sageGreenLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: PaletteColours.sageGreenDark),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '6 months of Palette Pro \u2022 \u00A324.99 one-time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perfect for a single decorating project',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PaletteColours.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            OutlinedButton(onPressed: onSelect, child: const Text('Get')),
        ],
      ),
    );
  }
}

/// Reusable feature bullet with check icon.
Widget _featureBullet(
  BuildContext context,
  String text, {
  bool comingSoon = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            comingSoon ? Icons.schedule : Icons.check_circle_outline,
            size: 16,
            color:
                comingSoon
                    ? PaletteColours.textTertiary
                    : PaletteColours.sageGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: comingSoon ? PaletteColours.textTertiary : null,
            ),
          ),
        ),
      ],
    ),
  );
}
