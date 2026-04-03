import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daos/exercise_dao.dart';
import 'daos/food_dao.dart';
import 'daos/weight_dao.dart';

part 'database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'lose' | 'maintain' | 'gain'
  TextColumn get goal => text()();

  /// 'male' | 'female' | 'other'
  TextColumn get gender => text()();

  /// ISO date string (YYYY-MM-DD)
  TextColumn get birthday => text()();

  RealColumn get currentWeightKg => real()();
  RealColumn get heightCm => real()();
  RealColumn get targetWeightKg => real()();

  /// 'sedentary' | 'lightly_active' | 'active' | 'very_active'
  TextColumn get activityLevel => text()();

  /// JSON-encoded list of strings e.g. '["vegetarian","keto"]'
  TextColumn get dietaryPreferences =>
      text().withDefault(const Constant('[]'))();

  IntColumn get dailyCalories => integer()();
  IntColumn get dailyProteinG => integer()();
  IntColumn get dailyCarbsG => integer()();
  IntColumn get dailyFatG => integer()();

  /// ISO 8601 timestamp
  TextColumn get createdAt => text()();
}

class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// YYYY-MM-DD — unique per calendar day
  TextColumn get date => text().unique()();

  IntColumn get waterMl => integer().withDefault(const Constant(0))();
}

class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyLogId =>
      integer().references(DailyLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get calories => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
  TextColumn get servingSize => text().nullable()();
  RealColumn get servings => real().withDefault(const Constant(1.0))();

  /// 'camera' | 'search'
  TextColumn get source => text()();

  TextColumn get photoUri => text().nullable()();
  IntColumn get healthScore => integer().nullable()();

  /// ISO 8601 timestamp
  TextColumn get loggedAt => text()();
}

class ExerciseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyLogId =>
      integer().references(DailyLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get durationMinutes => integer()();
  RealColumn get caloriesBurned => real()();

  /// ISO 8601 timestamp
  TextColumn get loggedAt => text()();
}

class WeightLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weightKg => real()();

  /// YYYY-MM-DD
  TextColumn get date => text()();

  /// ISO 8601 timestamp
  TextColumn get loggedAt => text()();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Profiles, DailyLogs, FoodEntries, ExerciseEntries, WeightLogs],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cal_ai_db');
  }

  @override
  int get schemaVersion => 1;

  // DAO accessors
  late final FoodDao foodDao = FoodDao(this);
  late final ExerciseDao exerciseDao = ExerciseDao(this);
  late final WeightDao weightDao = WeightDao(this);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
