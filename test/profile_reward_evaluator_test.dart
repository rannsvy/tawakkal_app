import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/profile/domain/services/profile_reward_evaluator.dart';

void main() {
  test('build returns expected milestones with lock/unlock states', () {
    final rewards = ProfileRewardEvaluator.build(
      const ProfileRewardInput(
        xpTotal: 500,
        currentStreak: 4,
        longestStreak: 6,
        totalTasbihCompletions: 8,
        completedQuizUnits: 14,
      ),
    );

    expect(rewards.length, 4);

    final streak3 = rewards.firstWhere((item) => item.code == 'streak_3');
    final streak7 = rewards.firstWhere((item) => item.code == 'streak_7');
    final tasbih10 = rewards.firstWhere((item) => item.code == 'tasbih_10');
    final quiz12 = rewards.firstWhere((item) => item.code == 'quiz_12');

    expect(streak3.isUnlocked, isTrue);
    expect(streak7.isUnlocked, isFalse);
    expect(tasbih10.isUnlocked, isFalse);
    expect(quiz12.isUnlocked, isTrue);
  });

  test('milestone progress is clamped and handles threshold boundaries', () {
    final rewards = ProfileRewardEvaluator.build(
      const ProfileRewardInput(
        xpTotal: 720,
        currentStreak: 3,
        longestStreak: 7,
        totalTasbihCompletions: 10,
        completedQuizUnits: 12,
      ),
    );

    for (final reward in rewards) {
      expect(reward.isUnlocked, isTrue);
      expect(reward.progress, 1);
    }
  });
}
