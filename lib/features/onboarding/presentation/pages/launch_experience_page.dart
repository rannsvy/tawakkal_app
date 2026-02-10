import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/colors.dart';
import '../../data/onboarding_local_store.dart';

class LaunchExperiencePage extends StatefulWidget {
  const LaunchExperiencePage({super.key});

  static const routeName = 'launch-experience';

  @override
  State<LaunchExperiencePage> createState() => _LaunchExperiencePageState();
}

enum _LaunchStage { checking, splash, onboarding }

class _LaunchExperiencePageState extends State<LaunchExperiencePage> {
  static const _splashDuration = Duration(milliseconds: 2300);

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
            colors: [Color(0xFF0B1A16), Color(0xFF111F1C), Color(0xFF08120F)],
          ),
        ),
        child: CustomPaint(
          painter: _CrossPatternPainter(
            color: TawakkalColors.primary.withValues(alpha: 0.08),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.9, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      TawakkalColors.primary.withValues(alpha: 0.2),
                      TawakkalColors.accentGold.withValues(alpha: 0.16),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TawakkalColors.accentGold.withValues(alpha: 0.28),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  size: 82,
                  color: TawakkalColors.accentGold,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Tawakkal',
              style: GoogleFonts.newsreader(
                fontSize: 46,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF7D98A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'توكل',
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE7CCA4),
              ),
            ),
            const SizedBox(height: 44),
            Text(
              'Loading your journey...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TawakkalColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 132,
                child: LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 5,
                  backgroundColor: const Color(0x22FFFFFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TawakkalColors.primary,
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

  bool get _isLastPage => _pageIndex == _slides.length - 1;

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
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
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
          Row(
            children: [
              const _BrandMark(),
              const Spacer(),
              TextButton(
                onPressed: _isSubmitting ? null : _finishAndEnter,
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              itemBuilder: (context, index) {
                return _OnboardingSlideCard(slide: _slides[index]);
              },
            ),
          ),
          const SizedBox(height: 18),
          _DotsIndicator(currentIndex: _pageIndex, itemCount: _slides.length),
          const SizedBox(height: 18),
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
          TextButton(
            onPressed: _isSubmitting ? null : _finishAndEnter,
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TawakkalColors.textSecondary,
                  fontWeight: FontWeight.w500,
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TawakkalColors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: TawakkalColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            Icons.mosque_rounded,
            color: TawakkalColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Tawakkal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: TawakkalColors.textPrimaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlideCard extends StatelessWidget {
  const _OnboardingSlideCard({required this.slide});

  final _LandingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: TawakkalColors.surfaceDark,
          border: Border.all(color: const Color(0x16FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: TawakkalColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: TawakkalColors.accentGold.withValues(alpha: 0.16),
                  border: Border.all(
                    color: TawakkalColors.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(slide.icon, color: TawakkalColors.accentGold),
              ),
              const SizedBox(height: 18),
              Text(
                slide.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TawakkalColors.textPrimaryDark,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TawakkalColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TawakkalColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TawakkalColors.primary.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  slide.highlight,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TawakkalColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
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

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.currentIndex, required this.itemCount});

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? TawakkalColors.primary
                : TawakkalColors.textSecondary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CrossPatternPainter extends CustomPainter {
  _CrossPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const gap = 40.0;
    for (double y = 14; y <= size.height; y += gap) {
      for (double x = 14; x <= size.width; x += gap) {
        canvas.drawLine(Offset(x - 3.5, y), Offset(x + 3.5, y), paint);
        canvas.drawLine(Offset(x, y - 3.5), Offset(x, y + 3.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrossPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LandingSlide {
  const _LandingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlight,
  });

  final IconData icon;
  final String title;
  final String description;
  final String highlight;
}

const _slides = <_LandingSlide>[
  _LandingSlide(
    icon: Icons.psychology_alt_rounded,
    title: 'Master Your Faith',
    description:
        'Learn the Quran with AI guidance that adapts to your pace and keeps every lesson respectful, clear, and practical.',
    highlight:
        'Adaptive quizzes, gentle feedback, and daily streak support in one focused learning path.',
  ),
  _LandingSlide(
    icon: Icons.menu_book_rounded,
    title: 'Read with Calm Focus',
    description:
        'Comfortable Arabic typography, transliteration, and translation help you stay present in every ayah.',
    highlight:
        'Bookmark ayah, add personal notes, and continue exactly where you paused.',
  ),
  _LandingSlide(
    icon: Icons.graphic_eq_rounded,
    title: 'Listen to Trusted Reciters',
    description:
        'Stream and download beautiful recitations for daily reflection with a modern player experience.',
    highlight:
        'Background playback, offline downloads, and quick reciter switching built for consistency.',
  ),
];
