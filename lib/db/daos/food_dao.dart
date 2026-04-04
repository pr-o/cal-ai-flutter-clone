import 'package:drift/drift.dart';

import '../database.dart';

part 'food_dao.g.dart';

@DriftAccessor(tables: [FoodEntries, DailyLogs])
class FoodDao extends DatabaseAccessor<AppDatabase> with _$FoodDaoMixin {
  FoodDao(super.db);

  /// All food entries for a given date string (YYYY-MM-DD).
  Future<List<FoodEntry>> entriesForDate(String date) async {
    final log = await (select(
      dailyLogs,
    )..where((t) => t.date.equals(date))).getSingleOrNull();
    if (log == null) return [];
    return (select(foodEntries)
          ..where((t) => t.dailyLogId.equals(log.id))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .get();
  }

  Future<int> insertEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<void> deleteEntry(int id) =>
      (delete(foodEntries)..where((t) => t.id.equals(id))).go();
}
