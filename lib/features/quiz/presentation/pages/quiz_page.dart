import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../../shared/widgets/universal_loading_view.dart';
import '../../../learning/domain/entities/difficulty.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../domain/entities/quiz_models.dart';
import '../../domain/entities/quiz_result_models.dart';
import '../../domain/services/quiz_text_compactor.dart';
import '../providers/quiz_providers.dart';
import 'quiz_result_page.dart';
import '../widgets/compact_expandable_text.dart';

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
  static const Duration _completionHoldDuration = Duration(milliseconds: 250);

  int _index = 0;
  final Map<String, String> _answers = <String, String>{};
  bool _showFeedback = false;
  bool _resultHandled = false;
  int _remainingLives = 3;
  double? _completionPendingProgress;
  final Stopwatch _quizStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _quizStopwatch.start();
  }

  @override
  void dispose() {
    _quizStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = Difficulty.fromKey(widget.difficultyKey);
    final quizState = ref.watch(
      quizPayloadProvider(
        QuizRequest(surahId: widget.surahId, difficulty: difficulty),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: AsyncStateView(
        value: quizState,
        useUniversalLoading: true,
        loadingMessage: 'Generating quiz and AI feedback...',
        loadingIcon: Icons.auto_awesome_rounded,
        showLoadingPercentage: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_index >= quiz.questions.length) {
      final resultArgs = _buildResultArgs(quiz: quiz, difficulty: difficulty);
      if (!_resultHandled) {
        _resultHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await ref
                .read(progressActionsProvider)
                .recordQuizCompletion(
                  surahId: quiz.surahId,
                  difficulty: difficulty,
                  score: resultArgs.score,
                  maxScore: resultArgs.maxScore,
                  xpEarned: resultArgs.xpEarned,
                );
          } catch (_) {
            // Result page should still open if progress sync fails.
          }

          if (!mounted) {
            return;
          }

          setState(() {
            _completionPendingProgress = 1.0;
          });
          await Future<void>.delayed(_completionHoldDuration);
          if (!mounted) {
            return;
          }

          this.context.goNamed(QuizResultPage.routeName, extra: resultArgs);
        });
      }

      return _CompletionPendingView(
        language: quiz.language,
        progress: _completionPendingProgress,
      );
    }

    final question = quiz.questions[_index];
    final ayahSnippet = ref
        .watch(surahDetailProvider(quiz.surahId))
        .maybeWhen(
          data: (surah) =>
              _resolveAyahSnippet(surah: surah, refs: question.ayahRefs),
          orElse: () => null,
        );
    final selected = _answers[question.id];
    final isCorrect = selected == question.correctOptionId;
    final questionProgress = (_index + 1) / quiz.questions.length;

    return RichPageBackground(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Tutup kuis',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: TawakkalColors.textSecondary,
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: questionProgress,
                            minHeight: 10,
                            color: TawakkalColors.accentGold,
                            backgroundColor: isDark
                                ? TawakkalColors.surfaceDark
                                : TawakkalColors.surfaceLightAlt,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _LivesBadge(lives: _remainingLives),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      _showFeedback ? 292 : 140,
                    ),
                    children: [
                      Text(
                        'Pertanyaan ${_index + 1} dari ${quiz.questions.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TawakkalColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _titleForQuestionType(question.type),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (ayahSnippet != null) ...[
                        const SizedBox(height: 14),
                        _AyahSnippetCard(snippet: ayahSnippet),
                      ],
                      const SizedBox(height: 14),
                      RichInfoCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Text(
                          question.prompt,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isDark
                                    ? TawakkalColors.textPrimaryDark
                                    : TawakkalColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...question.options.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AnswerOptionTile(
                            option: entry.value,
                            label: String.fromCharCode(65 + entry.key),
                            selectedId: selected,
                            correctId: question.correctOptionId,
                            revealResult: _showFeedback,
                            onTap: _showFeedback
                                ? null
                                : () {
                                    setState(() {
                                      _answers[question.id] = entry.value.id;
                                    });
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showFeedback && selected != null
                    ? _QuizFeedbackSheet(
                        key: ValueKey<String>('feedback_${question.id}'),
                        isCorrect: isCorrect,
                        language: quiz.language,
                        feedback: isCorrect
                            ? question.feedback.correct
                            : question.feedback.incorrect,
                        explanation: question.explanation,
                        correctAnswer: _findCorrectAnswer(
                          options: question.options,
                          correctOptionId: question.correctOptionId,
                        ),
                        onContinue: () {
                          setState(() {
                            _showFeedback = false;
                            _index += 1;
                          });
                        },
                      )
                    : _QuizActionBar(
                        key: ValueKey<String>('action_${question.id}'),
                        enabled: selected != null,
                        onPressed: selected == null
                            ? null
                            : () {
                                final answer = _answers[question.id];
                                if (answer == null) {
                                  return;
                                }
                                setState(() {
                                  _showFeedback = true;
                                  if (answer != question.correctOptionId &&
                                      _remainingLives > 0) {
                                    _remainingLives -= 1;
                                  }
                                });
                              },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateScore(QuizPayload quiz) {
    return _answers.entries.where((entry) {
      final question = quiz.questions.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => const QuizQuestion(
          id: '',
          type: QuizQuestionType.multipleChoice,
          prompt: '',
          ayahRefs: <String>[],
          options: <QuizOption>[],
          correctOptionId: '',
          explanation: '',
          feedback: QuizFeedback(correct: '', incorrect: ''),
          groundingRefs: <Map<String, String>>[],
        ),
      );
      return question.correctOptionId == entry.value;
    }).length;
  }

  QuizResultArgs _buildResultArgs({
    required QuizPayload quiz,
    required Difficulty difficulty,
  }) {
    _quizStopwatch.stop();
    final isEnglish = quiz.language.toLowerCase() == 'en';
    final score = _calculateScore(quiz);
    final xp =
        (score * quiz.scoring.xpPerCorrect) + quiz.scoring.completionBonus;
    final answeredItems = quiz.questions
        .map((question) {
          final selectedId = _answers[question.id] ?? '';
          final selectedText =
              _findOptionText(
                options: question.options,
                selectedOptionId: selectedId,
              ) ??
              '';
          final correctText =
              _findCorrectAnswer(
                options: question.options,
                correctOptionId: question.correctOptionId,
              ) ??
              '';
          final compactSelected = QuizTextCompactor.compactAnswer(
            selectedText,
            isEnglish: isEnglish,
          );
          final compactCorrect = QuizTextCompactor.compactAnswer(
            correctText,
            isEnglish: isEnglish,
          );
          final compactExplanation = QuizTextCompactor.compactExplanation(
            question.explanation,
            isEnglish: isEnglish,
          );
          final compactFeedbackCorrect = QuizTextCompactor.compactFeedback(
            question.feedback.correct,
            isEnglish: isEnglish,
          );
          final compactFeedbackIncorrect = QuizTextCompactor.compactFeedback(
            question.feedback.incorrect,
            isEnglish: isEnglish,
          );

          return AnsweredQuizItem(
            questionId: question.id,
            type: question.type,
            prompt: question.prompt,
            selectedOptionText: compactSelected.compact,
            fullSelectedOptionText: compactSelected.original,
            correctOptionText: compactCorrect.compact,
            fullCorrectOptionText: compactCorrect.original,
            isCorrect: selectedId == question.correctOptionId,
            explanation: compactExplanation.compact,
            fullExplanation: compactExplanation.original,
            feedbackCorrect: compactFeedbackCorrect.compact,
            fullFeedbackCorrect: compactFeedbackCorrect.original,
            feedbackIncorrect: compactFeedbackIncorrect.compact,
            fullFeedbackIncorrect: compactFeedbackIncorrect.original,
            ayahRefs: question.ayahRefs,
          );
        })
        .toList(growable: false);

    return QuizResultArgs(
      quizId: quiz.quizId,
      surahId: quiz.surahId,
      surahName: quiz.surahName,
      difficultyKey: difficulty.name,
      language: quiz.language,
      score: score,
      maxScore: quiz.questions.length,
      xpEarned: xp,
      elapsedSeconds: _quizStopwatch.elapsed.inSeconds,
      answeredItems: answeredItems,
    );
  }

  _AyahSnippetData? _resolveAyahSnippet({
    required SurahDetail surah,
    required List<String> refs,
  }) {
    for (final ref in refs) {
      final parsed = _parseAyahRef(ref);
      if (parsed == null) {
        continue;
      }
      if (parsed.surahId != null && parsed.surahId != surah.summary.surahId) {
        continue;
      }
      final ayah = surah.ayahs.firstWhere(
        (item) => item.ayahNumber == parsed.ayahNumber,
        orElse: () => const Ayah(
          surahId: 0,
          ayahNumber: 0,
          textArabic: '',
          textLatin: '',
          textIndonesian: '',
          audioUrls: <String, String>{},
        ),
      );
      if (ayah.ayahNumber == 0) {
        continue;
      }
      return _AyahSnippetData(
        reference: '${surah.summary.surahId}:${ayah.ayahNumber}',
        arabic: ayah.textArabic,
        translation: ayah.textIndonesian,
      );
    }
    return null;
  }

  _AyahRef? _parseAyahRef(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final pair = RegExp(r'(\d+):(\d+)').firstMatch(normalized);
    if (pair != null) {
      return _AyahRef(
        surahId: int.tryParse(pair.group(1)!),
        ayahNumber: int.tryParse(pair.group(2)!) ?? 0,
      );
    }

    final ayahOnly = int.tryParse(normalized);
    if (ayahOnly != null) {
      return _AyahRef(surahId: null, ayahNumber: ayahOnly);
    }

    return null;
  }

  String _titleForQuestionType(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.matching:
        return 'Cocokkan makna yang tepat';
      case QuizQuestionType.ordering:
        return 'Urutkan makna dengan benar';
      case QuizQuestionType.reflection:
        return 'Refleksi pemahaman ayat';
      case QuizQuestionType.multipleChoice:
        return 'Pilih jawaban yang paling tepat';
    }
  }

  String? _findCorrectAnswer({
    required List<QuizOption> options,
    required String correctOptionId,
  }) {
    for (final option in options) {
      if (option.id == correctOptionId) {
        return option.text;
      }
    }
    return null;
  }

  String? _findOptionText({
    required List<QuizOption> options,
    required String selectedOptionId,
  }) {
    for (final option in options) {
      if (option.id == selectedOptionId) {
        return option.text;
      }
    }
    return null;
  }
}

class _CompletionPendingView extends StatelessWidget {
  const _CompletionPendingView({required this.language, this.progress});

  final String language;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final isEnglish = language.toLowerCase() == 'en';
    return UniversalLoadingView(
      message: isEnglish
          ? 'Finalizing result and AI feedback...'
          : 'Menyiapkan hasil dan feedback AI...',
      progress: progress,
      primaryIcon: Icons.auto_awesome_rounded,
      showPercentage: false,
    );
  }
}

class _AyahRef {
  const _AyahRef({required this.surahId, required this.ayahNumber});

  final int? surahId;
  final int ayahNumber;
}

class _AyahSnippetData {
  const _AyahSnippetData({
    required this.reference,
    required this.arabic,
    required this.translation,
  });

  final String reference;
  final String arabic;
  final String translation;
}

class _AyahSnippetCard extends StatelessWidget {
  const _AyahSnippetCard({required this.snippet});

  final _AyahSnippetData snippet;

  @override
  Widget build(BuildContext context) {
    return RichInfoCard(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF162E29), Color(0xFF112823)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                color: TawakkalColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Ayah ${snippet.reference}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TawakkalColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            snippet.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TawakkalTypography.arabicStyle(
              color: TawakkalColors.textPrimaryDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            snippet.translation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TawakkalColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.option,
    required this.label,
    required this.selectedId,
    required this.correctId,
    required this.revealResult,
    required this.onTap,
  });

  final QuizOption option;
  final String label;
  final String? selectedId;
  final String correctId;
  final bool revealResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == option.id;
    final isCorrectOption = option.id == correctId;
    final isWrongSelection = revealResult && isSelected && !isCorrectOption;
    final revealCorrect = revealResult && isCorrectOption;

    final borderColor = revealCorrect
        ? const Color(0xFF26D691)
        : isWrongSelection
        ? const Color(0xFFE36D6D)
        : isSelected
        ? TawakkalColors.primary
        : Colors.white.withValues(alpha: 0.10);
    final background = revealCorrect
        ? const Color(0x1A26D691)
        : isWrongSelection
        ? const Color(0x22E36D6D)
        : isSelected
        ? TawakkalColors.primary.withValues(alpha: 0.12)
        : const Color(0xFF162421);

    final labelBg = revealCorrect
        ? const Color(0xFF26D691)
        : isWrongSelection
        ? const Color(0xFFE36D6D)
        : isSelected
        ? TawakkalColors.primary
        : Colors.transparent;
    final labelColor = revealCorrect || isWrongSelection || isSelected
        ? TawakkalColors.backgroundDark
        : TawakkalColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TawakkalColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                    height: 1.36,
                  ),
                ),
              ),
              if (revealCorrect) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF26D691),
                  size: 22,
                ),
              ],
              if (isWrongSelection) ...[
                const SizedBox(width: 10),
                const Icon(Icons.cancel, color: Color(0xFFE36D6D), size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizActionBar extends StatelessWidget {
  const _QuizActionBar({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: Color(0xFF162421),
          border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: TawakkalColors.primary,
              disabledBackgroundColor: Color(0xFF2A3B37),
              foregroundColor: TawakkalColors.backgroundDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Check Answer'),
          ),
        ),
      ),
    );
  }
}

