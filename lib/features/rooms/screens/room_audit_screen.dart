import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/features/rooms/logic/room_audit.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';

class RoomAuditScreen extends ConsumerStatefulWidget {
  const RoomAuditScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<RoomAuditScreen> createState() => _RoomAuditScreenState();
}

class _RoomAuditScreenState extends ConsumerState<RoomAuditScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider).track(AnalyticsEvents.screenViewed, {
        'screen': 'room_audit',
        'room_id': widget.roomId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Room Audit')),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }
          return PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage:
                'Unlock the Room Audit to see how your room scores against design rules',
            child: _AuditContent(roomId: widget.roomId),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}

class _AuditContent extends ConsumerWidget {
  const _AuditContent({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(roomAuditProvider(roomId));

    return reportAsync.when(
      data: (report) => _AuditView(report: report, roomId: roomId),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: ErrorCard()),
    );
  }
}

class _AuditView extends ConsumerWidget {
  const _AuditView({required this.report, required this.roomId});

  final RoomAuditReport report;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          _ScoreCard(report: report),
          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: PaletteColours.softGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section header
          Text(
            'Design Rules',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Based on professional interior design principles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Rule cards
          ...report.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RuleCard(rule: rule),
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
                      'About the audit',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'These rules are adapted from professional design principles. '
                  'They are guidelines, not strict requirements. '
                  'A room that breaks a rule deliberately often looks better than one '
                  'that follows every rule without intention.',
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

// ── Score Card ───────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final RoomAuditReport report;

  @override
  Widget build(BuildContext context) {
    final pct = report.percentage;

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
          Text(report.roomName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Design audit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Circular progress
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 8,
                    backgroundColor: PaletteColours.warmGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _scoreColour(pct),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${report.score}/${report.totalPossible}',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _scoreColour(pct),
                      ),
                    ),
                    Text(
                      'points',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusChip(
                icon: Icons.check_circle_outline,
                label: '${report.passCount} pass',
                colour: PaletteColours.sageGreen,
              ),
              _StatusChip(
                icon: Icons.remove_circle_outline,
                label: '${report.partialCount} partial',
                colour: PaletteColours.softGold,
              ),
              _StatusChip(
                icon: Icons.error_outline,
                label: '${report.needsWorkCount} to fix',
                colour: PaletteColours.statusNeedsWork,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColour(double pct) {
    if (pct >= 0.75) return PaletteColours.sageGreen;
    if (pct >= 0.5) return PaletteColours.softGold;
    return PaletteColours.statusNeedsWork;
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

// ── Rule Card ────────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});

  final AuditRule rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColour(rule.status), width: 1),
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
          // Header row
          Row(
            children: [
              _statusIcon(rule.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeColour(rule.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rule.status.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _badgeColour(rule.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            rule.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),

          // Detail
          if (rule.detail != null) ...[
            const SizedBox(height: 8),
            Text(
              rule.detail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textPrimary,
              ),
            ),
          ],

          // Suggestion
          if (rule.suggestion != null) ...[
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
                    Icons.lightbulb_outline,
                    size: 16,
                    color: PaletteColours.softGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule.suggestion!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _statusIcon(AuditStatus status) {
    return switch (status) {
      AuditStatus.pass => const Icon(
        Icons.check_circle,
        size: 20,
        color: PaletteColours.sageGreen,
      ),
      AuditStatus.partial => const Icon(
        Icons.remove_circle,
        size: 20,
        color: PaletteColours.softGold,
      ),
      AuditStatus.needsWork => const Icon(
        Icons.error,
        size: 20,
        color: PaletteColours.statusNeedsWork,
      ),
      AuditStatus.unknown => const Icon(
        Icons.help_outline,
        size: 20,
        color: PaletteColours.warmGrey,
      ),
    };
  }

  Color _borderColour(AuditStatus status) {
    return switch (status) {
      AuditStatus.pass => PaletteColours.sageGreen.withValues(alpha: 0.3),
      AuditStatus.partial => PaletteColours.softGold.withValues(alpha: 0.3),
      AuditStatus.needsWork => PaletteColours.statusNeedsWork.withValues(
        alpha: 0.3,
      ),
      AuditStatus.unknown => PaletteColours.warmGrey,
    };
  }

  Color _badgeColour(AuditStatus status) {
    return switch (status) {
      AuditStatus.pass => PaletteColours.sageGreen,
      AuditStatus.partial => PaletteColours.softGoldDark,
      AuditStatus.needsWork => PaletteColours.statusNeedsWork,
      AuditStatus.unknown => PaletteColours.textSecondary,
    };
  }
}
