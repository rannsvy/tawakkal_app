import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/chat/data/chat_prompt_builder.dart';
import 'package:tawakkal_app/features/quran/domain/entities/ayah.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';

void main() {
  test('buildContext maps surah, ayah translation, and tafsir snippets', () {
    const detail = SurahDetail(
      summary: SurahSummary(
        surahId: 1,
        nameArabic: 'al-fatihah-ar',
        nameLatin: 'Al-Fatihah',
        ayahCount: 7,
        revelationPlace: 'Makkah',
        meaning: 'Pembukaan',
        descriptionId: 'Desc',
        audioFull: <String, String>{},
      ),
      ayahs: <Ayah>[
        Ayah(
          surahId: 1,
          ayahNumber: 1,
          textArabic: 'bismillahir-rahmanir-rahim-ar',
          textLatin: 'Bismillah',
          textIndonesian:
              'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
          audioUrls: <String, String>{},
        ),
      ],
      tafsir: <TafsirEntry>[
        TafsirEntry(
          surahId: 1,
          ayahNumber: 1,
          text:
              'Ayat ini membuka semua aktivitas dengan penyandaran kepada Allah.',
        ),
      ],
    );

    final context = ChatPromptBuilder.buildContext(detail);

    expect(context.surahId, 1);
    expect(context.surahName, 'Al-Fatihah');
    expect(context.ayahTranslations, contains('1:1'));
    expect(context.tafsirSnippets, contains('Ayat ini membuka'));
  });
}
