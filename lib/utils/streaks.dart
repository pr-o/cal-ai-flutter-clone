/// Calculates the current consecutive-day logging streak.
///
/// [dates] is a list of 'YYYY-MM-DD' strings on which food was logged.
/// Counts backwards from today; if today has no log, counts backwards from
/// yesterday so a streak isn't broken just because the user hasn't logged yet.
int calculateStreak(List<String> dates) {
  if (dates.isEmpty) return 0;

  final dateSet = dates.toSet();
  final today = _dateString(DateTime.now());
  final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

  // Start from today if logged, otherwise start from yesterday.
  DateTime? cursor = dateSet.contains(today)
      ? DateTime.now()
      : dateSet.contains(yesterday)
          ? DateTime.now().subtract(const Duration(days: 1))
          : null;

  if (cursor == null) return 0;

  int streak = 0;
  DateTime current = cursor;
  while (dateSet.contains(_dateString(current))) {
    streak++;
    current = current.subtract(const Duration(days: 1));
  }
  return streak;
}

String _dateString(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
