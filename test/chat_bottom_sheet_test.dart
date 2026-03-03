import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/chat/domain/entities/chat_context.dart';
import 'package:tawakkal_app/features/chat/domain/entities/chat_message.dart';
import 'package:tawakkal_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:tawakkal_app/features/chat/domain/entities/chat_state.dart';
import 'package:tawakkal_app/features/chat/presentation/providers/chat_providers.dart';
import 'package:tawakkal_app/features/chat/presentation/widgets/chat_bottom_sheet.dart';
import 'package:tawakkal_app/features/chat/presentation/widgets/chat_floating_dock.dart';

void main() {
  testWidgets('floating dock opens chat bottom sheet', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ChatFloatingDock(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChatFloatingDock));
    await tester.pumpAndSettle();

    expect(find.byType(ChatBottomSheet), findsOneWidget);
    expect(find.text('Tawakkal AI'), findsOneWidget);
  });

  testWidgets('sending message renders user and assistant bubbles', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ChatBottomSheet())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Explain Surah Al-Ikhlas');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Explain Surah Al-Ikhlas'), findsOneWidget);
    expect(
      find.text('Mock reply for: Explain Surah Al-Ikhlas'),
      findsOneWidget,
    );

    expect(find.byTooltip('Copy response'), findsOneWidget);
    expect(find.byTooltip('Helpful response'), findsOneWidget);
    expect(find.byTooltip('Not helpful response'), findsOneWidget);

    await tester.tap(find.byTooltip('Helpful response'));
    await tester.pumpAndSettle();
    expect(
      container.read(chatControllerProvider).reactionsByMessageId.values.first,
      ChatReaction.up,
    );

    await tester.tap(find.byTooltip('Not helpful response'));
    await tester.pumpAndSettle();
    expect(
      container.read(chatControllerProvider).reactionsByMessageId.values.first,
      ChatReaction.down,
    );

    await tester.tap(find.byTooltip('Not helpful response'));
    await tester.pumpAndSettle();
    expect(
      container.read(chatControllerProvider).reactionsByMessageId,
      isEmpty,
    );

    await tester.tap(find.byTooltip('Copy response'));
    await tester.pumpAndSettle();
    expect(find.text('Response copied.'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
    ChatContext? surahContext,
  }) async {
    return 'Mock reply for: $message';
  }
}
