import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    final colourBlindMode = ref.watch(colourBlindModeProvider);
    final dnaAsync = ref.watch(latestColourDnaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: PaletteColours.premiumGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (tier == SubscriptionTier.free)
                        Text(
                          'Upgrade for full features',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: PaletteColours.textSecondary,
                                  ),
                        ),
                    ],
                  ),
                ),
                if (tier == SubscriptionTier.free)
                  FilledButton(
                    onPressed: () => context.push('/paywall'),
                    child: const Text('Upgrade'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Colour DNA summary
          dnaAsync.when(
            data: (dna) {
              if (dna == null) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Colour DNA'),
                subtitle: Text(
                  '${dna.primaryFamily.displayName} \u2022 ${dna.colourHexes.length} colours',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/palette'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Settings
          SwitchListTile(
            title: const Text('Colour Blind Mode'),
            subtitle: const Text(
              'Uses shape markers and text badges instead of colour-only indicators',
            ),
            value: colourBlindMode,
            onChanged: (v) =>
                ref.read(colourBlindModeProvider.notifier).state = v,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Retake Colour DNA Quiz'),
            onTap: () {
              ref.read(hasCompletedOnboardingProvider.notifier).state = false;
              context.go('/onboarding');
            },
          ),

          const Divider(),

          // About section
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Palette'),
            subtitle: Text('v1.0.0'),
          ),

          const SizedBox(height: 16),
          Text(
            'Colours displayed on screens are approximations. '
            'Always test physical paint samples in your space.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
