import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/auth_gate_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/quran/presentation/pages/surah_detail_page.dart';
import '../features/quiz/presentation/pages/quiz_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: AuthGatePage.routeName,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: '/home',
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
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
    ],
  );
});
