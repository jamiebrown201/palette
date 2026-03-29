import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/partner/logic/partner_comparison.dart';
import 'package:palette/features/partner/providers/partner_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:share_plus/share_plus.dart';

class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(partnerProfileProvider);
    final dnaAsync = ref.watch(latestColourDnaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Mode'),
        actions: [
          partnerAsync.whenOrNull(
                data:
                    (partner) =>
                        partner != null
                            ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove partner',
                              onPressed:
                                  () => _confirmRemovePartner(
                                    context,
                                    ref,
                                    partner.id,
                                  ),
                            )
                            : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: dnaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ErrorState(),
        data: (ColourDnaResult? dna) {
          if (dna == null) return const _NoDnaState();

          return partnerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const _ErrorState(),
            data: (partner) {
              if (partner == null) {
                return _InvitePartnerView(userName: dna.archetype?.displayName);
              }
              if (!partner.hasCompletedQuiz) {
                return _PendingInviteView(partner: partner);
              }
              // Both have DNA — show comparison
              final comparison = ref.watch(partnerComparisonProvider);
              if (comparison == null) return const _ErrorState();
              return _ComparisonView(
                partner: partner,
                comparison: comparison,
                userHexes: dna.colourHexes,
                userArchetype: dna.archetype,
              );
            },
          );
        },
      ),
    );
  }

  void _confirmRemovePartner(
    BuildContext context,
    WidgetRef ref,
    String partnerId,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove partner?'),
            content: const Text(
              'This will remove your partner and their comparison data. '
              'They can always take the quiz again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(partnerRepositoryProvider)
                      .deletePartner(partnerId);
                  ref.invalidate(partnerProfileProvider);
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}

/// State when the user hasn't completed their own DNA quiz yet.
class _NoDnaState extends StatelessWidget {
  const _NoDnaState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: PaletteColours.warmGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete your Colour DNA quiz first',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Partner Mode compares your design personality with your '
              "partner's. You need your own results before inviting them.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Something went wrong. Please try again.'));
  }
}

