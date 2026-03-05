import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      body: AnimatedSwitcher(
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
    );
  }
}

class _LaunchLoading extends StatelessWidget {
  const _LaunchLoading();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('launch-loading'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: TawakkalColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('launch-splash'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black],
        ),
      ),
      child: CustomPaint(
        painter: IslamicPatternPainter(opacity: 0.06, color: Colors.black),
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedLogo(),
            ),
          ),
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
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _secondaryAction() async {
    await _finishAndEnter();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topColor = isDark
        ? TawakkalColors.backgroundCedar
        : const Color(0xFFF5F7F6);
    final bottomColor = isDark
        ? TawakkalColors.backgroundDark
        : const Color(0xFFEFF4F2);
    final primaryBg = isDark
        ? const Color(0xFFA5D564)
        : const Color(0xFFB7DE72);
    final primaryFg = isDark
        ? const Color(0xFF163622)
        : const Color(0xFF2C6A42);
    final secondaryBg = isDark
        ? TawakkalColors.surfaceDark.withValues(alpha: 0.75)
        : Colors.white;
    final secondaryBorder = isDark
        ? TawakkalColors.surfaceDarkAlt
        : const Color(0xFFE4E9E7);
    final secondaryFg = isDark
        ? TawakkalColors.textPrimaryDark
        : const Color(0xFF202A27);

    return DecoratedBox(
      key: const ValueKey('launch-onboarding'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            children: [
              const _CenteredBrandLogo(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              StarProgressIndicator(
                currentIndex: _pageIndex,
                totalCount: onboardingSlides.length,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _nextOrFinish,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: primaryBg,
                    foregroundColor: primaryFg,
                    disabledBackgroundColor: primaryBg.withValues(alpha: 0.65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(_isLastPage ? 'Sign in' : 'Next'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _secondaryAction,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: secondaryFg,
                    backgroundColor: secondaryBg,
                    side: BorderSide(color: secondaryBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_isLastPage ? 'Sign up' : 'Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredBrandLogo extends StatelessWidget {
  const _CenteredBrandLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentOrange = Color(0xFFF2AE8F);
    const lightThemeGreen = Color(0xFF1F5F44);

    final taColor = isDark ? accentOrange : lightThemeGreen;
    final wakColor = isDark ? Colors.white : lightThemeGreen;
    final kalColor = isDark ? accentOrange : lightThemeGreen;

    return SizedBox(
      height: 82,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/tawakkal_logo.svg',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            RichText(
              key: const ValueKey('onboarding-brand-wordmark'),
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Ta',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: taColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextSpan(
                    text: 'wak',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: wakColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextSpan(
                    text: 'kal',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kalColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
