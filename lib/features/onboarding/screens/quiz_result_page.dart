import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/onboarding/data/era_affinities.dart';
import 'package:palette/features/onboarding/logic/undertone_temperature.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';
import 'package:share_plus/share_plus.dart';

/// The quiz result page showing the generated colour palette.
class QuizResultPage extends ConsumerStatefulWidget {
  const QuizResultPage({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;
  late final AnimationController _revealController;
  late final Animation<double> _headerFade;
  late final Animation<double> _archetypeFade;
  late final Animation<Offset> _archetypeSlide;
  late final Animation<double> _descriptionFade;
  late final Animation<double> _swatchesFade;
  bool _isRevealing = true;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Staggered animations
    _headerFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _archetypeFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    _archetypeSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    _descriptionFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _swatchesFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the reveal after a brief loading state
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isRevealing = false);
        _revealController.forward();
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _shareColourDna() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'colour-dna.png')],
        text:
            'I just discovered my Colour DNA! '
            'Take the quiz to find yours: https://palette.app/quiz',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    final palette = quizState.generatedPalette;

    if (palette == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show analysing state during reveal delay
    if (_isRevealing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder:
                  (_, value, child) => Opacity(opacity: value, child: child),
              child: const Icon(
                Icons.palette_outlined,
                size: 48,
                color: PaletteColours.sageGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analysing your choices...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final archetype = quizState.archetype;
    final archetypeDef =
        archetype != null ? archetypeDefinitions[archetype] : null;
    final confidence = quizState.dnaConfidence;

    // Parse system palette for role display
    SystemPalette? systemPalette;
    if (quizState.systemPaletteJson != null) {
      try {
        systemPalette = SystemPalette.fromJson(quizState.systemPaletteJson!);
      } catch (_) {
        // Fall back to flat grid
      }
    }

    return AnimatedBuilder(
      animation: _revealController,
      builder:
          (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section 1: Your Archetype ──
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    color: PaletteColours.warmWhite,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _headerFade,
                          child: Text(
                            'My Colour DNA',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        FadeTransition(
                          opacity: _headerFade,
                          child: Text(
                            _confidenceIntro(confidence),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: PaletteColours.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Archetype name with slide + fade
                        SlideTransition(
                          position: _archetypeSlide,
                          child: FadeTransition(
                            opacity: _archetypeFade,
                            child:
                                archetypeDef != null
                                    ? Column(
                                      children: [
                                        Text(
                                          archetypeDef.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          archetypeDef.headline,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color: PaletteColours.sageGreenDark,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                    : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: PaletteColours.sageGreenLight,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        palette.primaryFamily.displayName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          color: PaletteColours.sageGreenDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                          ),
                        ),

                        if (palette.secondaryFamily != null) ...[
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _archetypeFade,
                            child: Text(
                              'with ${palette.secondaryFamily!.displayName} accents',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _descriptionFade,
                          child: Text(
                            archetypeDef?.description ??
                                palette.primaryFamily.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: PaletteColours.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Palette swatches with fade
                        FadeTransition(
                          opacity: _swatchesFade,
                          child:
                              systemPalette != null
                                  ? _RoleLabelledSwatches(
                                    systemPalette: systemPalette,
                                  )
                                  : _PaletteGrid(
                                    colours:
                                        palette.colours
                                            .map((c) => c.hex)
                                            .toList(),
                                    surpriseIndices: [
                                      for (
                                        var i = 0;
                                        i < palette.colours.length;
                                        i++
                                      )
                                        if (palette.colours[i].isSurprise) i,
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Section 2: Why These Colours Work Together ──
                if (archetypeDef != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Why These Colours Work',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    archetypeDef.whyItWorks,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),

                  // Undertone harmony note
                  if (quizState.undertoneTally.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _undertoneHarmonyNote(quizState.undertoneTally),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.sageGreenDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Property context insight
                  if (quizState.propertyEra != null &&
                      quizState.propertyEra != PropertyEra.notSure) ...[
                    const SizedBox(height: 12),
                    _PropertyContextInsight(
                      propertyEra: quizState.propertyEra!,
                      propertyType: quizState.propertyType,
                      undertone: quizState.undertoneTally,
                      archetypeName: archetypeDef.name,
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Style Tips',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...archetypeDef.styleTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: PaletteColours.sageGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PaletteColours.softCream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: PaletteColours.softGoldDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            archetypeDef.watchOutFor,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Section 3: Your Next Steps ──
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Your Next Steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Share button
                OutlinedButton.icon(
                  onPressed: _isSharing ? null : _shareColourDna,
                  icon:
                      _isSharing
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.share_outlined),
                  label: Text(
                    _isSharing ? 'Preparing...' : 'Share My Colour DNA',
                  ),
                ),
                const SizedBox(height: 12),

                FilledButton(
                  onPressed: widget.onComplete,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Explore My Palette'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  String _undertoneHarmonyNote(Map<Undertone, int> tally) {
    if (tally.isEmpty) return '';
    final dominant = deriveUndertoneTemperature(tally);
    return switch (dominant) {
      Undertone.warm =>
        'All your colours share warm undertones, creating natural harmony.',
      Undertone.cool =>
        'Your colours share cool undertones, giving a calm, cohesive feel.',
      Undertone.neutral =>
        'Your colours blend warm and cool undertones for a versatile palette.',
    };
  }

  String _confidenceIntro(DnaConfidence? confidence) {
    return switch (confidence) {
      DnaConfidence.high => 'Your choices pointed clearly in one direction',
      DnaConfidence.medium =>
        'Your taste spans two worlds, and that is a strength',
      DnaConfidence.low =>
        'You have eclectic taste! We\'ve started you with a flexible '
            'base palette. Refine it as you plan your first room.',
      null => 'Your personal palette, built from your instincts',
    };
  }
}

class _PropertyContextInsight extends StatelessWidget {
  const _PropertyContextInsight({
    required this.propertyEra,
    this.propertyType,
    required this.undertone,
    required this.archetypeName,
  });

  final PropertyEra propertyEra;
  final PropertyType? propertyType;
  final Map<Undertone, int> undertone;
  final String archetypeName;

  @override
  Widget build(BuildContext context) {
    final eraAffinity = getEraAffinity(propertyEra);
    if (eraAffinity == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.sageGreenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 18,
            color: PaletteColours.sageGreenDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildInsight(eraAffinity),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildInsight(EraAffinity affinity) {
    final eraName = propertyEra.displayName;
    final typeName = propertyType?.displayName;

    final prefix =
        typeName != null
            ? '$archetypeName palette is a natural fit for your '
                '$eraName $typeName.'
            : '$archetypeName palette suits $eraName properties well.';

    return '$prefix ${affinity.description}';
  }
}

class _RoleLabelledSwatches extends StatelessWidget {
  const _RoleLabelledSwatches({required this.systemPalette});

  final SystemPalette systemPalette;

  @override
  Widget build(BuildContext context) {
    final roles = <(String hex, String label)>[
      (systemPalette.trimWhite.hex, 'Trim White'),
      ...systemPalette.dominantWalls.map((r) => (r.hex, 'Dominant Wall')),
      ...systemPalette.supportingWalls.map((r) => (r.hex, 'Supporting Wall')),
      (systemPalette.deepAnchor.hex, 'Deep Anchor'),
      ...systemPalette.accentPops.map((r) => (r.hex, 'Accent Pop')),
      (systemPalette.spineColour.hex, 'Spine'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children:
          roles.map((r) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _hexToColor(r.$1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(
                    r.$2,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textTertiary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({required this.colours, required this.surpriseIndices});

  final List<String> colours;
  final List<int> surpriseIndices;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < colours.length; i++)
          Semantics(
            label:
                'Palette colour ${i + 1}${surpriseIndices.contains(i) ? ', surprise colour' : ''}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _hexToColor(colours[i]),
                borderRadius: BorderRadius.circular(10),
                border:
                    surpriseIndices.contains(i)
                        ? Border.all(color: PaletteColours.softGold, width: 2)
                        : Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
              ),
              child:
                  surpriseIndices.contains(i)
                      ? const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: PaletteColours.softGold,
                          ),
                        ),
                      )
                      : null,
            ),
          ),
      ],
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