/// View shown when no partner has been invited yet.
class _InvitePartnerView extends ConsumerWidget {
  const _InvitePartnerView({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: PaletteColours.softGold,
          ),
          const SizedBox(height: 24),
          Text(
            'Decorate together',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Invite your partner to discover their Colour DNA. '
            "You'll see where your tastes overlap and where they diverge "
            '— so you can make decorating decisions together without '
            'the arguments.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletteColours.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // How it works
          const _StepCard(
            step: '1',
            title: 'Invite your partner',
            description:
                'Share a link — they take a quick Colour DNA quiz '
                'on their phone (no app install needed).',
          ),
          const SizedBox(height: 12),
          const _StepCard(
            step: '2',
            title: 'See the overlap',
            description:
                'A Venn diagram shows which colour families you share '
                'and where you differ.',
          ),
          const SizedBox(height: 12),
          const _StepCard(
            step: '3',
            title: 'Decorate with confidence',
            description:
                'Get room-by-room tips for blending both styles '
                'without compromise.',
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () => _invitePartner(context, ref),
            icon: const Icon(Icons.share),
            label: const Text('Invite your partner'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showManualEntrySheet(context, ref),
            child: const Text('Enter partner results manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _invitePartner(BuildContext context, WidgetRef ref) async {
    final inviteCode = _generateInviteCode();

    // Create a pending partner record
    await ref
        .read(partnerRepositoryProvider)
        .upsertPartner(
          PartnerProfilesCompanion.insert(
            id: 'partner-${DateTime.now().millisecondsSinceEpoch}',
            name: 'My Partner',
            inviteCode: inviteCode,
            hasCompletedQuiz: false,
            invitedAt: DateTime.now(),
          ),
        );
    ref.invalidate(partnerProfileProvider);

    ref.read(analyticsProvider).track('partner_invited');

    // Share the invite link
    final shareText =
        "I'm using Palette to plan our home's colours. "
        'Take this quick quiz so we can compare our design '
        'personalities!\n\n'
        'https://palette.app/partner/$inviteCode';

    await Share.share(shareText);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

/// View shown while waiting for partner to complete their quiz.
class _PendingInviteView extends ConsumerWidget {
  const _PendingInviteView({required this.partner});

  final PartnerProfile partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.hourglass_top,
            size: 64,
            color: PaletteColours.softGold,
          ),
          const SizedBox(height: 24),
          Text(
            'Waiting for ${partner.name}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Your partner hasn't completed their Colour DNA quiz yet. "
            'Share the link again or enter their results manually.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletteColours.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: PaletteColours.sageGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invite code: ${partner.inviteCode}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: partner.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final shareText =
                  "I'm using Palette to plan our home's colours. "
                  'Take this quick quiz so we can compare our design '
                  'personalities!\n\n'
                  'https://palette.app/partner/${partner.inviteCode}';
              await Share.share(shareText);
            },
            icon: const Icon(Icons.share),
            label: const Text('Resend invite'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showManualEntrySheet(context, ref),
            child: const Text('Enter results manually'),
          ),
        ],
      ),
    );
  }
}

/// Comparison view with Venn diagram and tips.
class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.partner,
    required this.comparison,
    required this.userHexes,
    this.userArchetype,
  });

  final PartnerProfile partner;
  final PartnerComparison comparison;
  final List<String> userHexes;
  final ColourArchetype? userArchetype;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compatibility score header
          _CompatibilityHeader(score: comparison.compatibilityScore),
          const SizedBox(height: 24),

          // Venn diagram
          _VennDiagram(
            userFamilies: comparison.userOnlyFamilies,
            sharedFamilies: comparison.sharedFamilies,
            partnerFamilies: comparison.partnerOnlyFamilies,
            userLabel: 'You',
            partnerLabel: partner.name,
          ),
          const SizedBox(height: 24),

          // Archetype comparison
          _ArchetypeComparison(
            userArchetype: userArchetype,
            partnerArchetype: partner.archetype,
          ),
          const SizedBox(height: 16),

          // Colour palette comparison
          _PaletteComparisonRow(label: 'Your palette', hexes: userHexes),
          const SizedBox(height: 8),
          _PaletteComparisonRow(
            label: "${partner.name}'s palette",
            hexes: partner.colourHexes ?? [],
          ),
          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comparison.summaryText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tips
          Text(
            'How to decorate together',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...comparison.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: PaletteColours.softGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Undertone match indicator
          const SizedBox(height: 16),
          _UndertoneMatchBadge(match: comparison.undertoneMatch),
        ],
      ),
    );
  }
}

