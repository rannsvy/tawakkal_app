import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../learning/domain/entities/difficulty.dart';
import '../../data/cloud_sync_service.dart';
import '../../data/progress_repository.dart';
import '../../domain/entities/progress_snapshot.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProgressRepository(database);
});

final progressSnapshotProvider = FutureProvider<ProgressSnapshot>((ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getSnapshot(userId);
});

final progressActionsProvider = Provider<ProgressActions>((ref) {
  return ProgressActions(ref);
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  return CloudSyncService(database: database, supabaseClient: client);
});

class ProgressActions {
  ProgressActions(this._ref);

  final Ref _ref;

  Future<void> recordQuizCompletion({
    required int surahId,
    required Difficulty difficulty,
    required int score,
    required int maxScore,
    required int xpEarned,
  }) async {
    final repository = _ref.read(progressRepositoryProvider);
    final userId = _ref.read(currentUserIdProvider);
    await repository.recordQuizCompletion(
      userLocalId: userId,
      surahId: surahId,
      difficulty: difficulty,
      score: score,
      maxScore: maxScore,
      xpEarned: xpEarned,
    );
    _ref.invalidate(progressSnapshotProvider);
    await _ref.read(cloudSyncServiceProvider).syncPendingQueue();
  }

  Future<void> syncPendingData() async {
    await _ref.read(cloudSyncServiceProvider).syncPendingQueue();
  }
}
