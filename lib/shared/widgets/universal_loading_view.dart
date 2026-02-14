import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class UniversalLoadingView extends StatefulWidget {
  const UniversalLoadingView({
    super.key,
    this.message = 'Preparing your daily path',
    this.progress,
    this.primaryIcon = Icons.bedtime_rounded,
    this.showPercentage = true,
    this.padding = const EdgeInsets.all(24),
  });

  final String message;
  final double? progress;
  final IconData primaryIcon;
  final bool showPercentage;
  final EdgeInsetsGeometry padding;

  @override
  State<UniversalLoadingView> createState() => _UniversalLoadingViewState();
}

class _UniversalLoadingViewState extends State<UniversalLoadingView>
    with SingleTickerProviderStateMixin {
  static const Duration _simulationTick = Duration(milliseconds: 100);

  late final AnimationController _controller;
  Timer? _simulationTicker;
  Duration _simulationElapsed = Duration.zero;
  double _simulatedProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _syncSimulationLifecycle(initialMount: true);
  }

  @override
  void dispose() {
    _simulationTicker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UniversalLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == widget.progress) {
      return;
    }
    _syncSimulationLifecycle(initialMount: false);
  }

  void _syncSimulationLifecycle({required bool initialMount}) {
    if (widget.progress != null) {
      _simulationTicker?.cancel();
      _simulationTicker = null;
      return;
    }

    if (initialMount || _simulationTicker == null) {
      _simulationElapsed = Duration.zero;
      if (!initialMount) {
        setState(() {
          _simulatedProgress = 0;
        });
      }
    }

    if (_simulationTicker != null) {
      return;
    }

    _simulationTicker = Timer.periodic(_simulationTick, (_) {
      if (!mounted || widget.progress != null) {
        return;
      }
      _simulationElapsed += _simulationTick;
      final nextProgress = _computeSimulatedProgress(_simulationElapsed);
      if (nextProgress <= _simulatedProgress + 0.0005) {
        return;
      }
      setState(() {
        _simulatedProgress = nextProgress;
      });
    });
  }

  double _computeSimulatedProgress(Duration elapsed) {
    final elapsedSeconds = elapsed.inMilliseconds / 1000;
    if (elapsedSeconds <= 6) {
      final normalized = (elapsedSeconds / 6).clamp(0, 1).toDouble();
      return Curves.easeOutCubic.transform(normalized) * 0.9;
    }

    final tailSeconds = elapsedSeconds - 6;
    final tailProgress = 0.08 * (1 - math.exp(-tailSeconds / 8));
    return (0.9 + tailProgress).clamp(0, 0.98).toDouble();
  }

  double _effectiveProgress() {
    final explicit = widget.progress;
    if (explicit != null) {
      return explicit.clamp(0, 1).toDouble();
    }
    return _simulatedProgress.clamp(0, 0.98).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : const Color(0xFF0A0F0E);
    final effectiveProgress = _effectiveProgress();

    return SizedBox.expand(
      key: const Key('universal-loading-root'),
      child: ColoredBox(
        color: backgroundColor,
        child: SafeArea(
          child: Padding(
            padding: widget.padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortestSide = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final iconClusterSize = (shortestSide * 0.62)
                    .clamp(180, 250)
                    .toDouble();
                final verticalGapAfterIcon = (constraints.maxHeight * 0.035)
                    .clamp(14, 26)
                    .toDouble();
                final verticalGapAfterBar = (constraints.maxHeight * 0.015)
                    .clamp(8, 14)
                    .toDouble();
                final contentWidth = constraints.maxWidth >= 560
                    ? 420.0
                    : constraints.maxWidth;
                final loadingBlockWidth = math.min(
                  contentWidth,
                  math.min(320.0, math.max(220.0, contentWidth * 0.82)),
                );
                final contentVerticalPadding = (constraints.maxHeight * 0.09)
                    .clamp(18, 46)
                    .toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: contentVerticalPadding,
                              ),
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  final pulseScale =
                                      1 +
                                      (0.04 *
                                          math.sin(
                                            _controller.value * 2 * math.pi,
                                          ));
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _IconCluster(
                                        icon: widget.primaryIcon,
                                        pulseScale: pulseScale,
                                        size: iconClusterSize,
                                      ),
                                      SizedBox(height: verticalGapAfterIcon),
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: loadingBlockWidth,
                                          child: _LoadingBarBlock(
                                            progress: effectiveProgress,
                                            showPercentage:
                                                widget.showPercentage,
                                            animationValue: _controller.value,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: verticalGapAfterBar),
                                      Text(
                                        widget.message,
                                        key: const Key(
                                          'universal-loading-message',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  TawakkalColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCluster extends StatelessWidget {
  const _IconCluster({
    required this.icon,
    required this.pulseScale,
    required this.size,
  });

  final IconData icon;
  final double pulseScale;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glowSize = size * 0.84;
    final iconSize = size * 0.5;
    final starSize = size * 0.16;
    final starTop = size * 0.19;
    final starRight = size * 0.20;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: pulseScale,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TawakkalColors.accentGold.withValues(alpha: 0.26),
                      TawakkalColors.accentGold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Icon(icon, size: iconSize, color: TawakkalColors.accentGold),
              Positioned(
                top: starTop,
                right: starRight,
                child: Icon(
                  Icons.star_rounded,
                  size: starSize,
                  color: TawakkalColors.accentGold.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBarBlock extends StatelessWidget {
  const _LoadingBarBlock({
    required this.progress,
    required this.showPercentage,
    required this.animationValue,
  });

  final double progress;
  final bool showPercentage;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0, 1).toDouble();
    final percentageLabel = !showPercentage
        ? null
        : '${(clampedProgress * 100).round()}%';

    return Column(
      key: const Key('universal-loading-bar-block'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loading',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TawakkalColors.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (percentageLabel != null)
              Text(
                percentageLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TawakkalColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            key: const Key('universal-loading-progress-track'),
            height: 4,
            color: const Color(0xFF17211F),
            child: _DeterminateFill(
              progress: clampedProgress,
              animationValue: animationValue,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeterminateFill extends StatelessWidget {
  const _DeterminateFill({
    required this.progress,
    required this.animationValue,
  });

  final double progress;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        key: const Key('universal-loading-determinate-fill'),
        widthFactor: progress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TawakkalColors.surfaceDarkAlt,
                    TawakkalColors.primary,
                    TawakkalColors.accentGold,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: TawakkalColors.primary.withValues(alpha: 0.28),
                  ),
                ],
              ),
            ),
            FractionalTranslation(
              translation: Offset((animationValue * 1.9) - 0.95, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
