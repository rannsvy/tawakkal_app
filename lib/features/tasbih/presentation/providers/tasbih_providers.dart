import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../data/tasbih_repository.dart';
import '../../domain/entities/tasbih_models.dart';

final tasbihRepositoryProvider = Provider<TasbihRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TasbihRepository(database: database);
});

final tasbihStateProvider =
    AsyncNotifierProvider<TasbihController, TasbihState>(TasbihController.new);

class TasbihController extends AsyncNotifier<TasbihState> {
  @override
  Future<TasbihState> build() {
    return ref.read(tasbihRepositoryProvider).loadState();
  }

  Future<void> increment() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final nextCount = current.count + 1;
    final isCompleted = nextCount >= current.target;
    final updated = current.copyWith(
      count: isCompleted ? 0 : nextCount,
      todayCycles: isCompleted
          ? (current.todayCycles + 1)
          : current.todayCycles,
    );
    await ref.read(tasbihRepositoryProvider).saveState(updated);
    if (isCompleted) {
      await ref
          .read(tasbihRepositoryProvider)
          .saveCompletion(target: current.target, finalCount: nextCount);
      await HapticFeedback.mediumImpact();
      ref.invalidate(tasbihHistoryProvider);
    } else {
      await HapticFeedback.lightImpact();
    }
    state = AsyncData(updated);
  }

  Future<void> resetCount() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final updated = current.copyWith(count: 0);
    await ref.read(tasbihRepositoryProvider).saveState(updated);
    state = AsyncData(updated);
  }

  Future<void> resetDailyCycles() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final updated = current.copyWith(todayCycles: 0);
    await ref.read(tasbihRepositoryProvider).saveState(updated);
    state = AsyncData(updated);
  }

  Future<void> setTarget(int value) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final safeTarget = value <= 0 ? 33 : value;
    final updated = current.copyWith(count: 0, target: safeTarget);
    await ref.read(tasbihRepositoryProvider).saveState(updated);
    state = AsyncData(updated);
  }
}

final tasbihHistoryProvider = FutureProvider<List<TasbihHistoryItem>>((ref) {
  return ref.read(tasbihRepositoryProvider).getTodayHistory();
});
