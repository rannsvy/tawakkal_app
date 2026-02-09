import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_state_view.dart';
import '../../../learning/domain/entities/difficulty.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../domain/entities/quiz_models.dart';
import '../providers/quiz_providers.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({
    super.key,
    required this.surahId,
    required this.difficultyKey,
  });

  static const routeName = 'quiz-page';

  final int surahId;
  final String difficultyKey;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _index = 0;
  final Map<String, String> _answers = <String, String>{};
  bool _showFeedback = false;
  bool _completionRecorded = false;

  @override
  Widget build(BuildContext context) {
    final difficulty = Difficulty.fromKey(widget.difficultyKey);
    final quizState = ref.watch(
      quizPayloadProvider(
        QuizRequest(surahId: widget.surahId, difficulty: difficulty),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Surah')),
      body: AsyncStateView(
        value: quizState,
        onRetry: () => ref.invalidate(
          quizPayloadProvider(
            QuizRequest(surahId: widget.surahId, difficulty: difficulty),
          ),
        ),
        builder: (quiz) => _buildQuizBody(context, quiz, difficulty),
      ),
    );
  }

  Widget _buildQuizBody(
    BuildContext context,
    QuizPayload quiz,
    Difficulty difficulty,
  ) {
    if (_index >= quiz.questions.length) {
      final score = _answers.entries
          .where(
            (entry) =>
                quiz.questions
                    .firstWhere((question) => question.id == entry.key)
                    .correctOptionId ==
                entry.value,
          )
          .length;
      final xp =
          (score * quiz.scoring.xpPerCorrect) + quiz.scoring.completionBonus;

      if (!_completionRecorded) {
        _completionRecorded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(progressActionsProvider)
              .recordQuizCompletion(
                surahId: quiz.surahId,
                difficulty: difficulty,
                score: score,
                maxScore: quiz.questions.length,
                xpEarned: xp,
              );
        });
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Alhamdulillah, kuis selesai.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text('Skor: $score / ${quiz.questions.length}'),
                  Text('XP didapat: $xp'),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Kembali ke Beranda'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = quiz.questions[_index];
    final selected = _answers[question.id];
    final isCorrect = selected == question.correctOptionId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pertanyaan ${_index + 1} dari ${quiz.questions.length}'),
                const SizedBox(height: 8),
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...question.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showFeedback
                          ? null
                          : () {
                              setState(() {
                                _answers[question.id] = option.id;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == option.id
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0x22000000),
                            width: selected == option.id ? 1.5 : 1,
                          ),
                          color: selected == option.id
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.08)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected == option.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(option.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showFeedback && selected != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCorrect
                          ? question.feedback.correct
                          : question.feedback.incorrect,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            if (!_showFeedback) {
                              setState(() {
                                _showFeedback = true;
                              });
                              return;
                            }
                            setState(() {
                              _index += 1;
                              _showFeedback = false;
                            });
                          },
                    child: Text(_showFeedback ? 'Lanjut' : 'Jawab'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
