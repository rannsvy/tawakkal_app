import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../domain/entities/quiz_result_models.dart';
import '../../domain/services/quiz_result_insight_builder.dart';
import '../../domain/services/quiz_text_compactor.dart';
import '../widgets/compact_expandable_text.dart';

class QuizResultPage extends StatelessWidget {
  const QuizResultPage({
    super.key,
    required this.args,
    this.onBackToPathTap,
    this.onCloseTap,
  });

  static const routeName = 'quiz-result-page';

  final QuizResultArgs args;
  final VoidCallback? onBackToPathTap;
  final VoidCallback? onCloseTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = const QuizResultInsightBuilder().build(args);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : TawakkalColors.backgroundLight,
      body: RichPageBackground(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 168),
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  _ResultTopBar(
                    onClose: () => _onClose(context),
                    summaryLabel: args.isEnglish ? 'Summary' : 'Ringkasan',
                  ),
                  const SizedBox(height: 8),
                  _ScoreRing(
                    scorePercent: args.accuracyPercent.clamp(0, 100),
                    statusLabel: insight.performanceLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${args.surahName} | ${_difficultyLabel(args)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TawakkalColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.performanceMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TawakkalColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StatsRow(args: args),
                  const SizedBox(height: 18),
                  RichInfoCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF123228), Color(0xFF162421)],
                    ),
                    child: _AiInsightContent(args: args, insight: insight),
                  ),
                ],
              ),
            ),
            _BottomActionBar(
              reviewLabel: args.isEnglish
                  ? 'Review Mistakes'
                  : 'Lihat Kesalahan',
              backLabel: args.isEnglish ? 'Back to Path' : 'Kembali ke Jalur',
              onReviewTap: () => _showReviewMistakesSheet(context),
              onBackTap: () => _onBackToPath(context),
            ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(QuizResultArgs value) {
    switch (value.difficultyKey) {
      case 'hard':
        return value.isEnglish ? 'Hard' : 'Sulit';
      case 'medium':
        return value.isEnglish ? 'Medium' : 'Menengah';
      default:
        return value.isEnglish ? 'Easy' : 'Mudah';
    }
  }

  void _onClose(BuildContext context) {
    final callback = onCloseTap;
    if (callback != null) {
      callback();
      return;
    }
    context.go('/home?tab=learning');
  }

  void _onBackToPath(BuildContext context) {
    final callback = onBackToPathTap;
    if (callback != null) {
      callback();
      return;
    }
    context.go('/home?tab=learning');
  }

  Future<void> _showReviewMistakesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _ReviewMistakesSheet(args: args);
      },
    );
  }
}

class _ResultTopBar extends StatelessWidget {
  const _ResultTopBar({required this.onClose, required this.summaryLabel});

  final VoidCallback onClose;
  final String summaryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: TawakkalColors.textSecondary,
        ),
        Expanded(
          child: Text(
            summaryLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TawakkalColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Opacity(
          opacity: 0,
          child: IconButton(
            onPressed: null,
            icon: const Icon(Icons.share_rounded),
            color: TawakkalColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.scorePercent, required this.statusLabel});

  final int scorePercent;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: SizedBox(
          width: 188,
          height: 188,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: (scorePercent / 100).clamp(0, 1).toDouble(),
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _ProgressRingPainter(progress: value),
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TawakkalColors.accentGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$scorePercent%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? TawakkalColors.textPrimaryDark
                        : TawakkalColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 9.0;
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth;

    final trackPaint = Paint()
      ..color = const Color(0xFF1B2724)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = TawakkalColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.args});

  final QuizResultArgs args;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xBB1B2724)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0x1EFFFFFF)
              : const Color(0x12000000),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResultStat(
              label: args.isEnglish ? 'Time' : 'Waktu',
              value: _formatElapsed(args.elapsedSeconds),
              valueColor: Theme.of(context).brightness == Brightness.dark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: args.isEnglish ? 'Accuracy' : 'Akurasi',
              value: '${args.score}/${args.maxScore}',
              valueColor: TawakkalColors.primary,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ResultStat(
              label: 'XP',
              value: '+${args.xpEarned}',
              valueColor: TawakkalColors.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final remainingSeconds = safe % 60;
    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = remainingSeconds.toString().padLeft(2, '0');
    return '$minuteText:$secondText';
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: TawakkalColors.textSecondary,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0x24FFFFFF)
          : const Color(0x14000000),
    );
  }
}

class _AiInsightContent extends StatelessWidget {
  const _AiInsightContent({required this.args, required this.insight});

