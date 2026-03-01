import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/auth_gate_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/onboarding/presentation/pages/launch_experience_page.dart';
import '../features/prayer_times/presentation/pages/prayer_times_page.dart';
import '../features/quran/presentation/pages/surah_detail_page.dart';
import '../features/qibla/presentation/pages/qibla_page.dart';
import '../features/quiz/presentation/pages/quiz_page.dart';
import '../features/quiz/presentation/pages/quiz_result_page.dart';
import '../features/quiz/domain/entities/quiz_result_models.dart';
import '../features/daily_verse/presentation/pages/daily_verse_page.dart';
import '../features/tasbih/presentation/pages/tasbih_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: LaunchExperiencePage.routeName,
        builder: (context, state) => const LaunchExperiencePage(),
      ),
      GoRoute(
        path: '/auth',
        name: AuthGatePage.routeName,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: '/home',
        name: HomePage.routeName,
        builder: (context, state) {
          final tabKey = state.uri.queryParameters['tab'];
          return HomePage(initialTabIndex: _resolveHomeTabIndex(tabKey));
        },
      ),
      GoRoute(
        path: '/surah/:surahId',
        name: SurahDetailPage.routeName,
        builder: (context, state) {
          final surahId =
              int.tryParse(state.pathParameters['surahId'] ?? '') ?? 1;
          return SurahDetailPage(surahId: surahId);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: QuizPage.routeName,
        builder: (context, state) {
          final surahId =
              int.tryParse(state.uri.queryParameters['surahId'] ?? '') ?? 1;
          final difficulty = state.uri.queryParameters['difficulty'] ?? 'easy';
          return QuizPage(surahId: surahId, difficultyKey: difficulty);
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: QuizResultPage.routeName,
        redirect: (context, state) {
          return state.extra is QuizResultArgs ? null : '/home';
        },
        builder: (context, state) {
          final args = state.extra! as QuizResultArgs;
          return QuizResultPage(args: args);
        },
      ),
      GoRoute(
        path: '/daily-verse',
        name: DailyVersePage.routeName,
        builder: (context, state) => const DailyVersePage(),
      ),
      GoRoute(
        path: '/prayer-times',
        name: PrayerTimesPage.routeName,
        builder: (context, state) => const PrayerTimesPage(),
      ),
      GoRoute(
        path: '/qibla',
        name: QiblaPage.routeName,
        builder: (context, state) => const QiblaPage(),
      ),
      GoRoute(
        path: '/tasbih',
        name: TasbihPage.routeName,
        builder: (context, state) => const TasbihPage(),
      ),
    ],
  );
});

int _resolveHomeTabIndex(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'quran':
      return 1;
    case 'learning':
      return 2;
    case 'audio':
      return 3;
    case 'profile':
      return 4;
    default:
      return 0;
  }
}
