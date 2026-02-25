import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Stepped progress indicator for multi-stage flows.
class SteppedProgressBar extends StatelessWidget {
  const SteppedProgressBar({
    required this.totalSteps,
    required this.currentStep,
    this.activeColour,
    super.key,
  });

  final int totalSteps;
  final int currentStep;
  final Color? activeColour;

  @override
  Widget build(BuildContext context) {
    final active = activeColour ?? PaletteColours.sageGreen;

    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < totalSteps - 1 ? 4 : 0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted || isCurrent
                      ? active
                      : PaletteColours.warmGrey,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
