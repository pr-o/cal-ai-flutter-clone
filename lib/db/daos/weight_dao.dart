import 'package:drift/drift.dart';

import '../database.dart';

part 'weight_dao.g.dart';

@DriftAccessor(tables: [WeightLogs])
class WeightDao extends DatabaseAccessor<AppDatabase> with _$WeightDaoMixin {
  WeightDao(super.db);

  /// Weight entries from the last [days] calendar days, ascending by date.
  Future<List<WeightLog>> lastNDays(int days) {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    return (select(weightLogs)
          ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// Most recent weight log entry, or null if none exists.
  Future<WeightLog?> latest() =>
      (select(weightLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertEntry(WeightLogsCompanion entry) =>
      into(weightLogs).insert(entry);
}
