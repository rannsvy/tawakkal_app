import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/core/storage/sqlite/app_database.dart';
import 'package:tawakkal_app/features/tasbih/data/tasbih_repository.dart';
import 'package:tawakkal_app/features/tasbih/domain/entities/tasbih_models.dart';

void main() {
  test('persists tasbih state and returns today history', () async {
    final db = _FakeTasbihDatabase();
    final repository = TasbihRepository(database: db);

    final initial = await repository.loadState();
    expect(initial.count, 0);
    expect(initial.target, 33);

    const updated = TasbihState(count: 7, target: 99, todayCycles: 1);
    await repository.saveState(updated);
    final reloaded = await repository.loadState();
    expect(reloaded.count, 7);
    expect(reloaded.target, 99);
    expect(reloaded.todayCycles, 1);

    await repository.saveCompletion(
      target: 99,
      finalCount: 99,
      now: DateTime(2026, 3, 1, 9),
    );
    await repository.saveCompletion(
      target: 33,
      finalCount: 33,
      now: DateTime(2026, 3, 1, 11),
    );

    final history = await repository.getTodayHistory(
      now: DateTime(2026, 3, 1, 18),
    );
    expect(history.length, 2);
    expect(history.first.finalCount, 99);
  });
}

class _FakeTasbihDatabase extends AppDatabase {
  Map<String, Object?>? _state;
  final List<Map<String, Object?>> _history = <Map<String, Object?>>[];

  @override
  Future<Map<String, Object?>> getOrCreateTasbihState() async {
    _state ??= <String, Object?>{
      'id': 1,
      'count': 0,
      'target': 33,
      'today_cycles': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return _state!;
  }

  @override
  Future<void> upsertTasbihState({
    required int count,
    required int target,
    required int todayCycles,
  }) async {
    _state = <String, Object?>{
      'id': 1,
      'count': count,
      'target': target,
      'today_cycles': todayCycles,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> insertTasbihHistory({
    required String dateKey,
    required int target,
    required int finalCount,
  }) async {
    _history.add(<String, Object?>{
      'date_key': dateKey,
      'target': target,
      'final_count': finalCount,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, Object?>>> getTasbihHistoryByDate({
    required String dateKey,
  }) async {
    return _history
        .where((row) => (row['date_key'] as String?) == dateKey)
        .toList(growable: false);
  }
}
