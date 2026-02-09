import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  const Ayah({
    required this.surahId,
    required this.ayahNumber,
    required this.textArabic,
    required this.textLatin,
    required this.textIndonesian,
    this.textEnglish,
    required this.audioUrls,
  });

  final int surahId;
  final int ayahNumber;
  final String textArabic;
  final String textLatin;
  final String textIndonesian;
  final String? textEnglish;
  final Map<String, String> audioUrls;

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    textArabic,
    textLatin,
    textIndonesian,
    textEnglish,
    audioUrls,
  ];
}

class TafsirEntry extends Equatable {
  const TafsirEntry({
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    this.source = 'equran_tafsir_id',
  });

  final int surahId;
  final int ayahNumber;
  final String text;
  final String source;

  @override
  List<Object?> get props => [surahId, ayahNumber, text, source];
}
