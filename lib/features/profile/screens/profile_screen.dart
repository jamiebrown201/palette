import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/constants/renter_constraints.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    final colourBlindMode = ref.watch(colourBlindModeProvider);
    final constraints = ref.watch(renterConstraintsProvider);
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
                const Icon(
                  Icons.workspace_premium,
                  color: PaletteColours.premiumGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tier == SubscriptionTier.free)
                        Text(
                          'Upgrade for full features',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PaletteColours.textSecondary),
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
                    final label =
                        dna.archetype != null
                            ? archetypeDefinitions[dna.archetype]?.name ??
                                dna.primaryFamily.displayName
                            : dna.primaryFamily.displayName;
                    return _ProfileRow(
                      icon: Icons.auto_awesome,
                      iconColor: PaletteColours.softGold,
                      title: 'Colour DNA',
                      subtitle:
                          '$label \u2022 ${dna.colourHexes.length} colours',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: PaletteColours.textTertiary,
                      ),
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
                    ref.read(quizNotifierProvider.notifier).reset();
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
                  secondary: const Icon(
                    Icons.visibility_outlined,
                    color: PaletteColours.accessibleBlue,
                  ),
                  title: const Text('Colour Blind Mode'),
                  subtitle: const Text(
                    'Uses shape markers and text badges instead of colour-only indicators',
                  ),
                  value: colourBlindMode,
                  onChanged:
                      (v) =>
                          ref.read(colourBlindModeProvider.notifier).state = v,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (constraints.isRenter) ...[
                  const Divider(height: 1, indent: 56),
                  _ProfileRow(
                    icon: Icons.home_outlined,
                    iconColor: PaletteColours.sageGreen,
                    title: 'Renter Settings',
                    subtitle: 'Update what you can change in your rental',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: PaletteColours.textTertiary,
                    ),
                    onTap:
                        () =>
                            _showRenterSettingsSheet(context, ref, constraints),
                  ),
                ],
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
            child: const _ProfileRow(
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void _showRenterSettingsSheet(
  BuildContext context,
  WidgetRef ref,
  RenterConstraints current,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _RenterSettingsSheet(
          initial: current,
          onSave: (updated) async {
            await ref
                .read(userProfileRepositoryProvider)
                .updateRenterConstraints(
                  canPaint: updated.canPaint,
                  canDrill: updated.canDrill,
                  keepingFlooring: updated.keepingFlooring,
                  isTemporaryHome: updated.isTemporaryHome,
                  reversibleOnly: updated.reversibleOnly,
                );
            ref.read(renterConstraintsProvider.notifier).state = updated;
          },
        ),
  );
}

class _RenterSettingsSheet extends StatefulWidget {
  const _RenterSettingsSheet({required this.initial, required this.onSave});

  final RenterConstraints initial;
  final Future<void> Function(RenterConstraints) onSave;

  @override
  State<_RenterSettingsSheet> createState() => _RenterSettingsSheetState();
}

class _RenterSettingsSheetState extends State<_RenterSettingsSheet> {
  late bool? _canPaint;
  late bool? _canDrill;
  late bool? _keepingFlooring;
  late bool? _isTemporaryHome;
  late bool? _reversibleOnly;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _canPaint = widget.initial.canPaint;
    _canDrill = widget.initial.canDrill;
    _keepingFlooring = widget.initial.keepingFlooring;
    _isTemporaryHome = widget.initial.isTemporaryHome;
    _reversibleOnly = widget.initial.reversibleOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Renter Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "We'll adapt recommendations to what you can actually change",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
          ),
          const SizedBox(height: 20),
          _SettingsToggle(
            label: 'Can you paint the walls?',
            value: _canPaint,
            onChanged: (v) => setState(() => _canPaint = v),
          ),
          _SettingsToggle(
            label: 'Can you drill or mount things?',
            value: _canDrill,
            onChanged: (v) => setState(() => _canDrill = v),
          ),
          _SettingsToggle(
            label: 'Keeping the existing flooring?',
            value: _keepingFlooring,
            onChanged: (v) => setState(() => _keepingFlooring = v),
          ),
          _SettingsToggle(
            label: 'Is this a temporary home?',
            value: _isTemporaryHome,
            onChanged: (v) => setState(() => _isTemporaryHome = v),
          ),
          _SettingsToggle(
            label: 'Reversible changes only?',
            value: _reversibleOnly,
            onChanged: (v) => setState(() => _reversibleOnly = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                _saving
                    ? null
                    : () async {
                      setState(() => _saving = true);
                      await widget.onSave(
                        RenterConstraints(
                          isRenter: true,
                          canPaint: _canPaint,
                          canDrill: _canDrill,
                          keepingFlooring: _keepingFlooring,
                          isTemporaryHome: _isTemporaryHome,
                          reversibleOnly: _reversibleOnly,
                        ),
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Yes'),
            selected: value == true,
            onSelected: (_) => onChanged(true),
            selectedColor: PaletteColours.sageGreenLight,
            checkmarkColor: PaletteColours.sageGreenDark,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('No'),
            selected: value == false,
            onSelected: (_) => onChanged(false),
            selectedColor: PaletteColours.sageGreenLight,
            checkmarkColor: PaletteColours.sageGreenDark,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
