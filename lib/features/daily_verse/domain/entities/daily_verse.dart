class DailyVerse {
  const DailyVerse({
    required this.dateKey,
    required this.surahId,
    required this.ayahNumber,
    required this.textArabic,
    required this.textLatin,
    required this.textIndonesian,
    required this.source,
  });

  final String dateKey;
  final int surahId;
  final int ayahNumber;
  final String textArabic;
  final String textLatin;
  final String textIndonesian;
  final String source;
}
