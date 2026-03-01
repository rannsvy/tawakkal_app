import '../../../core/storage/sqlite/app_database.dart';
import '../domain/entities/tasbih_models.dart';

class TasbihRepository {
  TasbihRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<TasbihState> loadState() async {
    final row = await _database.getOrCreateTasbihState();
    return TasbihState(
      count: (row['count'] as int?) ?? 0,
      target: (row['target'] as int?) ?? 33,
      todayCycles: (row['today_cycles'] as int?) ?? 0,
    );
  }

  Future<void> saveState(TasbihState state) async {
    await _database.upsertTasbihState(
      count: state.count,
      target: state.target,
      todayCycles: state.todayCycles,
    );
  }

  Future<void> saveCompletion({
    required int target,
    required int finalCount,
    DateTime? now,
  }) async {
    final value = now ?? DateTime.now();
    await _database.insertTasbihHistory(
      dateKey: _dateKey(value),
      target: target,
      finalCount: finalCount,
    );
  }

  Future<List<TasbihHistoryItem>> getTodayHistory({DateTime? now}) async {
    final value = now ?? DateTime.now();
    final rows = await _database.getTasbihHistoryByDate(
      dateKey: _dateKey(value),
    );
    return rows
        .map((row) {
          final completedAtRaw = row['completed_at'] as String? ?? '';
          return TasbihHistoryItem(
            target: (row['target'] as int?) ?? 0,
            finalCount: (row['final_count'] as int?) ?? 0,
            completedAt: DateTime.tryParse(completedAtRaw) ?? value,
          );
        })
        .toList(growable: false);
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }
}
