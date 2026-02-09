import '../../../core/storage/sqlite/app_database.dart';
import '../../learning/domain/entities/difficulty.dart';
import '../domain/entities/progress_snapshot.dart';

class ProgressRepository {
  ProgressRepository(this._database);

  final AppDatabase _database;

  Future<ProgressSnapshot> getSnapshot(String userLocalId) async {
    final row = await _database.getOrCreateProfileProgress(userLocalId);
    final xpTotal = row['xp_total'] as int? ?? 0;
    final currentStreak = row['current_streak'] as int? ?? 0;
    final longestStreak = row['longest_streak'] as int? ?? 0;

    return ProgressSnapshot(
      xpTotal: xpTotal,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      level: _calculateLevel(xpTotal),
    );
  }

  Future<ProgressSnapshot> recordQuizCompletion({
    required String userLocalId,
    required int surahId,
    required Difficulty difficulty,
    required int score,
    required int maxScore,
    required int xpEarned,
  }) async {
    await _database.upsertLearningProgress(
      userLocalId: userLocalId,
      surahId: surahId,
      difficulty: difficulty.name,
      currentStage: score == maxScore ? 'completed' : 'in_progress',
      xpEarned: xpEarned,
    );
    await _database.enqueueSync(
      entityType: 'learning_progress',
      entityId: '$userLocalId:$surahId:${difficulty.name}',
      operation: 'upsert',
      payload: <String, Object?>{
        'user_id': userLocalId,
        'surah_id': surahId,
        'difficulty': difficulty.name,
        'score': score,
        'max_score': maxScore,
        'xp_earned': xpEarned,
      },
    );
    final row = await _database.applyDailyProgress(
      userLocalId: userLocalId,
      xpDelta: xpEarned,
    );
    return ProgressSnapshot(
      xpTotal: row['xp_total'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      level: _calculateLevel(row['xp_total'] as int? ?? 0),
    );
  }

  int _calculateLevel(int xp) {
    return (xp / 120).floor() + 1;
  }
}
