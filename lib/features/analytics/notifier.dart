import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../utils/streaks.dart';
import '../../utils/units.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class WeeklyMacroDay {
  final String date;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int calories;

  const WeeklyMacroDay({
    required this.date,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.calories,
  });
}

class AnalyticsState {
  final List<WeightLog> weightHistory;
  final List<WeeklyMacroDay> weeklyMacros;
  final int streakDays;
  final double? latestWeightKg;

  const AnalyticsState({
    this.weightHistory = const [],
    this.weeklyMacros = const [],
    this.streakDays = 0,
    this.latestWeightKg,
  });
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AnalyticsNotifier extends AsyncNotifier<AnalyticsState> {
  @override
  Future<AnalyticsState> build() => _load();

  Future<AnalyticsState> _load() async {
    final db = ref.read(databaseProvider);

    // Weight history (last 90 days)
    final weightHistory = await db.weightDao.lastNDays(90);
    final latestWeight = weightHistory.isNotEmpty
        ? weightHistory.last.weightKg
        : null;

    // Food entries last 7 days for macro chart
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    final cutoffDate = dateString(sevenDaysAgo);

    final recentFood = await (db.select(db.foodEntries).join([
      innerJoin(
        db.dailyLogs,
        db.dailyLogs.id.equalsExp(db.foodEntries.dailyLogId),
      ),
    ])..where(db.dailyLogs.date.isBiggerOrEqualValue(cutoffDate))).get();

    // Group by date
    final Map<String, WeeklyMacroDay> byDate = {};
    for (final row in recentFood) {
      final log = row.readTable(db.dailyLogs);
      final entry = row.readTable(db.foodEntries);
      final existing = byDate[log.date];
      byDate[log.date] = WeeklyMacroDay(
        date: log.date,
        proteinG: (existing?.proteinG ?? 0) + entry.proteinG * entry.servings,
        carbsG: (existing?.carbsG ?? 0) + entry.carbsG * entry.servings,
        fatG: (existing?.fatG ?? 0) + entry.fatG * entry.servings,
        calories:
            (existing?.calories ?? 0) +
            (entry.calories * entry.servings).round(),
      );
    }

    // Fill all 7 days (even ones with no data)
    final weeklyMacros = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      final key = dateString(d);
      return byDate[key] ??
          WeeklyMacroDay(
            date: key,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
            calories: 0,
          );
    });

    // Streak from food entry dates
    final allLoggedDates =
        await (db.selectOnly(db.dailyLogs)
              ..addColumns([db.dailyLogs.date])
              ..join([
                innerJoin(
                  db.foodEntries,
                  db.foodEntries.dailyLogId.equalsExp(db.dailyLogs.id),
                ),
              ]))
            .map((r) => r.read(db.dailyLogs.date)!)
            .get();
    final streak = calculateStreak(allLoggedDates.toSet().toList());

    return AnalyticsState(
      weightHistory: weightHistory,
      weeklyMacros: weeklyMacros,
      streakDays: streak,
      latestWeightKg: latestWeight,
    );
  }

  Future<void> logWeight(double kg) async {
    final db = ref.read(databaseProvider);
    final today = dateString(DateTime.now());
    await db.weightDao.insertEntry(
      WeightLogsCompanion(
        weightKg: Value(kg),
        date: Value(today),
        loggedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
    ref.invalidateSelf();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, AnalyticsState>(
      AnalyticsNotifier.new,
    );
