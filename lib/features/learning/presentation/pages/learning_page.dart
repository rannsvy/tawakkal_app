import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_state_view.dart';
import '../../domain/entities/difficulty.dart';
import '../../domain/entities/learning_stage.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key});

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  Difficulty _difficulty = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    final surahsState = ref.watch(surahListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Jalur Belajar Surah',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: Difficulty.values.map((difficulty) {
            return ChoiceChip(
              label: Text(_difficultyLabel(difficulty)),
              selected: _difficulty == difficulty,
              onSelected: (_) {
                setState(() {
                  _difficulty = difficulty;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: kDefaultLearningStages
                  .map(
                    (stage) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text('${stage.order}'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(stage.description),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pilih Surah untuk Mulai Kuis',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AsyncStateView(
          value: surahsState,
          onRetry: () => ref.invalidate(surahListProvider),
          builder: (surahs) {
            return Column(
              children: surahs.map((surah) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(surah.nameLatin),
                      subtitle: Text('${surah.ayahCount} ayat'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          context.push(
                            '/quiz?surahId=${surah.surahId}&difficulty=${_difficulty.name}',
                          );
                        },
                        child: const Text('Mulai'),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _difficultyLabel(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => 'Mudah',
      Difficulty.medium => 'Menengah',
      Difficulty.hard => 'Sulit',
    };
  }
}
