import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tawakkal_app/app/app.dart';

void main() {
  testWidgets('Auth gate renders on app start', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TawakkalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Tawakkal'), findsOneWidget);
    expect(find.text('Mulai sebagai Guest'), findsOneWidget);
  });
}
