import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/features/rooms/logic/renovation_sequencing.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';

class RenovationGuideScreen extends ConsumerStatefulWidget {
  const RenovationGuideScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<RenovationGuideScreen> createState() =>
      _RenovationGuideScreenState();
}

class _RenovationGuideScreenState extends ConsumerState<RenovationGuideScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider).track(AnalyticsEvents.screenViewed, {
        'screen': 'renovation_guide',
        'room_id': widget.roomId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Renovation Guide')),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }
          return PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage:
                'Unlock the Renovation Guide to see the best order '
                'for decorating your room',
            child: _GuideContent(roomId: widget.roomId),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}

class _GuideContent extends ConsumerWidget {
  const _GuideContent({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(renovationGuideProvider(roomId));

    return guideAsync.when(
      data: (guide) => _GuideView(guide: guide),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: ErrorCard()),
    );
  }
}

class _GuideView extends StatelessWidget {
  const _GuideView({required this.guide});

  final RenovationGuide guide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress card
          _ProgressCard(guide: guide),
          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  color: PaletteColours.softGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guide.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Property note
          if (guide.propertyNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PaletteColours.warmWhite,
                border: Border.all(
                  color: PaletteColours.softGold.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: PaletteColours.softGoldDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About your property',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color: PaletteColours.softGoldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guide.propertyNote!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PaletteColours.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Section header
          Text(
            'Step-by-step sequence',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            "Professional decorator's order for your room",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Steps with timeline
          ...guide.steps.asMap().entries.map(
            (entry) => _StepCard(
              step: entry.value,
              isLast: entry.key == guide.steps.length - 1,
            ),
          ),
          const SizedBox(height: 16),

          // Educational footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.warmWhite,
              border: Border.all(color: PaletteColours.warmGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: PaletteColours.sageGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why order matters',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Professional decorators always work top-down and '
                  'big-to-small. Painting before flooring avoids drips '
                  'on new floors. Placing large furniture before accessories '
                  'means you know exactly where accent pieces are needed. '
                  'Following this order saves time, money, and frustration.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Card ──────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.guide});

  final RenovationGuide guide;

  @override
  Widget build(BuildContext context) {
    final pct = guide.progressPercent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(guide.roomName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Renovation sequence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: PaletteColours.warmGrey,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColour(pct)),
            ),
          ),
          const SizedBox(height: 12),

          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusChip(
                icon: Icons.check_circle_outline,
                label: '${guide.completedCount} done',
                colour: PaletteColours.sageGreen,
              ),
              _StatusChip(
                icon: Icons.radio_button_unchecked,
                label: '${guide.totalCount - guide.completedCount} remaining',
                colour: PaletteColours.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _progressColour(double pct) {
    if (pct >= 0.75) return PaletteColours.sageGreen;
    if (pct >= 0.4) return PaletteColours.softGold;
    return PaletteColours.softGoldDark;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.colour,
  });

  final IconData icon;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colour,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Step Card ──────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isLast});

  final RenovationStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _stepCircle(context),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _timelineColour().withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColour(), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeColour().withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            step.status.label,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: _badgeColour(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),

                    // Why this order
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PaletteColours.softCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: PaletteColours.sageGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.whyThisOrder,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: PaletteColours.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cost hint
                    if (step.estimatedCostBracket != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: PaletteColours.softGoldDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              step.estimatedCostBracket!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: PaletteColours.softGoldDark,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Renter note
                    if (step.renterNote != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.key_outlined,
                            size: 14,
                            color: PaletteColours.sageGreen,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              step.renterNote!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: PaletteColours.sageGreen),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Tip
                    if (step.tip != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PaletteColours.softGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: PaletteColours.softGoldDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.tip!,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: PaletteColours.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(BuildContext context) {
    final isDone = step.status == RenovationStepStatus.done;
    final isSkipped = step.status == RenovationStepStatus.skipped;

    if (isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: PaletteColours.sageGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }

    if (isSkipped) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: PaletteColours.warmGrey,
          shape: BoxShape.circle,
          border: Border.all(color: PaletteColours.warmGrey),
        ),
        child: const Icon(
          Icons.skip_next,
          color: PaletteColours.textSecondary,
          size: 16,
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color:
            step.status == RenovationStepStatus.inProgress
                ? PaletteColours.softGold.withValues(alpha: 0.2)
                : PaletteColours.warmWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              step.status == RenovationStepStatus.inProgress
                  ? PaletteColours.softGold
                  : PaletteColours.warmGrey,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${step.order}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                step.status == RenovationStepStatus.inProgress
                    ? PaletteColours.softGoldDark
                    : PaletteColours.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _timelineColour() {
    return switch (step.status) {
      RenovationStepStatus.done => PaletteColours.sageGreen,
      RenovationStepStatus.inProgress => PaletteColours.softGold,
      RenovationStepStatus.upcoming => PaletteColours.warmGrey,
      RenovationStepStatus.skipped => PaletteColours.warmGrey,
    };
  }

  Color _borderColour() {
    return switch (step.status) {
      RenovationStepStatus.done => PaletteColours.sageGreen.withValues(
        alpha: 0.3,
      ),
      RenovationStepStatus.inProgress => PaletteColours.softGold.withValues(
        alpha: 0.5,
      ),
      RenovationStepStatus.upcoming => PaletteColours.warmGrey,
      RenovationStepStatus.skipped => PaletteColours.warmGrey,
    };
  }

  Color _badgeColour() {
    return switch (step.status) {
      RenovationStepStatus.done => PaletteColours.sageGreen,
      RenovationStepStatus.inProgress => PaletteColours.softGoldDark,
      RenovationStepStatus.upcoming => PaletteColours.textSecondary,
      RenovationStepStatus.skipped => PaletteColours.textSecondary,
    };
  }
}