  final QuizResultArgs args;
  final QuizResultInsight insight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4D38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x330ED8A5)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: TawakkalColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args.isEnglish
                        ? 'AI Learning Insights'
                        : 'Insight Belajar AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TawakkalColors.textPrimaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    args.isEnglish
                        ? 'Personalized Analysis'
                        : 'Analisis Personal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TawakkalColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InsightRow(
          icon: Icons.check_circle_rounded,
          iconColor: TawakkalColors.primary,
          title: insight.strongUnderstandingTitle,
          body: insight.strongUnderstandingBody,
          isEnglish: args.isEnglish,
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        const SizedBox(height: 10),
        _InsightRow(
          icon: Icons.lightbulb_rounded,
          iconColor: TawakkalColors.accentGold,
          title: insight.focusAreaTitle,
          body: insight.focusAreaBody,
          isEnglish: args.isEnglish,
          useCompactedBody: true,
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.isEnglish,
    this.useCompactedBody = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool isEnglish;
  final bool useCompactedBody;

  @override
  Widget build(BuildContext context) {
    final compactedBody = useCompactedBody
        ? QuizTextCompactor.compactFocusArea(body, isEnglish: isEnglish)
        : null;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: TawakkalColors.textSecondary,
      height: 1.35,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TawakkalColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (!useCompactedBody)
                Text(body, style: bodyStyle)
              else
                CompactExpandableText(
                  fullText: compactedBody!.original,
                  compactText: compactedBody.compact,
                  isTruncated: compactedBody.isTruncated,
                  label: title,
                  isEnglish: isEnglish,
                  style: bodyStyle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.reviewLabel,
    required this.backLabel,
    required this.onReviewTap,
    required this.onBackTap,
  });

  final String reviewLabel;
  final String backLabel;
  final VoidCallback onReviewTap;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? Colors.black : TawakkalColors.backgroundLight)
                  .withValues(alpha: 0),
              isDark ? Colors.black : TawakkalColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReviewTap,
                  icon: const Icon(Icons.history_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? TawakkalColors.textPrimaryDark
                        : TawakkalColors.textPrimaryLight,
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0x1FFFFFFF)
                          : const Color(0x22000000),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xCC1B2724)
                        : Colors.white,
                  ),
                  label: Text(
                    reviewLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onBackTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: TawakkalColors.primary,
                    foregroundColor: TawakkalColors.backgroundDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    backLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewMistakesSheet extends StatefulWidget {
  const _ReviewMistakesSheet({required this.args});

  final QuizResultArgs args;

  @override
  State<_ReviewMistakesSheet> createState() => _ReviewMistakesSheetState();
}

class _ReviewMistakesSheetState extends State<_ReviewMistakesSheet> {
  int _currentIndex = 0;

  List<AnsweredQuizItem> get _mistakes => widget.args.incorrectItems;
  bool get _isEnglish => widget.args.isEnglish;

  void _closeSheet() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _goToIndex(int index) {
    final mistakes = _mistakes;
    if (mistakes.isEmpty) {
      return;
    }
    final safeIndex = index.clamp(0, mistakes.length - 1).toInt();
    if (safeIndex == _currentIndex) {
      return;
    }
    setState(() {
      _currentIndex = safeIndex;
    });
  }

  Future<void> _openAllMistakesIndex() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AllMistakesIndexSheet(
          mistakes: _mistakes,
          currentIndex: _currentIndex,
          isEnglish: _isEnglish,
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    _goToIndex(selected);
  }

  Future<void> _openHelp() async {
    final mistakes = _mistakes;
    if (mistakes.isEmpty) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ReviewHelpSheet(
          item: mistakes[_currentIndex],
          number: _currentIndex + 1,
          isEnglish: _isEnglish,
        );
      },
    );
  }

  void _goNextOrFinish() {
    final mistakes = _mistakes;
    if (mistakes.isEmpty) {
      return;
    }
    if (_currentIndex >= mistakes.length - 1) {
      _closeSheet();
      return;
    }
    setState(() {
      _currentIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mistakes = _mistakes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final title = _isEnglish ? 'Review Mistakes' : 'Tinjau Kesalahan';
    final subtitle = _isEnglish
        ? '${mistakes.length} items to improve'
        : '${mistakes.length} soal untuk ditingkatkan';

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162421) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x12000000),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _SheetHandle(isDark: isDark),
                  if (mistakes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: isDark
                                      ? TawakkalColors.textPrimaryDark
                                      : TawakkalColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: TawakkalColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    _ReviewProgressHeader(
                      current: _currentIndex + 1,
                      total: mistakes.length,
                      isEnglish: _isEnglish,
                    ),
                  const Divider(height: 1, color: Color(0x1FFFFFFF)),
                  Expanded(
                    child: mistakes.isEmpty
                        ? _NoMistakeState(isEnglish: _isEnglish)
                        : SingleChildScrollView(
                            physics: const ClampingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                            child: _MistakeCard(
                              item: mistakes[_currentIndex],
                              number: _currentIndex + 1,
                              isEnglish: _isEnglish,
                            ),
                          ),
                  ),
                ],
              ),
              if (mistakes.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ReviewBottomNavBar(
                    isEnglish: _isEnglish,
                    isLast: _currentIndex >= mistakes.length - 1,
                    onAllTap: _openAllMistakesIndex,
                    onNextTap: _goNextOrFinish,
                    onHelpTap: _openHelp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0x22000000),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ReviewProgressHeader extends StatelessWidget {
  const _ReviewProgressHeader({
    required this.current,
    required this.total,
    required this.isEnglish,
  });

  final int current;
  final int total;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final clampedTotal = total <= 0 ? 1 : total;
    final clampedProgress = (current / clampedTotal).clamp(0, 1).toDouble();
    final reviewLabel = isEnglish ? 'Review' : 'Tinjau';
    final countLabel = isEnglish
        ? '$current of $clampedTotal Mistakes'
        : '$current dari $clampedTotal Kesalahan';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reviewLabel.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TawakkalColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                ),
              ),
              Text(
                countLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TawakkalColors.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: isDark ? const Color(0xFF1F2D29) : const Color(0xFFE3ECEA),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedProgress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [TawakkalColors.accentGold, Color(0xFFD88914)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomNavBar extends StatelessWidget {
  const _ReviewBottomNavBar({
    required this.isEnglish,
    required this.isLast,
    required this.onAllTap,
    required this.onNextTap,
    required this.onHelpTap,
  });

  final bool isEnglish;
  final bool isLast;
  final VoidCallback onAllTap;
  final VoidCallback onNextTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryLabel = isLast
        ? (isEnglish ? 'Finish' : 'Selesai')
        : (isEnglish ? 'Next Mistake' : 'Soal Berikut');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF21B2724) : const Color(0xF2FFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x14FFFFFF) : const Color(0x11000000),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ReviewNavAction(
                  icon: Icons.grid_view_rounded,
                  label: isEnglish ? 'All Mistakes' : 'Semua Kesalahan',
                  onTap: onAllTap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: onNextTap,
                      icon: Icon(
                        isLast ? Icons.check_circle_rounded : Icons.play_arrow,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: TawakkalColors.primary,
                        foregroundColor: TawakkalColors.backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(
                        primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ReviewNavAction(
                  icon: Icons.help_outline_rounded,
                  label: isEnglish ? 'Help' : 'Bantuan',
                  onTap: onHelpTap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x1FFFFFFF)
                    : const Color(0x19000000),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewNavAction extends StatelessWidget {
  const _ReviewNavAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 74,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? TawakkalColors.textPrimaryDark
              : TawakkalColors.textPrimaryLight,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          minimumSize: const Size(70, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x0FFFFFFF)
                    : const Color(0x08000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: TawakkalColors.textSecondary, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TawakkalColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllMistakesIndexSheet extends StatelessWidget {
  const _AllMistakesIndexSheet({
    required this.mistakes,
    required this.currentIndex,
    required this.isEnglish,
  });

  final List<AnsweredQuizItem> mistakes;
  final int currentIndex;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = isEnglish ? 'All Mistakes' : 'Semua Kesalahan';
    final subtitle = isEnglish
        ? 'Jump directly to a question'
        : 'Langsung lompat ke pertanyaan';
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162421) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x12000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _SheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TawakkalColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x1FFFFFFF)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  itemCount: mistakes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = mistakes[index];
                    final isSelected = index == currentIndex;
                    final titleText = isEnglish
                        ? 'Question ${index + 1}'
                        : 'Pertanyaan ${index + 1}';

                    return ListTile(
                      onTap: () => Navigator.of(context).pop(index),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      tileColor: isSelected
                          ? TawakkalColors.primary.withValues(alpha: 0.15)
                          : (isDark
                                ? const Color(0xCC1B2724)
                                : const Color(0xFFF5F8F7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? TawakkalColors.primary.withValues(alpha: 0.42)
                              : Colors.transparent,
                        ),
                      ),
                      leading: CircleAvatar(
                        radius: 13,
                        backgroundColor: isSelected
                            ? TawakkalColors.primary
                            : TawakkalColors.textSecondary.withValues(
                                alpha: 0.25,
                              ),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isSelected
                                    ? TawakkalColors.backgroundDark
                                    : (isDark
                                          ? TawakkalColors.textPrimaryDark
                                          : TawakkalColors.textPrimaryLight),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      title: Text(
                        titleText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        item.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TawakkalColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: TawakkalColors.primary,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewHelpSheet extends StatelessWidget {
  const _ReviewHelpSheet({
    required this.item,
    required this.number,
    required this.isEnglish,
  });

  final AnsweredQuizItem item;
  final int number;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = item.fullFeedbackForResult.trim().isNotEmpty
        ? item.fullFeedbackForResult
        : item.fullExplanationText;
    final compactTip = QuizTextCompactor.compactExplanation(
      source,
      isEnglish: isEnglish,
    );
    final title = isEnglish ? 'Study Tip' : 'Tips Belajar';
    final subtitle = isEnglish
        ? 'Personalized guidance for this mistake'
        : 'Panduan personal untuk kesalahan ini';
    final closeLabel = isEnglish ? 'Got it' : 'Mengerti';

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.74,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162421) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x12000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _SheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TawakkalColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: TawakkalColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: isDark
                                      ? TawakkalColors.textPrimaryDark
                                      : TawakkalColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: TawakkalColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x1FFFFFFF)),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Question $number' : 'Pertanyaan $number',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TawakkalColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.prompt,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEnglish ? 'What to review' : 'Yang perlu ditinjau',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TawakkalColors.accentGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        compactTip.compact,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          height: 1.35,
                        ),
                      ),
                      if (item.ayahRefs.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.ayahRefs
                              .where((ref) => ref.trim().isNotEmpty)
                              .map(
                                (ref) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: isDark
                                        ? const Color(0x11FFFFFF)
                                        : const Color(0x0A000000),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0x1FFFFFFF)
                                          : const Color(0x12000000),
                                    ),
                                  ),
                                  child: Text(
                                    ref,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: TawakkalColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: TawakkalColors.primary,
                      foregroundColor: TawakkalColors.backgroundDark,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      closeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMistakeState extends StatelessWidget {
  const _NoMistakeState({required this.isEnglish});

  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: TawakkalColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isEnglish
                  ? 'No mistakes in this session.'
                  : 'Tidak ada kesalahan di sesi ini.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isEnglish
                  ? 'Try a higher difficulty to keep your progress growing.'
                  : 'Coba tingkat kesulitan lebih tinggi agar progres tetap bertumbuh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TawakkalColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    required this.item,
    required this.number,
    required this.isEnglish,
  });

  final AnsweredQuizItem item;
  final int number;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedSource = item.fullSelectedAnswer.trim().isNotEmpty
        ? item.fullSelectedAnswer
        : (isEnglish ? 'Not selected' : 'Belum dipilih');
    final compactSelected = QuizTextCompactor.compactAnswer(
      selectedSource,
      isEnglish: isEnglish,
    );
    final compactCorrect = QuizTextCompactor.compactAnswer(
      item.fullCorrectAnswer,
      isEnglish: isEnglish,
    );
    final compactFeedback = QuizTextCompactor.compactFeedback(
      item.fullFeedbackForResult,
      isEnglish: isEnglish,
    );
    final compactExplanation = QuizTextCompactor.compactExplanation(
      item.fullExplanationText,
      isEnglish: isEnglish,
    );

    return RichInfoCard(
      borderRadius: 16,
      color: isDark ? const Color(0xCC1B2724) : const Color(0xFFF6F8F8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isEnglish ? 'Question' : 'Pertanyaan'} $number',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TawakkalColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.prompt,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _AnswerRow(
            label: isEnglish ? 'Your answer' : 'Jawaban kamu',
            text: compactSelected,
            valueColor: TawakkalColors.danger,
            isEnglish: isEnglish,
          ),
          const SizedBox(height: 8),
          _AnswerRow(
            label: isEnglish ? 'Correct answer' : 'Jawaban benar',
            text: compactCorrect,
            valueColor: TawakkalColors.primary,
            isEnglish: isEnglish,
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish ? 'AI feedback' : 'Feedback AI',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TawakkalColors.accentGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          CompactExpandableText(
            fullText: compactFeedback.original,
            compactText: compactFeedback.compact,
            isTruncated: compactFeedback.isTruncated,
            label: isEnglish ? 'AI feedback' : 'Feedback AI',
            isEnglish: isEnglish,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TawakkalColors.textSecondary,
              height: 1.34,
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
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.text,
    required this.valueColor,
    required this.isEnglish,
  });

  final String label;
  final CompactedText text;
  final Color valueColor;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TawakkalColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        CompactExpandableText(
          fullText: text.original,
          compactText: text.compact,
          isTruncated: text.isTruncated,
          label: label,
          isEnglish: isEnglish,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
