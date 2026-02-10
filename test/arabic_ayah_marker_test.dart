import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/quran/domain/entities/ayah.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:tawakkal_app/features/quran/presentation/widgets/ayah_card.dart';
import 'package:tawakkal_app/shared/utils/arabic_ayah_marker.dart';

void main() {
  group('Arabic ayah marker formatter', () {
    test('converts western numbers to eastern arabic digits', () {
      expect(toEasternArabicDigits(1), '١');
      expect(toEasternArabicDigits(10), '١٠');
      expect(toEasternArabicDigits(286), '٢٨٦');
    });

    test('formats end marker with U+06DD ornament', () {
      expect(formatAyahEndingMarker(1), '۝١');
      expect(formatAyahEndingMarker(67), '۝٦٧');
      expect(formatAyahEndingMarker(0), isEmpty);
    });
  });

  testWidgets('AyahCard renders inline ayah ornament marker', (tester) async {
    const ayah = Ayah(
      surahId: 1,
      ayahNumber: 12,
      textArabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      textLatin: 'Bismillahirrahmanirrahim',
      textIndonesian: 'Dengan nama Allah Yang Maha Pengasih...',
      audioUrls: <String, String>{},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ayahBookmarkProvider.overrideWith((ref, locator) async => false),
          ayahNoteProvider.overrideWith((ref, locator) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AyahCard(ayah: ayah, onPlayPressed: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('۝١٢'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });
}