/// Circular score display.
class _CompatibilityHeader extends StatelessWidget {
  const _CompatibilityHeader({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (score) {
      >= 70 => ('Naturally aligned', PaletteColours.sageGreen),
      >= 40 => ('Creative tension', PaletteColours.softGold),
      _ => ('Complementary opposites', PaletteColours.accessibleBlue),
    };

    return Column(
      children: [
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
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: PaletteColours.warmGrey,
                  valueColor: AlwaysStoppedAnimation(colour),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colour,
                    ),
                  ),
                  Text(
                    'match',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colour,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Custom-painted Venn diagram showing family overlap.
class _VennDiagram extends StatelessWidget {
  const _VennDiagram({
    required this.userFamilies,
    required this.sharedFamilies,
    required this.partnerFamilies,
    required this.userLabel,
    required this.partnerLabel,
  });

  final List<PaletteFamily> userFamilies;
  final List<PaletteFamily> sharedFamilies;
  final List<PaletteFamily> partnerFamilies;
  final String userLabel;
  final String partnerLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _VennPainter(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // User only
            Expanded(
              child: _VennLegendColumn(
                label: userLabel,
                colour: PaletteColours.sageGreen.withValues(alpha: 0.3),
                families: userFamilies,
              ),
            ),
            // Shared
            Expanded(
              child: _VennLegendColumn(
                label: 'Shared',
                colour: PaletteColours.softGold.withValues(alpha: 0.3),
                families: sharedFamilies,
                emptyText: 'No overlap',
              ),
            ),
            // Partner only
            Expanded(
              child: _VennLegendColumn(
                label: partnerLabel,
                colour: PaletteColours.accessibleBlue.withValues(alpha: 0.3),
                families: partnerFamilies,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VennPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final radius = size.height * 0.4;
    final offset = radius * 0.55;

    // Left circle (user)
    final leftPaint =
        Paint()
          ..color = PaletteColours.sageGreen.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2 - offset, centerY),
      radius,
      leftPaint,
    );

    // Right circle (partner)
    final rightPaint =
        Paint()
          ..color = PaletteColours.accessibleBlue.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2 + offset, centerY),
      radius,
      rightPaint,
    );

    // Overlap highlight
    final overlapPaint =
        Paint()
          ..color = PaletteColours.softGold.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

    // Draw overlap using clipping
    canvas.save();
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2 - offset, centerY),
          radius: radius,
        ),
      ),
    );
    canvas.drawCircle(
      Offset(size.width / 2 + offset, centerY),
      radius,
      overlapPaint,
    );
    canvas.restore();

    // Borders
    final borderPaint =
        Paint()
          ..color = PaletteColours.divider
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(size.width / 2 - offset, centerY),
      radius,
      borderPaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2 + offset, centerY),
      radius,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VennLegendColumn extends StatelessWidget {
  const _VennLegendColumn({
    required this.label,
    required this.colour,
    required this.families,
    this.emptyText,
  });

  final String label;
  final Color colour;
  final List<PaletteFamily> families;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        if (families.isEmpty)
          Text(
            emptyText ?? '\u2014',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
          )
        else
          ...families.map(
            (f) => Text(
              f.displayName,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/// Side-by-side archetype comparison.
class _ArchetypeComparison extends StatelessWidget {
  const _ArchetypeComparison({this.userArchetype, this.partnerArchetype});

  final ColourArchetype? userArchetype;
  final ColourArchetype? partnerArchetype;

  @override
  Widget build(BuildContext context) {
    if (userArchetype == null && partnerArchetype == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ArchetypeChip(
              label: 'You',
              archetype: userArchetype,
              colour: PaletteColours.sageGreen,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.compare_arrows,
              color: PaletteColours.textTertiary,
            ),
          ),
          Expanded(
            child: _ArchetypeChip(
              label: 'Partner',
              archetype: partnerArchetype,
              colour: PaletteColours.accessibleBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeChip extends StatelessWidget {
  const _ArchetypeChip({
    required this.label,
    required this.colour,
    this.archetype,
  });

  final String label;
  final ColourArchetype? archetype;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: PaletteColours.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            archetype?.displayName ?? 'Not set',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colour,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Row of colour swatches for comparison.
class _PaletteComparisonRow extends StatelessWidget {
  const _PaletteComparisonRow({required this.label, required this.hexes});

  final String label;
  final List<String> hexes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hexes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) {
                final hex = hexes[i].replaceAll('#', '');
                final colour = Color(int.parse('FF$hex', radix: 16));
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: PaletteColours.divider,
                      width: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge showing undertone match status.
class _UndertoneMatchBadge extends StatelessWidget {
  const _UndertoneMatchBadge({required this.match});

  final bool match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            match
                ? PaletteColours.sageGreen.withValues(alpha: 0.1)
                : PaletteColours.softGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: match ? PaletteColours.sageGreen : PaletteColours.softGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              match
                  ? 'Your undertone temperatures match \u2014 choosing '
                      'whites and neutrals will be straightforward.'
                  : 'Your undertone temperatures differ \u2014 bridge with '
                      'neutral-leaning colours like greige or mushroom.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Step card for the invite flow.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: PaletteColours.sageGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: PaletteColours.sageGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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

/// Bottom sheet for entering a partner's DNA results manually.
void _showManualEntrySheet(BuildContext context, WidgetRef ref) {
  var name = '';
  PaletteFamily? primary;
  PaletteFamily? secondary;
  ColourArchetype? archetype;
  Undertone? undertone;
  ChromaBand? saturation;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setState) => DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder:
                    (_, controller) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: ListView(
                        controller: controller,
                        children: [
                          Text(
                            "Enter partner's results",
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If your partner has taken the quiz on another '
                            'device, enter their results here.',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: PaletteColours.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Partner's name",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => name = v,
                          ),
                          const SizedBox(height: 16),

                          // Archetype
                          DropdownButtonFormField<ColourArchetype>(
                            decoration: const InputDecoration(
                              labelText: 'Design identity',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                ColourArchetype.values
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => archetype = v),
                          ),
                          const SizedBox(height: 16),

                          // Primary family
                          DropdownButtonFormField<PaletteFamily>(
                            decoration: const InputDecoration(
                              labelText: 'Primary colour family',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                PaletteFamily.values
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => primary = v),
                          ),
                          const SizedBox(height: 16),

                          // Secondary family (optional)
                          DropdownButtonFormField<PaletteFamily>(
                            decoration: const InputDecoration(
                              labelText: 'Secondary family (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                PaletteFamily.values
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => secondary = v),
                          ),
                          const SizedBox(height: 16),

                          // Undertone
                          DropdownButtonFormField<Undertone>(
                            decoration: const InputDecoration(
                              labelText: 'Undertone temperature',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                Undertone.values
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => undertone = v),
                          ),
                          const SizedBox(height: 16),

                          // Saturation
                          DropdownButtonFormField<ChromaBand>(
                            decoration: const InputDecoration(
                              labelText: 'Saturation preference',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                ChromaBand.values
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => saturation = v),
                          ),
                          const SizedBox(height: 24),

                          FilledButton(
                            onPressed:
                                (name.isNotEmpty && primary != null)
                                    ? () => _saveManualPartner(
                                      ctx,
                                      ref,
                                      name: name,
                                      archetype: archetype,
                                      primary: primary!,
                                      secondary: secondary,
                                      undertone: undertone,
                                      saturation: saturation,
                                    )
                                    : null,
                            child: const Text('Save partner results'),
                          ),
                        ],
                      ),
                    ),
              ),
        ),
  );
}

Future<void> _saveManualPartner(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required PaletteFamily primary,
  ColourArchetype? archetype,
  PaletteFamily? secondary,
  Undertone? undertone,
  ChromaBand? saturation,
}) async {
  final repo = ref.read(partnerRepositoryProvider);

  // Generate representative hex colours for the partner's family
  final hexes = _familyRepresentativeHexes(primary);

  final existing = await repo.getPartner();

  await repo.upsertPartner(
    PartnerProfilesCompanion(
      id: Value(
        existing?.id ?? 'partner-${DateTime.now().millisecondsSinceEpoch}',
      ),
      name: Value(name),
      inviteCode: Value(existing?.inviteCode ?? 'MANUAL'),
      archetype: Value(archetype),
      primaryFamily: Value(primary),
      secondaryFamily: Value(secondary),
      undertone: Value(undertone),
      saturation: Value(saturation),
      colourHexes: Value(hexes),
      hasCompletedQuiz: const Value(true),
      invitedAt: Value(existing?.invitedAt ?? DateTime.now()),
      completedAt: Value(DateTime.now()),
    ),
  );

  ref.invalidate(partnerProfileProvider);
  ref.read(analyticsProvider).track('partner_dna_entered');

  if (context.mounted) {
    Navigator.pop(context);
  }
}

/// Representative hex colours for each palette family.
List<String> _familyRepresentativeHexes(
  PaletteFamily family,
) => switch (family) {
  PaletteFamily.warmNeutrals => ['#C9B99A', '#A89070', '#E8DCC8', '#8B7355'],
  PaletteFamily.coolNeutrals => ['#9CA3AB', '#B8BFC7', '#7A858F', '#D4D8DC'],
  PaletteFamily.earthTones => ['#C4A882', '#8B6F47', '#D4C4A8', '#5C4033'],
  PaletteFamily.pastels => ['#E8C4D0', '#C4D8E8', '#D4E8C4', '#E8D8C4'],
  PaletteFamily.brights => ['#E86040', '#40A0E8', '#40C840', '#E8C040'],
  PaletteFamily.jewelTones => ['#8B2252', '#1B4B6B', '#2B5B3B', '#6B3B8B'],
  PaletteFamily.darks => ['#2C2C2C', '#3B2B1B', '#1B2B3B', '#2B1B3B'],
};
