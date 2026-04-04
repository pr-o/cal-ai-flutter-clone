import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MacroType { protein, carbs, fat }

/// Compact pill showing remaining grams for a single macro.
///
/// Displays a small colored arc ring, gram value, and label.
class MacroPill extends StatelessWidget {
  const MacroPill({
    super.key,
    required this.type,
    required this.remaining,
    required this.goal,
  });

  final MacroType type;

  /// Remaining grams to consume for the day.
  final double remaining;

  /// Daily goal in grams.
  final double goal;

  static const _colors = {
    MacroType.protein: Color(0xFFFF6B35),
    MacroType.carbs: Color(0xFFFFB800),
    MacroType.fat: Color(0xFF4A9EFF),
  };

  static const _labels = {
    MacroType.protein: 'Protein left',
    MacroType.carbs: 'Carbs left',
    MacroType.fat: 'Fat left',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type]!;
    final label = _labels[type]!;
    final progress = goal > 0
        ? ((goal - remaining) / goal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniRing(progress: progress, color: color, size: 44),
          const SizedBox(height: 8),
          Text(
            '${remaining.round()}g',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MiniRingPainter(
        progress: progress,
        color: color,
        trackColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
