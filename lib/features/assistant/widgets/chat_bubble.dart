import 'package:flutter/material.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/theme/palette_typography.dart';
import 'package:palette/features/assistant/logic/assistant_engine.dart';

/// A single chat bubble in the assistant conversation.
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, this.onFollowUpTapped, super.key});

  final AssistantMessage message;
  final ValueChanged<String>? onFollowUpTapped;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            _buildBubble(),
            if (message.colourSwatches.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSwatches(),
            ],
            if (!message.isUser && message.suggestedFollowUps.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildFollowUps(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            message.isUser
                ? PaletteColours.sageGreen
                : PaletteColours.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
          bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
        ),
        boxShadow:
            message.isUser
                ? null
                : const [
                  BoxShadow(
                    color: PaletteColours.shadowLevel1,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
      ),
      child: Text(
        message.text,
        style: PaletteTypography.bodyMedium.copyWith(
          color:
              message.isUser
                  ? PaletteColours.textOnAccent
                  : PaletteColours.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwatches() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: message.colourSwatches.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final hex = message.colourSwatches[index];
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hexToColor(hex),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PaletteColours.divider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowUps() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children:
          message.suggestedFollowUps.map((suggestion) {
            return GestureDetector(
              onTap: () => onFollowUpTapped?.call(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PaletteColours.softCream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PaletteColours.sageGreenLight),
                ),
                child: Text(
                  suggestion,
                  style: PaletteTypography.labelMedium.copyWith(
                    color: PaletteColours.sageGreenDark,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
