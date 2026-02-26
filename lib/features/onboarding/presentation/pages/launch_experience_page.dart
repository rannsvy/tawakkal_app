import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/colors.dart';
import '../../data/onboarding_content.dart';
import '../../data/onboarding_local_store.dart';
import '../widgets/animated_logo.dart';
import '../widgets/islamic_pattern_painter.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/star_progress_indicator.dart';

class LaunchExperiencePage extends StatefulWidget {
  const LaunchExperiencePage({super.key});

  static const routeName = 'launch-experience';

  @override
  State<LaunchExperiencePage> createState() => _LaunchExperiencePageState();
}

enum _LaunchStage { checking, splash, onboarding }

class _LaunchExperiencePageState extends State<LaunchExperiencePage> {
  static const _splashDuration = Duration(milliseconds: 2800);

  final OnboardingLocalStore _onboardingStore = const OnboardingLocalStore();
  _LaunchStage _stage = _LaunchStage.checking;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasCompletedOnboarding = await _onboardingStore.isCompleted();
    if (!mounted) {
      return;
    }

    if (hasCompletedOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth');
        }
      });
      return;
    }

    setState(() => _stage = _LaunchStage.splash);
    await Future<void>.delayed(_splashDuration);

    if (!mounted) {
      return;
    }
    setState(() => _stage = _LaunchStage.onboarding);
  }

  Future<void> _finishOnboarding() async {
    await _onboardingStore.markCompleted();
    if (!mounted) {
      return;
    }
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Colors.black],
          ),
        ),
        child: CustomPaint(
          painter: IslamicPatternPainter(opacity: 0.06, color: Colors.black),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_stage) {
                _LaunchStage.checking => const _LaunchLoading(),
                _LaunchStage.splash => const _LaunchSplash(),
                _LaunchStage.onboarding => _OnboardingPager(
                  onFinished: _finishOnboarding,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchLoading extends StatelessWidget {
  const _LaunchLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('launch-loading'),
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: TawakkalColors.primary,
        ),
      ),
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('launch-splash'),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const AnimatedLogo(),
        ),
      ),
    );
  }
}

class _OnboardingPager extends StatefulWidget {
  const _OnboardingPager({required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<_OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<_OnboardingPager> {
  final PageController _pageController = PageController();

  int _pageIndex = 0;
  bool _isSubmitting = false;

  bool get _isLastPage => _pageIndex == onboardingSlides.length - 1;

  Future<void> _finishAndEnter() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    await widget.onFinished();
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _nextOrFinish() async {
    if (_isLastPage) {
      await _finishAndEnter();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('launch-onboarding'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        children: [
          // Top bar with brand mark and skip button
          _TopBar(onSkip: _isSubmitting ? null : _finishAndEnter),
          const SizedBox(height: 8),
          // Page view with cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingSlides.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) {
                return OnboardingCard(
                  slide: onboardingSlides[index],
                  isVisible: index == _pageIndex,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Star progress indicator
          StarProgressIndicator(
            currentIndex: _pageIndex,
            totalCount: onboardingSlides.length,
          ),
          const SizedBox(height: 24),
          // Primary action button
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _nextOrFinish,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: TawakkalColors.primary,
              foregroundColor: TawakkalColors.backgroundDark,
            ),
            label: Text(_isLastPage ? 'Begin Journey' : 'Next'),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TawakkalColors.backgroundDark,
                    ),
                  )
                : Icon(
                    _isLastPage
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                  ),
          ),
          const SizedBox(height: 12),
          // Secondary action
          TextButton(
            onPressed: _isSubmitting ? null : _finishAndEnter,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TawakkalColors.textSecondary,
                  letterSpacing: 0.1,
                ),
                children: const [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Log In',
                    style: TextStyle(
                      color: TawakkalColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandMark(),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: TawakkalColors.textSecondary,
          ),
          child: Text(
            'Skip',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                TawakkalColors.primary.withValues(alpha: 0.2),
                TawakkalColors.accentGold.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: TawakkalColors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(
              'assets/images/tawakkal_transparent.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tawakkal',
              style: GoogleFonts.newsreader(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TawakkalColors.textPrimaryDark,
                height: 1.1,
              ),
            ),
            Text(
              'توكل',
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TawakkalColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
