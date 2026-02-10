import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalStore {
  const OnboardingLocalStore();

  static const completionKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completionKey) ?? false;
  }

  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(completionKey, true);
  }
}
