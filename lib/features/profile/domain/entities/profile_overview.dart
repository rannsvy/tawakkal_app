import 'package:equatable/equatable.dart';

import 'reward_milestone.dart';

class ProfileOverview extends Equatable {
  const ProfileOverview({
    required this.displayName,
    required this.email,
    required this.isGuest,
    required this.level,
    required this.xpTotal,
    required this.currentStreak,
    required this.longestStreak,
    required this.tasbihTodayCycles,
    required this.totalTasbihCompletions,
    required this.completedQuizUnits,
    required this.rewards,
  });

  final String displayName;
  final String email;
  final bool isGuest;
  final int level;
  final int xpTotal;
  final int currentStreak;
  final int longestStreak;
  final int tasbihTodayCycles;
  final int totalTasbihCompletions;
  final int completedQuizUnits;
  final List<RewardMilestone> rewards;

  @override
  List<Object?> get props => [
    displayName,
    email,
    isGuest,
    level,
    xpTotal,
    currentStreak,
    longestStreak,
    tasbihTodayCycles,
    totalTasbihCompletions,
    completedQuizUnits,
    rewards,
  ];
}
