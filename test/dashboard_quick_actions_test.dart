import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tawakkal_app/features/auth/domain/auth_user.dart';
import 'package:tawakkal_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:tawakkal_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:tawakkal_app/features/progress/domain/entities/progress_snapshot.dart';
import 'package:tawakkal_app/features/progress/presentation/providers/progress_providers.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';

void main() {
  testWidgets('quick action cards navigate to dedicated pages', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: DashboardPage(onSelectTab: (_) {})),
        ),
        GoRoute(
          path: '/daily-verse',
          builder: (context, state) => const Scaffold(body: Text('daily-page')),
        ),
        GoRoute(
          path: '/qibla',
          builder: (context, state) => const Scaffold(body: Text('qibla-page')),
        ),
        GoRoute(
          path: '/prayer-times',
          builder: (context, state) =>
              const Scaffold(body: Text('prayer-page')),
        ),
        GoRoute(
          path: '/tasbih',
          builder: (context, state) =>
              const Scaffold(body: Text('tasbih-page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          progressSnapshotProvider.overrideWith((ref) async {
            return const ProgressSnapshot(
              xpTotal: 200,
              currentStreak: 3,
              longestStreak: 8,
              level: 2,
            );
          }),
          surahListProvider.overrideWith(
            (ref) async => const <SurahSummary>[
              SurahSummary(
                surahId: 67,
                nameArabic: 'الملك',
                nameLatin: 'Al-Mulk',
                ayahCount: 30,
                revelationPlace: 'Makkah',
                meaning: 'Kerajaan',
                descriptionId: '',
                audioFull: <String, String>{},
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Verse'));
    await tester.pumpAndSettle();
    expect(find.text('daily-page'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qibla Finder'));
    await tester.pumpAndSettle();
    expect(find.text('qibla-page'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();

    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(horizontal.first, const Offset(-180, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prayer Times'));
    await tester.pumpAndSettle();
    expect(find.text('prayer-page'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.drag(horizontal.first, const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasbih'));
    await tester.pumpAndSettle();
    expect(find.text('tasbih-page'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  @override
  Future<TawakkalUser?> build() async {
    return const TawakkalUser(
      id: 'u1',
      displayName: 'Tester',
      isGuest: false,
      email: 'tester@example.com',
    );
  }
}
