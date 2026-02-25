import 'package:flutter/foundation.dart';
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

          // Your Palette section
          Text(
            'Your Palette',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PaletteColours.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Column(
              children: [
                dnaAsync.when(
                  data: (dna) {
                    if (dna == null) return const SizedBox.shrink();
                    return _ProfileRow(
                      icon: Icons.auto_awesome,
                      iconColor: PaletteColours.softGold,
                      title: 'Colour DNA',
                      subtitle:
                          '${dna.primaryFamily.displayName} \u2022 ${dna.colourHexes.length} colours',
                      trailing: const Icon(Icons.chevron_right,
                          color: PaletteColours.textTertiary),
                      onTap: () => context.push('/palette'),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Divider(height: 1, indent: 56),
                _ProfileRow(
                  icon: Icons.refresh,
                  iconColor: PaletteColours.sageGreen,
                  title: 'Retake Colour DNA Quiz',
                  onTap: () {
                    ref.read(hasCompletedOnboardingProvider.notifier).state =
                        false;
                    context.go('/onboarding');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings section
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PaletteColours.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_outlined,
                      color: PaletteColours.accessibleBlue),
                  title: const Text('Colour Blind Mode'),
                  subtitle: const Text(
                    'Uses shape markers and text badges instead of colour-only indicators',
                  ),
                  value: colourBlindMode,
                  onChanged: (v) =>
                      ref.read(colourBlindModeProvider.notifier).state = v,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          Container(
            decoration: BoxDecoration(
              color: PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: _ProfileRow(
              icon: Icons.info_outline,
              iconColor: PaletteColours.textTertiary,
              title: 'About Palette',
              subtitle: 'v1.0.0',
            ),
          ),

          if (kDebugMode) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/dev'),
              icon: const Icon(Icons.bug_report),
              label: const Text('QA Mode'),
            ),
          ],

          const SizedBox(height: 20),
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
