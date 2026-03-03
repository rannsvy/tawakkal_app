import 'package:equatable/equatable.dart';

class ChatContext extends Equatable {
  const ChatContext({
    required this.surahId,
    required this.surahName,
    this.ayahTranslations,
    this.tafsirSnippets,
  });

  final int surahId;
  final String surahName;
  final String? ayahTranslations;
  final String? tafsirSnippets;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'surah_id': surahId,
    'surah_name': surahName,
    if (ayahTranslations != null && ayahTranslations!.isNotEmpty)
      'ayah_translations': ayahTranslations,
    if (tafsirSnippets != null && tafsirSnippets!.isNotEmpty)
      'tafsir_snippets': tafsirSnippets,
  };

  @override
  List<Object?> get props => [
    surahId,
    surahName,
    ayahTranslations,
    tafsirSnippets,
  ];
}
