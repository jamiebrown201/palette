import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/notifications/logic/prompt_engine.dart';
import 'package:palette/features/notifications/providers/notification_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';

/// Displays the current in-app prompt on the home screen.
class PromptCard extends ConsumerWidget {
  const PromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promptAsync = ref.watch(currentPromptProvider);

    return promptAsync.when(
      data: (prompt) {
        if (prompt == null) return const SizedBox.shrink();
        return _PromptCardContent(prompt: prompt);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PromptCardContent extends ConsumerStatefulWidget {
  const _PromptCardContent({required this.prompt});

  final InAppPrompt prompt;

  @override
  ConsumerState<_PromptCardContent> createState() => _PromptCardContentState();
}

class _PromptCardContentState extends ConsumerState<_PromptCardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AnalyticsEvents.promptViewed, {
        'type': widget.prompt.type.name,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final isOptIn = prompt.type == PromptType.notificationOptIn;

    final Color bgColor;
    final Color accentColor;
    final IconData icon;

    switch (prompt.type) {
      case PromptType.notificationOptIn:
        bgColor = PaletteColours.sageGreenLight.withValues(alpha: 0.3);
        accentColor = PaletteColours.sageGreenDark;
        icon = Icons.notifications_outlined;
      case PromptType.sampleFollowUp:
        bgColor = PaletteColours.softGoldLight.withValues(alpha: 0.4);
        accentColor = PaletteColours.softGoldDark;
        icon = Icons.local_shipping_outlined;
      case PromptType.movingCountdown:
        bgColor = PaletteColours.softGoldLight.withValues(alpha: 0.4);
        accentColor = PaletteColours.softGoldDark;
        icon = Icons.home_outlined;
      case PromptType.progressCelebration:
        bgColor = PaletteColours.sageGreenLight.withValues(alpha: 0.3);
        accentColor = PaletteColours.sageGreenDark;
        icon = Icons.celebration_outlined;
      case PromptType.weekendProject:
        bgColor = PaletteColours.softCream;
        accentColor = PaletteColours.softGoldDark;
        icon = Icons.weekend_outlined;
      case PromptType.seasonalRefresh:
        bgColor = PaletteColours.softCream;
        accentColor = PaletteColours.sageGreenDark;
        icon = Icons.eco_outlined;
      case PromptType.clocksChange:
        bgColor = PaletteColours.softGoldLight.withValues(alpha: 0.4);
        accentColor = PaletteColours.softGoldDark;
        icon = Icons.access_time_outlined;
      case PromptType.reEngagement:
        bgColor = PaletteColours.softCream;
        accentColor = PaletteColours.sageGreenDark;
        icon = Icons.waving_hand_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prompt.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isOptIn) ...[
                  FilledButton(
                    onPressed: () => _handleOptIn(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(prompt.actionLabel),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _handleOptIn(false),
                    child: Text(
                      'Not now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () => _handleAction(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(prompt.actionLabel),
                  ),
                  if (prompt.dismissible) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _handleDismiss,
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOptIn(bool enabled) async {
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.setNotificationsEnabled(enabled);
    await repo.markOptInPromptShown();

    ref.read(analyticsProvider).track(AnalyticsEvents.notificationOptIn, {
      'enabled': enabled,
    });

    ref.invalidate(currentPromptProvider);
  }

  void _handleAction(BuildContext context) {
    final prompt = widget.prompt;
    ref.read(analyticsProvider).track(AnalyticsEvents.promptActioned, {
      'type': prompt.type.name,
    });

    if (prompt.route != null) {
      context.push(prompt.route!);
    }
  }

  Future<void> _handleDismiss() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.promptDismissed, {
      'type': widget.prompt.type.name,
    });
    await ref.read(userProfileRepositoryProvider).dismissPrompt();
    ref.invalidate(currentPromptProvider);
  }
}
