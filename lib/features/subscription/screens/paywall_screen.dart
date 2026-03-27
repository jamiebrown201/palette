import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/providers/app_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = ref.watch(subscriptionTierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero message — outcome-focused
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: PaletteColours.premiumGold,
            ),
            const SizedBox(height: 12),
            Text(
              'Avoid expensive colour mistakes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Get personalised recommendations for every room in your home',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Free tier
            _TierCard(
              tier: SubscriptionTier.free,
              isCurrent: currentTier == SubscriptionTier.free,
              features: const [
                'Colour DNA quiz & shareable result',
                'View your palette',
                'Unlimited room profiles',
                'Colour Wheel & White Finder',
                'Educational content',
                'Paint shopping links',
              ],
              onSelect: null,
            ),
            const SizedBox(height: 16),

            // Plus tier — recommended
            _TierCard(
              tier: SubscriptionTier.plus,
              isCurrent: currentTier == SubscriptionTier.plus,
              isRecommended: true,
              price: '\u00A33.99/mo',
              priceSubtext: 'or \u00A329.99/year (save 37%)',
              features: const [
                'Everything in Free, plus:',
                'Edit & customise your palette',
                'Light direction recommendations',
                '70/20/10 colour planner',
                'Red Thread whole-house flow',
                'Export room plans as PDF',
              ],
              onSelect: () {
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.plus;
                context.pop();
              },
            ),
            const SizedBox(height: 16),

            // Pro tier
            _TierCard(
              tier: SubscriptionTier.pro,
              isCurrent: currentTier == SubscriptionTier.pro,
              price: '\u00A37.99/mo',
              priceSubtext: 'or \u00A359.99/year (save 37%)',
              features: const [
                'Everything in Plus, plus:',
                'AI Visualiser (coming soon)',
                'Product recommendations (coming soon)',
                'Partner Mode (coming soon)',
                'Paint & Finish Recommender (coming soon)',
              ],
              onSelect: () {
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.pro;
                context.pop();
              },
            ),
            const SizedBox(height: 16),

            // Project Pass — compact card
            _ProjectPassCard(
              isCurrent: currentTier == SubscriptionTier.projectPass,
              onSelect: () {
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.projectPass;
                context.pop();
              },
            ),
            const SizedBox(height: 20),

            // Annual framing
            Text(
              'Less than a Farrow & Ball sample pot per month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.softGoldDark,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Disclaimer
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
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.features,
    required this.onSelect,
    this.isRecommended = false,
    this.price,
    this.priceSubtext,
  });

  final SubscriptionTier tier;
  final bool isCurrent;
  final bool isRecommended;
  final List<String> features;
  final VoidCallback? onSelect;
  final String? price;
  final String? priceSubtext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? PaletteColours.premiumGold
              : PaletteColours.divider,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tier.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PaletteColours.premiumGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Recommended',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(
              price!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: PaletteColours.premiumGold,
                  ),
            ),
            if (priceSubtext != null)
              Text(
                priceSubtext!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
              ),
          ],
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        f.contains('coming soon')
                            ? Icons.schedule
                            : Icons.check,
                        size: 16,
                        color: f.contains('coming soon')
                            ? PaletteColours.textTertiary
                            : PaletteColours.sageGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: f.contains('coming soon')
                                      ? PaletteColours.textTertiary
                                      : null,
                                ),
                      ),
                    ),
                  ],
                ),
              )),
          if (onSelect != null && !isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isRecommended
                  ? FilledButton(
                      onPressed: onSelect,
                      child: Text('Upgrade to ${tier.displayName}'),
                    )
                  : OutlinedButton(
                      onPressed: onSelect,
                      child: Text('Choose ${tier.displayName}'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectPassCard extends StatelessWidget {
  const _ProjectPassCard({
    required this.isCurrent,
    required this.onSelect,
  });

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
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PaletteColours.sageGreenLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: PaletteColours.sageGreenDark,
                              ),
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
            OutlinedButton(
              onPressed: onSelect,
              child: const Text('Get'),
            ),
        ],
      ),
    );
  }
}
