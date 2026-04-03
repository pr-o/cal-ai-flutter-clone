import 'package:flutter_test/flutter_test.dart';
import 'package:cal_ai_flutter_clone/utils/streaks.dart';

String _daysAgo(int n) {
  final d = DateTime.now().subtract(Duration(days: n));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  group('calculateStreak', () {
    test('empty list returns 0', () {
      expect(calculateStreak([]), 0);
    });

    test('only today returns 1', () {
      expect(calculateStreak([_daysAgo(0)]), 1);
    });

    test('today and yesterday returns 2', () {
      expect(calculateStreak([_daysAgo(0), _daysAgo(1)]), 2);
    });

    test('5 consecutive days ending today', () {
      final dates = List.generate(5, (i) => _daysAgo(i));
      expect(calculateStreak(dates), 5);
    });

    test('gap in streak resets count', () {
      // logged today, 1 day ago, then gap, then 3+ days ago
      final dates = [_daysAgo(0), _daysAgo(1), _daysAgo(3), _daysAgo(4)];
      expect(calculateStreak(dates), 2);
    });

    test('only yesterday (not yet logged today) counts from yesterday', () {
      expect(calculateStreak([_daysAgo(1)]), 1);
    });

    test('yesterday and 2 days ago — streak is 2', () {
      expect(calculateStreak([_daysAgo(1), _daysAgo(2)]), 2);
    });

    test('old dates with no recent activity returns 0', () {
      expect(calculateStreak([_daysAgo(5), _daysAgo(6)]), 0);
    });

    test('duplicate dates do not inflate streak', () {
      final dates = [_daysAgo(0), _daysAgo(0), _daysAgo(1)];
      expect(calculateStreak(dates), 2);
    });
  });
}
