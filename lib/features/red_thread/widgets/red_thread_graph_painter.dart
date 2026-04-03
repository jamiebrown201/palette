import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// A room node in the Red Thread graph.
class GraphNode {
  const GraphNode({
    required this.id,
    required this.name,
    this.heroHex,
    this.isDisconnected = false,
  });

  final String id;
  final String name;
  final String? heroHex;
  final bool isDisconnected;
}

/// An edge between two rooms in the Red Thread graph.
class GraphEdge {
  const GraphEdge({required this.fromId, required this.toId});

  final String fromId;
  final String toId;
}

/// Paints a free-form node-and-edge diagram for the Red Thread flow.
///
/// Rooms are arranged in a circular layout and connected by curved edges
/// coloured with the thread colour(s). Rooms with no thread colour present
/// show a dashed border warning indicator.
class RedThreadGraphPainter extends CustomPainter {
  const RedThreadGraphPainter({
    required this.nodes,
    required this.edges,
    required this.threadHexes,
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<String> threadHexes;

  static const double _nodeWidth = 120;
  static const double _nodeHeight = 56;
  static const double _nodeRadius = 10;
  static const double _swatchSize = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final positions = _layoutNodes(size);

    // Draw edges first (behind nodes)
    _drawEdges(canvas, positions);

    // Draw nodes on top
    _drawNodes(canvas, positions);
  }

  /// Arrange nodes in a circular layout centred within the canvas.
  Map<String, Offset> _layoutNodes(Size size) {
    final positions = <String, Offset>{};
    final count = nodes.length;

    if (count == 1) {
      positions[nodes.first.id] = Offset(size.width / 2, size.height / 2);
      return positions;
    }

    // Circular layout with generous radius
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = (size.width / 2) - _nodeWidth / 2 - 16;
    final radiusY = (size.height / 2) - _nodeHeight / 2 - 16;
    final radius = math.min(radiusX, radiusY).clamp(60.0, double.infinity);

    for (var i = 0; i < count; i++) {
      // Start from top (-π/2) and go clockwise
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      positions[nodes[i].id] = Offset(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );
    }

    return positions;
  }

  void _drawEdges(Canvas canvas, Map<String, Offset> positions) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final from = positions[edge.fromId];
      final to = positions[edge.toId];
      if (from == null || to == null) continue;

      // Pick thread colour for this edge (cycle through thread colours)
      final threadColor =
          threadHexes.isNotEmpty
              ? hexToColor(threadHexes[i % threadHexes.length])
              : PaletteColours.sageGreen;

      final edgePaint =
          Paint()
            ..color = threadColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;

      // Curved edge between node centres
      final midX = (from.dx + to.dx) / 2;
      final midY = (from.dy + to.dy) / 2;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 1) continue;

      final curveOffset = dist * 0.12;
      final controlPoint = Offset(
        midX + (dy / dist) * curveOffset,
        midY - (dx / dist) * curveOffset,
      );

      final path =
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, to.dx, to.dy);

      canvas.drawPath(path, edgePaint);

      // Small dot at each end
      final dotPaint =
          Paint()
            ..color = threadColor.withValues(alpha: 0.8)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(from, 3, dotPaint);
      canvas.drawCircle(to, 3, dotPaint);
    }
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> positions) {
    for (final node in nodes) {
      final center = positions[node.id];
      if (center == null) continue;

      final rect = Rect.fromCenter(
        center: center,
        width: _nodeWidth,
        height: _nodeHeight,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(_nodeRadius),
      );

      // Fill
      final fillColour =
          node.heroHex != null
              ? hexToColor(node.heroHex!).withValues(alpha: 0.15)
              : PaletteColours.warmGrey.withValues(alpha: 0.3);

      canvas.drawRRect(rrect, Paint()..color = fillColour);

      // Border — dashed for disconnected, solid for connected
      if (node.isDisconnected) {
        _drawDashedBorder(canvas, rrect);
      } else {
        final borderPaint =
            Paint()
              ..color = PaletteColours.textSecondary.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
        canvas.drawRRect(rrect, borderPaint);
      }

      // Hero colour swatch (small square to the left of the name)
      if (node.heroHex != null) {
        final swatchRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + 10,
            rect.top + (_nodeHeight - _swatchSize) / 2,
            _swatchSize,
            _swatchSize,
          ),
          const Radius.circular(3),
        );
        canvas
          ..drawRRect(swatchRect, Paint()..color = hexToColor(node.heroHex!))
          ..drawRRect(
            swatchRect,
            Paint()
              ..color = PaletteColours.divider
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
      }

      // Room name
      final textX =
          node.heroHex != null
              ? rect.left + 10 + _swatchSize + 6
              : rect.left + 10;
      final maxTextWidth = rect.right - textX - 8;

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color:
                node.isDisconnected
                    ? PaletteColours.softGoldDark
                    : PaletteColours.textPrimary,
            fontSize: 11,
            fontWeight:
                node.isDisconnected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: maxTextWidth.clamp(20, double.infinity));

      textPainter.paint(
        canvas,
        Offset(textX, rect.top + (_nodeHeight - textPainter.height) / 2),
      );

      // Warning indicator for disconnected rooms
      if (node.isDisconnected) {
        final warningCenter = Offset(rect.right - 14, rect.top + 14);
        canvas.drawCircle(
          warningCenter,
          7,
          Paint()..color = PaletteColours.softGoldDark,
        );
        final exclamation = TextPainter(
          text: const TextSpan(
            text: '!',
            style: TextStyle(
              color: PaletteColours.textOnAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        exclamation.paint(
          canvas,
          Offset(
            warningCenter.dx - exclamation.width / 2,
            warningCenter.dy - exclamation.height / 2,
          ),
        );
      }
    }
  }

  void _drawDashedBorder(Canvas canvas, RRect rrect) {
    final paint =
        Paint()
          ..color = PaletteColours.softGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      const dashLength = 6.0;
      const gapLength = 4.0;
      var draw = true;

      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final end = (distance + length).clamp(0.0, metric.length);

        if (draw) {
          final segment = metric.extractPath(distance, end);
          canvas.drawPath(segment, paint);
        }

        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(RedThreadGraphPainter oldDelegate) =>
      nodes != oldDelegate.nodes ||
      edges != oldDelegate.edges ||
      threadHexes != oldDelegate.threadHexes;
}
