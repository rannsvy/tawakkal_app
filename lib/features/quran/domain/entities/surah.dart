import 'package:equatable/equatable.dart';

import 'ayah.dart';

class SurahSummary extends Equatable {
  const SurahSummary({
    required this.surahId,
    required this.nameArabic,
    required this.nameLatin,
    required this.ayahCount,
    required this.revelationPlace,
    required this.meaning,
    required this.descriptionId,
    required this.audioFull,
  });

  final int surahId;
  final String nameArabic;
  final String nameLatin;
  final int ayahCount;
  final String revelationPlace;
  final String meaning;
  final String descriptionId;
  final Map<String, String> audioFull;

  @override
  List<Object?> get props => [
    surahId,
    nameArabic,
    nameLatin,
    ayahCount,
    revelationPlace,
    meaning,
    descriptionId,
    audioFull,
  ];
}

class SurahDetail extends Equatable {
  const SurahDetail({
    required this.summary,
    required this.ayahs,
    required this.tafsir,
  });

  final SurahSummary summary;
  final List<Ayah> ayahs;
  final List<TafsirEntry> tafsir;

  @override
  List<Object?> get props => [summary, ayahs, tafsir];
}
