import 'package:flutter/material.dart';

/// A horizontal 7-day strip for the home screen.
///
/// The current day shows a dashed circle outline. A logged day shows a solid
/// filled pill. Tapping a past day calls [onDaySelected] with 'YYYY-MM-DD'.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDaySelected,
    this.loggedDates = const {},
  });

  /// The currently highlighted date as 'YYYY-MM-DD'.
  final String selectedDate;

  /// Dates on which food was logged, as 'YYYY-MM-DD' strings.
  final Set<String> loggedDates;

  /// Called when the user taps a day tile.
  final ValueChanged<String> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final today = _dateString(DateTime.now());
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return d;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) {
        final key = _dateString(day);
        final isToday = key == today;
        final isSelected = key == selectedDate;
        final isLogged = loggedDates.contains(key);

        return _DayTile(
          date: day,
          dateKey: key,
          isToday: isToday,
          isSelected: isSelected,
          isLogged: isLogged,
          onTap: () => onDaySelected(key),
        );
      }).toList(),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.dateKey,
    required this.isToday,
    required this.isSelected,
    required this.isLogged,
    required this.onTap,
  });

  final DateTime date;
  final String dateKey;
  final bool isToday;
  final bool isSelected;
  final bool isLogged;
  final VoidCallback onTap;

  static const _dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dayLetters[date.weekday % 7],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? activeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 4),
            _DateCircle(
              label: '${date.day}',
              isToday: isToday,
              isSelected: isSelected,
              isLogged: isLogged,
              activeColor: activeColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCircle extends StatelessWidget {
  const _DateCircle({
    required this.label,
    required this.isToday,
    required this.isSelected,
    required this.isLogged,
    required this.activeColor,
  });

  final String label;
  final bool isToday;
  final bool isSelected;
  final bool isLogged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    // Filled pill for selected non-today days
    if (isSelected && !isToday) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: activeColor == Colors.black
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    // Dashed circle for today
    if (isToday) {
      return CustomPaint(
        painter: _DashedCirclePainter(color: activeColor),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeColor : null,
                  ),
            ),
          ),
        ),
      );
    }

    // Dot indicator for logged past days
    if (isLogged) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5500),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }

    // Plain date number
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    const dashCount = 10;
    const gapFraction = 0.4;
    const totalAngle = 2 * 3.14159265;
    final dashAngle = totalAngle / dashCount * (1 - gapFraction);
    final gapAngle = totalAngle / dashCount * gapFraction;

    double startAngle = -3.14159265 / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

String _dateString(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
