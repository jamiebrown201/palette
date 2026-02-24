import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/providers/app_providers.dart';

/// Wraps content that requires a premium subscription.
///
/// If the user's tier is sufficient, shows the child normally.
/// Otherwise, displays the child with a blur overlay and an upgrade CTA.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.requiredTier,
    required this.child,
    this.upgradeMessage = 'Upgrade to unlock this feature',
    super.key,
  });

  final SubscriptionTier requiredTier;
  final Widget child;
  final String upgradeMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = ref.watch(subscriptionTierProvider);

    if (currentTier >= requiredTier) {
      return child;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Blurred child – wrapped in a ConstrainedBox so the Stack is at
        // least tall enough for the overlay content to fit without overflow.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: child,
            ),
          ),
        ),

        // Upgrade overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: PaletteColours.cardBackground.withValues(alpha: 0.7),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: PaletteColours.premiumGold,
                ),
                const SizedBox(height: 12),
                Text(
                  upgradeMessage,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push('/paywall'),
                  child: Text(requiredTier.displayName),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
