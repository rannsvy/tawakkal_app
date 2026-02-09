import 'difficulty.dart';

class LearningStage {
  const LearningStage({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.difficulty,
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final Difficulty difficulty;
}

const List<LearningStage> kDefaultLearningStages = <LearningStage>[
  LearningStage(
    id: 'intro',
    title: 'Pengantar Surah',
    description: 'Tema utama dan konteks ringkas surah.',
    order: 1,
    difficulty: Difficulty.easy,
  ),
  LearningStage(
    id: 'vocab',
    title: 'Kosakata Kunci',
    description: 'Istilah penting yang sering muncul pada surah.',
    order: 2,
    difficulty: Difficulty.easy,
  ),
  LearningStage(
    id: 'meaning',
    title: 'Makna Per Ayat',
    description: 'Pemahaman ayat secara bertahap.',
    order: 3,
    difficulty: Difficulty.medium,
  ),
  LearningStage(
    id: 'quiz',
    title: 'Kuis Reflektif',
    description: 'Latihan pemahaman sesuai tingkat kesulitan.',
    order: 4,
    difficulty: Difficulty.hard,
  ),
];
