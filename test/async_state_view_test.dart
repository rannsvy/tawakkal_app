import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/shared/widgets/async_state_view.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_view.dart';

void main() {
  Future<void> pumpAsyncState<T>(
    WidgetTester tester, {
    required AsyncValue<T> value,
    required Widget Function(T data) builder,
    bool useUniversalLoading = false,
    String loadingMessage = 'Preparing your daily path',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncStateView<T>(
          value: value,
          builder: builder,
          useUniversalLoading: useUniversalLoading,
          loadingMessage: loadingMessage,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows spinner loading by default', (tester) async {
    await pumpAsyncState<String>(
      tester,
      value: const AsyncLoading<String>(),
      builder: (data) => Text(data),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(UniversalLoadingView), findsNothing);
  });

  testWidgets('shows universal loading when enabled', (tester) async {
    await pumpAsyncState<String>(
      tester,
      value: const AsyncLoading<String>(),
      builder: (data) => Text(data),
      useUniversalLoading: true,
      loadingMessage: 'Generating quiz and AI feedback...',
    );

    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('Generating quiz and AI feedback...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders data view', (tester) async {
    await pumpAsyncState<String>(
      tester,
      value: const AsyncData<String>('Loaded'),
      builder: (data) => Text(data),
    );

    expect(find.text('Loaded'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(UniversalLoadingView), findsNothing);
  });

  testWidgets('universal loading fills scaffold body constraints', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            value: const AsyncLoading<String>(),
            useUniversalLoading: true,
            builder: (data) => Text(data),
          ),
        ),
      ),
    );
    await tester.pump();

    final rootSize = tester.getSize(
      find.byKey(const Key('universal-loading-root')),
    );
    expect(rootSize.width, 390);
    expect(rootSize.height, 844);
  });

  testWidgets('holds at 100 percent before rendering resolved state', (
    tester,
  ) async {
    final valueNotifier = ValueNotifier<AsyncValue<String>>(
      const AsyncLoading<String>(),
    );
    addTearDown(valueNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<AsyncValue<String>>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return AsyncStateView<String>(
              value: value,
              useUniversalLoading: true,
              showLoadingPercentage: true,
              builder: (data) => Text(data),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('Loaded'), findsNothing);

    valueNotifier.value = const AsyncData<String>('Loaded');
    await tester.pump();

    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Loaded'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('Loaded'), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(UniversalLoadingView), findsNothing);
    expect(find.text('Loaded'), findsOneWidget);
  });
}