class _QuizFeedbackSheet extends StatelessWidget {
  const _QuizFeedbackSheet({
    super.key,
    required this.isCorrect,
    required this.language,
    required this.feedback,
    required this.explanation,
    required this.correctAnswer,
    required this.onContinue,
  });

  final bool isCorrect;
  final String language;
  final String feedback;
  final String explanation;
  final String? correctAnswer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final background = isCorrect
        ? const Color(0xFF11392B)
        : const Color(0xFF2F1515);
    final borderColor = isCorrect
        ? const Color(0xFF1A5F4A)
        : const Color(0xFF5B2323);
    final titleColor = isCorrect
        ? const Color(0xFF34D399)
        : const Color(0xFFF2B8B8);
    final iconColor = isCorrect
        ? const Color(0xFFFBBF24)
        : const Color(0xFFE36D6D);
    final isEnglish = language.toLowerCase() == 'en';
    final compactFeedback = QuizTextCompactor.compactFeedback(
      feedback,
      isEnglish: isEnglish,
    );
    final compactExplanation = QuizTextCompactor.compactExplanation(
      explanation,
      isEnglish: isEnglish,
    );
    final compactCorrectAnswer = QuizTextCompactor.compactAnswer(
      correctAnswer ?? '',
      isEnglish: isEnglish,
    );

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: borderColor, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isCorrect ? 'Correct!' : 'Keep Learning!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CompactExpandableText(
              fullText: compactFeedback.original,
              compactText: compactFeedback.compact,
              isTruncated: compactFeedback.isTruncated,
              label: isEnglish ? 'Feedback' : 'Feedback',
              isEnglish: isEnglish,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TawakkalColors.textPrimaryDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            CompactExpandableText(
              fullText: compactExplanation.original,
              compactText: compactExplanation.compact,
              isTruncated: compactExplanation.isTruncated,
              label: isEnglish ? 'Explanation' : 'Penjelasan',
              isEnglish: isEnglish,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TawakkalColors.textSecondary,
                height: 1.38,
              ),
            ),
            if (!isCorrect &&
                correctAnswer != null &&
                correctAnswer!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                isEnglish ? 'Correct answer' : 'Jawaban benar',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TawakkalColors.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              CompactExpandableText(
                fullText: compactCorrectAnswer.original,
                compactText: compactCorrectAnswer.compact,
                isTruncated: compactCorrectAnswer.isTruncated,
                label: isEnglish ? 'Correct answer' : 'Jawaban benar',
                isEnglish: isEnglish,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TawakkalColors.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: TawakkalColors.primary,
                  foregroundColor: TawakkalColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(isCorrect ? 'Continue' : 'Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivesBadge extends StatelessWidget {
  const _LivesBadge({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF162421),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFE36D6D), size: 18),
          const SizedBox(width: 4),
          Text(
            '$lives',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TawakkalColors.textPrimaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
