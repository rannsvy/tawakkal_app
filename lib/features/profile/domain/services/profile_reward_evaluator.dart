import '../entities/reward_milestone.dart';

class ProfileRewardInput {
  const ProfileRewardInput({
    required this.xpTotal,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalTasbihCompletions,
    required this.completedQuizUnits,
  });

  final int xpTotal;
  final int currentStreak;
  final int longestStreak;
  final int totalTasbihCompletions;
  final int completedQuizUnits;
}

class ProfileRewardEvaluator {
  const ProfileRewardEvaluator._();

  static List<RewardMilestone> build(ProfileRewardInput input) {
    return <RewardMilestone>[
      RewardMilestone(
        code: 'streak_3',
        title: 'Istiqamah Dasar',
        description: 'Jaga konsistensi ibadah selama 3 hari berturut-turut.',
        kind: RewardMilestoneKind.streak,
        currentValue: input.currentStreak,
        threshold: 3,
        unitLabel: 'hari',
      ),
      RewardMilestone(
        code: 'streak_7',
        title: 'Istiqamah Pekanan',
        description: 'Capai rekor streak ibadah minimal 7 hari.',
        kind: RewardMilestoneKind.streak,
        currentValue: input.longestStreak,
        threshold: 7,
        unitLabel: 'hari',
      ),
      RewardMilestone(
        code: 'tasbih_10',
        title: 'Sahabat Tasbih',
        description: 'Selesaikan 10 sesi tasbih dari riwayat ibadah.',
        kind: RewardMilestoneKind.tasbih,
        currentValue: input.totalTasbihCompletions,
        threshold: 10,
        unitLabel: 'sesi',
      ),
      RewardMilestone(
        code: 'quiz_12',
        title: 'Mahir Kuis',
        description: 'Selesaikan 12 unit kuis dengan status completed.',
        kind: RewardMilestoneKind.quiz,
        currentValue: input.completedQuizUnits,
        threshold: 12,
        unitLabel: 'kuis',
      ),
    ];
  }
}
