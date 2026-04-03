import 'package:drift/drift.dart';

import '../database.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [ExerciseEntries, DailyLogs])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  /// All exercise entries for a given date string (YYYY-MM-DD).
  Future<List<ExerciseEntry>> entriesForDate(String date) async {
    final log = await (select(dailyLogs)
          ..where((t) => t.date.equals(date)))
        .getSingleOrNull();
    if (log == null) return [];
    return (select(exerciseEntries)
          ..where((t) => t.dailyLogId.equals(log.id))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .get();
  }

  Future<int> insertEntry(ExerciseEntriesCompanion entry) =>
      into(exerciseEntries).insert(entry);

  Future<void> deleteEntry(int id) =>
      (delete(exerciseEntries)..where((t) => t.id.equals(id))).go();
}
