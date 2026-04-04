import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A horizontal scrollable ruler picker.
///
/// Displays a large bold value above a ruler of tick marks. The selected value
/// is always pinned to the center of the widget. Snaps to the nearest [step].
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
    this.label,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  /// Optional label shown above the value (e.g. "Lose weight").
  final String? label;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late final ScrollController _scroll;
  static const double _tickSpacing = 8.0;
  static const double _rulerHeight = 64.0;
  bool _isScrolling = false;

  int get _totalTicks => ((widget.max - widget.min) / widget.step).round() + 1;

  double _valueToOffset(double value, double viewWidth) {
    final index = ((value - widget.min) / widget.step).round();
    return index * _tickSpacing - viewWidth / 2;
  }

  double _offsetToValue(double offset, double viewWidth) {
    final index = ((offset + viewWidth / 2) / _tickSpacing).round();
    final clamped = index.clamp(0, _totalTicks - 1);
    final raw = widget.min + clamped * widget.step;
    // Round to step precision
    final factor = math.pow(10, widget.step.toString().split('.').last.length);
    return (raw * factor).round() / factor;
  }

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue());
  }

  void _jumpToValue() {
    if (!_scroll.hasClients) return;
    final offset = _valueToOffset(
      widget.value,
      _scroll.position.viewportDimension,
    );
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  void didUpdateWidget(RulerPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_isScrolling) _jumpToValue();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
        ],
        // Value display
        Text(
          '${_fmt(widget.value)} ${widget.unit}',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        // Ruler
        SizedBox(
          height: _rulerHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewWidth = constraints.maxWidth;
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification) _isScrolling = true;
                  if (n is ScrollEndNotification) {
                    _isScrolling = false;
                    final v = _offsetToValue(_scroll.offset, viewWidth);
                    if (v != widget.value) widget.onChanged(v);
                  }
                  if (n is ScrollUpdateNotification) {
                    final v = _offsetToValue(_scroll.offset, viewWidth);
                    if (v != widget.value) widget.onChanged(v);
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  itemCount: _totalTicks,
                  itemExtent: _tickSpacing,
                  padding: EdgeInsets.symmetric(horizontal: viewWidth / 2),
                  itemBuilder: (context, index) {
                    final isMajor = index % 10 == 0;
                    final isMid = index % 5 == 0;
                    final tickHeight = isMajor
                        ? 32.0
                        : isMid
                        ? 20.0
                        : 12.0;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 1.5,
                        height: tickHeight,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Center indicator line
        Container(
          height: 2,
          width: 2,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (widget.step < 1) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0);
  }
}
