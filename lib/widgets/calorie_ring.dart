import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated donut ring showing calories consumed vs goal.
///
/// A flame icon sits at the center. The arc fills clockwise from 12 o'clock
/// on mount via an [AnimationController].
class CalorieRing extends StatefulWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 200.0,
    this.strokeWidth = 14.0,
  });

  final int consumed;
  final int goal;
  final double size;
  final double strokeWidth;

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CalorieRing old) {
    super.didUpdateWidget(old);
    if (old.consumed != widget.consumed || old.goal != widget.goal) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.goal > 0 ? (widget.consumed / widget.goal).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: progress * _animation.value,
              strokeWidth: widget.strokeWidth,
              trackColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              fillColor: const Color(0xFFFF5500), // accentOrange
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 28, color: Color(0xFFFF5500)),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.consumed}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'of ${widget.goal} kcal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track (full circle)
    canvas.drawCircle(center, radius, trackPaint);

    // Filled arc — starts at 12 o'clock (-π/2)
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}
