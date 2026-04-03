import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/features/rooms/logic/lighting_planner.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LightingPlannerScreen extends ConsumerStatefulWidget {
  const LightingPlannerScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<LightingPlannerScreen> createState() =>
      _LightingPlannerScreenState();
}

class _LightingPlannerScreenState extends ConsumerState<LightingPlannerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider).track(AnalyticsEvents.screenViewed, {
        'screen': 'lighting_planner',
        'room_id': widget.roomId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lighting Planner')),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }
          return PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage:
                'Unlock the Lighting Planner to see what your room needs',
            child: _PlannerContent(roomId: widget.roomId),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: ErrorCard()),
      ),
    );
  }
}

class _PlannerContent extends ConsumerWidget {
  const _PlannerContent({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(lightingPlanProvider(roomId));

    return planAsync.when(
      data: (plan) => _PlanView(plan: plan),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: ErrorCard()),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final LightingPlan plan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _SummaryCard(plan: plan),
          const SizedBox(height: 24),

          // Overall note
          if (plan.overallNote != null) ...[
            _TipCard(text: plan.overallNote!),
            const SizedBox(height: 24),
          ],

          const SectionHeader(
            title: 'Three layers of light',
            subtitle: 'Every room needs ambient, task, and accent lighting',
          ),
          const SizedBox(height: 8),

          // Layers
          for (final layer in plan.layers) ...[
            _LayerCard(layer: layer),
            const SizedBox(height: 16),
          ],

          // Educational note
          const SizedBox(height: 8),
          _EducationalNote(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.plan});

  final LightingPlan plan;

  @override
  Widget build(BuildContext context) {
    final progress = plan.layersCovered / plan.layersTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                plan.isComplete ? Icons.check_circle : Icons.lightbulb_outline,
                color:
                    plan.isComplete
                        ? PaletteColours.sageGreen
                        : PaletteColours.softGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lighting plan for ${plan.roomName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: PaletteColours.warmGrey,
              valueColor: AlwaysStoppedAnimation(
                plan.isComplete
                    ? PaletteColours.sageGreen
                    : PaletteColours.softGold,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.layer});

  final LightingLayer layer;

  IconData get _layerIcon => switch (layer.type) {
    LightingSubcategory.ambient => Icons.light_mode_outlined,
    LightingSubcategory.task => Icons.desk_outlined,
    LightingSubcategory.accent => Icons.auto_awesome,
  };

  Color get _layerColour => switch (layer.type) {
    LightingSubcategory.ambient => PaletteColours.softGold,
    LightingSubcategory.task => PaletteColours.sageGreen,
    LightingSubcategory.accent => PaletteColours.accessibleBlue,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              layer.isCovered
                  ? PaletteColours.sageGreenLight
                  : PaletteColours.divider,
        ),
        boxShadow: const [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _layerColour.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_layerIcon, color: _layerColour, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              layer.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _StatusBadge(isCovered: layer.isCovered),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        layer.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // "Why it matters" section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: PaletteColours.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    layer.whyItMatters,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Covered by info
          if (layer.isCovered && layer.coveredBy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: PaletteColours.sageGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Covered by: ${layer.coveredBy!.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.sageGreenDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Renter note
          if (layer.renterNote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_outlined,
                      size: 14,
                      color: PaletteColours.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        layer.renterNote!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Product recommendations
          if (!layer.isCovered &&
              layer.recommendations != null &&
              layer.recommendations!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Recommended products',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: PaletteColours.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final product in layer.recommendations!)
              _ProductTile(product: product),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isCovered});

  final bool isCovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            isCovered
                ? PaletteColours.sageGreenLight
                : PaletteColours.softGoldLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCovered ? 'Covered' : 'Needed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              isCovered
                  ? PaletteColours.sageGreenDark
                  : PaletteColours.softGoldDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PaletteColours.warmWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PaletteColours.divider),
        ),
        child: Row(
          children: [
            // Colour swatch
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _parseHex(product.primaryColourHex),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PaletteColours.divider),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.brand} \u2022 ${product.category.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              '\u00A3${product.priceGbp.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            // Buy CTA
            IconButton(
              onPressed: () async {
                ref
                    .read(analyticsProvider)
                    .track(AnalyticsEvents.affiliateLinkTapped, {
                      'product_id': product.id,
                      'category': product.category.name,
                      'source': 'lighting_planner',
                    });
                final uri = Uri.tryParse(product.affiliateUrl);
                if (uri == null ||
                    (uri.scheme != 'https' && uri.scheme != 'http')) {
                  return;
                }
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open link')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Buy',
              style: IconButton.styleFrom(
                foregroundColor: PaletteColours.sageGreenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return PaletteColours.warmGrey;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softGoldLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            size: 20,
            color: PaletteColours.softGoldDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why layered lighting matters',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'A room lit only from above feels flat and clinical. Three layers '
            'create depth, warmth, and flexibility. Ambient sets the base, '
            'task supports activity, and accent adds personality. Together, '
            'they let you control the mood for any occasion.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
