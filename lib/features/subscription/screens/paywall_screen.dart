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
            // Hero message
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: PaletteColours.premiumGold,
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock the full Palette experience',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Tier cards
            _TierCard(
              tier: SubscriptionTier.free,
              isCurrent: currentTier == SubscriptionTier.free,
              features: const [
                'Colour DNA quiz',
                'View palette (no editing)',
                'Room profiles (basic)',
                'Colour Wheel',
                'White Finder',
              ],
              onSelect: null,
            ),
            const SizedBox(height: 16),
            _TierCard(
              tier: SubscriptionTier.plus,
              isCurrent: currentTier == SubscriptionTier.plus,
              isRecommended: true,
              features: const [
                'Everything in Free',
                'Edit & customise palette',
                'Light recommendations',
                '70/20/10 planner',
                'Red Thread coherence',
                'Export as PDF',
              ],
              onSelect: () {
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.plus;
                context.pop();
              },
            ),
            const SizedBox(height: 16),
            _TierCard(
              tier: SubscriptionTier.pro,
              isCurrent: currentTier == SubscriptionTier.pro,
              features: const [
                'Everything in Plus',
                'Partner mode',
                'Priority support',
                'Early access to features',
              ],
              onSelect: () {
                ref.read(subscriptionTierProvider.notifier).state =
                    SubscriptionTier.pro;
                context.pop();
              },
            ),
            const SizedBox(height: 24),

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
  });

  final SubscriptionTier tier;
  final bool isCurrent;
  final bool isRecommended;
  final List<String> features;
  final VoidCallback? onSelect;

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
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check,
                        size: 16, color: PaletteColours.sageGreen),
                    const SizedBox(width: 8),
                    Text(f, style: Theme.of(context).textTheme.bodySmall),
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
