import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/profile/domain/entities/profile_overview.dart';
import 'package:tawakkal_app/features/profile/domain/entities/reward_milestone.dart';
import 'package:tawakkal_app/features/profile/presentation/pages/profile_page.dart';
import 'package:tawakkal_app/features/profile/presentation/providers/profile_overview_providers.dart';

void main() {
  testWidgets('profile page renders redesigned sections and reward cards', (
    tester,
  ) async {
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileOverviewProvider.overrideWith((ref) async => _fakeOverview),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PROFIL SAYA'), findsOneWidget);
    expect(find.text('PROGRES SAAT INI'), findsOneWidget);
    expect(find.text('PENCAPAIAN IBADAH'), findsOneWidget);
    expect(find.text('AKUN'), findsNothing);
    expect(find.text('Penuntut Ilmu'), findsNothing);
    expect(find.text('Pencari Hikmah'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('reward-streak_3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('reward-streak_7')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('reward-tasbih_10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('reward-quiz_12')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('reward-xp_240')), findsNothing);
    expect(find.byKey(const ValueKey<String>('reward-xp_720')), findsNothing);
  });

  testWidgets('reward card opens detail bottom sheet', (tester) async {
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileOverviewProvider.overrideWith((ref) async => _fakeOverview),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('reward-streak_3')));
    await tester.pumpAndSettle();

    expect(find.text('Istiqamah Dasar'), findsWidgets);
    expect(find.textContaining('Progres:'), findsOneWidget);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1080, 2200);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

const ProfileOverview _fakeOverview = ProfileOverview(
  displayName: 'Reo Tawakkal',
  email: 'reo@example.com',
  isGuest: false,
  level: 4,
  xpTotal: 480,
  currentStreak: 5,
  longestStreak: 9,
  tasbihTodayCycles: 3,
  totalTasbihCompletions: 11,
  completedQuizUnits: 13,
  rewards: <RewardMilestone>[
    RewardMilestone(
      code: 'streak_3',
      title: 'Istiqamah Dasar',
      description: 'Jaga konsistensi ibadah selama 3 hari berturut-turut.',
      kind: RewardMilestoneKind.streak,
      currentValue: 5,
      threshold: 3,
      unitLabel: 'hari',
    ),
    RewardMilestone(
      code: 'streak_7',
      title: 'Istiqamah Pekanan',
      description: 'Capai rekor streak ibadah minimal 7 hari.',
      kind: RewardMilestoneKind.streak,
      currentValue: 9,
      threshold: 7,
      unitLabel: 'hari',
    ),
    RewardMilestone(
      code: 'tasbih_10',
      title: 'Sahabat Tasbih',
      description: 'Selesaikan 10 sesi tasbih dari riwayat ibadah.',
      kind: RewardMilestoneKind.tasbih,
      currentValue: 11,
      threshold: 10,
      unitLabel: 'sesi',
    ),
    RewardMilestone(
      code: 'quiz_12',
      title: 'Mahir Kuis',
      description: 'Selesaikan 12 unit kuis dengan status completed.',
      kind: RewardMilestoneKind.quiz,
      currentValue: 13,
      threshold: 12,
      unitLabel: 'kuis',
    ),
  ],
);
