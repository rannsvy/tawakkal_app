import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../domain/entities/profile_overview.dart';
import '../../domain/services/profile_reward_evaluator.dart';

final profileActivityMetricsProvider = FutureProvider<ProfileActivityMetrics>((
  ref,
) async {
  final database = ref.watch(appDatabaseProvider);
  final userLocalId = ref.watch(currentUserIdProvider);
  final todayKey = _dateKey(DateTime.now());

  final completedQuizUnits = await database.countCompletedLearningUnits(
    userLocalId: userLocalId,
  );
  final totalTasbihCompletions = await database.countTasbihCompletions();
  final tasbihTodayCycles = await database.countTasbihCompletions(
    dateKey: todayKey,
  );

  return ProfileActivityMetrics(
    completedQuizUnits: completedQuizUnits,
    totalTasbihCompletions: totalTasbihCompletions,
    tasbihTodayCycles: tasbihTodayCycles,
  );
});

final profileOverviewProvider = FutureProvider<ProfileOverview>((ref) async {
  final authUser = await ref.watch(authControllerProvider.future);
  final snapshot = await ref.watch(progressSnapshotProvider.future);
  final metrics = await ref.watch(profileActivityMetricsProvider.future);

  final displayName = authUser?.displayName.trim().isNotEmpty == true
      ? authUser!.displayName.trim()
      : 'Sahabat Tawakkal';
  final email = authUser?.email ?? 'Belum terhubung';
  final isGuest = authUser?.isGuest ?? true;

  final rewards = ProfileRewardEvaluator.build(
    ProfileRewardInput(
      xpTotal: snapshot.xpTotal,
      currentStreak: snapshot.currentStreak,
      longestStreak: snapshot.longestStreak,
      totalTasbihCompletions: metrics.totalTasbihCompletions,
      completedQuizUnits: metrics.completedQuizUnits,
    ),
  );

  return ProfileOverview(
    displayName: displayName,
    email: email,
    isGuest: isGuest,
    level: snapshot.level,
    xpTotal: snapshot.xpTotal,
    currentStreak: snapshot.currentStreak,
    longestStreak: snapshot.longestStreak,
    tasbihTodayCycles: metrics.tasbihTodayCycles,
    totalTasbihCompletions: metrics.totalTasbihCompletions,
    completedQuizUnits: metrics.completedQuizUnits,
    rewards: rewards,
  );
});

class ProfileActivityMetrics {
  const ProfileActivityMetrics({
    required this.completedQuizUnits,
    required this.totalTasbihCompletions,
    required this.tasbihTodayCycles,
  });

  final int completedQuizUnits;
  final int totalTasbihCompletions;
  final int tasbihTodayCycles;
}

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return '${normalized.year.toString().padLeft(4, '0')}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}
