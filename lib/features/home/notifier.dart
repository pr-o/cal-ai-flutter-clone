import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../utils/units.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String todayString() => dateString(DateTime.now());

// ─── Selected date ────────────────────────────────────────────────────────────

/// The date currently displayed on the home screen ('YYYY-MM-DD').
class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() => todayString();

  void select(String date) => state = date;
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, String>(
  SelectedDateNotifier.new,
);

// ─── State ────────────────────────────────────────────────────────────────────

class MacroTotals {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroTotals({this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
}

class DailyState {
  final String date;
  final int dailyLogId;
  final List<FoodEntry> foodEntries;
  final List<ExerciseEntry> exerciseEntries;
  final int waterMl;

  // Derived totals
  final int caloriesConsumed;
  final int caloriesFromExercise;
  final MacroTotals macrosConsumed;

  const DailyState({
    required this.date,
    required this.dailyLogId,
    this.foodEntries = const [],
    this.exerciseEntries = const [],
    this.waterMl = 0,
    this.caloriesConsumed = 0,
    this.caloriesFromExercise = 0,
    this.macrosConsumed = const MacroTotals(),
  });

  /// Net calories = consumed − burned by exercise.
  int get caloriesNet => caloriesConsumed - caloriesFromExercise;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class DailyNotifier extends AsyncNotifier<DailyState> {
  @override
  Future<DailyState> build() async {
    // Rebuild whenever the selected date changes.
    final date = ref.watch(selectedDateProvider);
    return _loadForDate(date);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<DailyState> _loadForDate(String date) async {
    final db = ref.read(databaseProvider);

    final existing = await (db.select(
      db.dailyLogs,
    )..where((t) => t.date.equals(date))).getSingleOrNull();

    final int logId;
    final int waterMl;

    if (existing != null) {
      logId = existing.id;
      waterMl = existing.waterMl;
    } else {
      logId = await db
          .into(db.dailyLogs)
          .insert(DailyLogsCompanion(date: Value(date)));
      waterMl = 0;
    }

    final food = await db.foodDao.entriesForDate(date);
    final exercise = await db.exerciseDao.entriesForDate(date);

    return _buildState(
      date: date,
      logId: logId,
      food: food,
      exercise: exercise,
      waterMl: waterMl,
    );
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> addFoodEntry(FoodEntriesCompanion entry) async {
    final current = await future;
    await ref
        .read(databaseProvider)
        .foodDao
        .insertEntry(entry.copyWith(dailyLogId: Value(current.dailyLogId)));
    ref.invalidateSelf();
  }

  Future<void> deleteFoodEntry(int id) async {
    await ref.read(databaseProvider).foodDao.deleteEntry(id);
    ref.invalidateSelf();
  }

  Future<void> addExerciseEntry(ExerciseEntriesCompanion entry) async {
    final current = await future;
    await ref
        .read(databaseProvider)
        .exerciseDao
        .insertEntry(entry.copyWith(dailyLogId: Value(current.dailyLogId)));
    ref.invalidateSelf();
  }

  Future<void> deleteExerciseEntry(int id) async {
    await ref.read(databaseProvider).exerciseDao.deleteEntry(id);
    ref.invalidateSelf();
  }

  Future<void> updateWater(int additionalMl) async {
    final db = ref.read(databaseProvider);
    final current = await future;
    final newTotal = current.waterMl + additionalMl;
    await (db.update(db.dailyLogs)
          ..where((t) => t.id.equals(current.dailyLogId)))
        .write(DailyLogsCompanion(waterMl: Value(newTotal)));
    ref.invalidateSelf();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DailyState _buildState({
    required String date,
    required int logId,
    required List<FoodEntry> food,
    required List<ExerciseEntry> exercise,
    required int waterMl,
  }) {
    final caloriesConsumed = food
        .fold(0.0, (sum, e) => sum + e.calories * e.servings)
        .round();
    final caloriesFromExercise = exercise
        .fold(0.0, (sum, e) => sum + e.caloriesBurned)
        .round();

    final macros = MacroTotals(
      proteinG: food.fold(0.0, (sum, e) => sum + e.proteinG * e.servings),
      carbsG: food.fold(0.0, (sum, e) => sum + e.carbsG * e.servings),
      fatG: food.fold(0.0, (sum, e) => sum + e.fatG * e.servings),
    );

    return DailyState(
      date: date,
      dailyLogId: logId,
      foodEntries: food,
      exerciseEntries: exercise,
      waterMl: waterMl,
      caloriesConsumed: caloriesConsumed,
      caloriesFromExercise: caloriesFromExercise,
      macrosConsumed: macros,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final dailyProvider = AsyncNotifierProvider<DailyNotifier, DailyState>(
  DailyNotifier.new,
);

final profileProvider = FutureProvider<Profile?>((ref) async {
  final db = ref.read(databaseProvider);
  return (db.select(db.profiles)..limit(1)).getSingleOrNull();
});
