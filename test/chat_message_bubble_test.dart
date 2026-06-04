import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/chat/domain/entities/chat_message.dart';
import 'package:tawakkal_app/features/chat/presentation/widgets/chat_message_bubble.dart';

void main() {
  testWidgets('assistant markdown table is rendered as readable rows', (
    tester,
  ) async {
    const content = '''
Tentu, berikut adalah tabel biografi singkat Umar bin Khattab:

| **Aspek** | **Detail** |
|:---|:---|
| **Nama Lengkap** | Umar bin Al-Khattab bin Nufail Al-Adawi Al-Quraisy |
| **Julukan** | Al-Faruq (Pembeda antara hak dan batil) |
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: ChatMessageBubble(
              message: ChatMessage(
                id: 'assistant-1',
                role: ChatRole.assistant,
                content: content,
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Aspek / Detail'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(
      find.text('Umar bin Al-Khattab bin Nufail Al-Adawi Al-Quraisy'),
      findsOneWidget,
    );
    expect(find.text('| **Aspek** | **Detail** |'), findsNothing);
  });

  testWidgets('assistant response renders html break tags as line breaks', (
    tester,
  ) async {
    const content =
        'Peran Penting\n'
        '1. Dijuluki Al-Faruq oleh Rasulullah SAW.<br>2. Diangkat menjadi Khalifah oleh Abu Bakar.<br/>3. Menetapkan kalender Hijriah.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: ChatMessageBubble(
              message: ChatMessage(
                id: 'assistant-2',
                role: ChatRole.assistant,
                content: content,
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('<br>'), findsNothing);
    expect(find.textContaining('<br/>'), findsNothing);
    expect(find.textContaining('2. Diangkat menjadi Khalifah'), findsOneWidget);
    expect(
      find.textContaining('3. Menetapkan kalender Hijriah'),
      findsOneWidget,
    );
  });

  testWidgets('assistant response does not crash on malformed pipe lines', (
    tester,
  ) async {
    const content = 'Ringkasan\n|\n| **Aspek** | **Detail** |\n|';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: ChatMessageBubble(
              message: ChatMessage(
                id: 'assistant-3',
                role: ChatRole.assistant,
                content: content,
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ringkasan'), findsOneWidget);
  });
}
