/// Data model for onboarding slide content.
class OnboardingSlide {
  const OnboardingSlide({
    required this.illustrationAsset,
    required this.title,
    required this.description,
  });

  final String illustrationAsset;
  final String title;
  final String description;
}

/// Onboarding content for the redesigned two-step flow.
const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    illustrationAsset: 'assets/icons/studying_ob_page_1.svg',
    title: 'Learn, Read, And Listen',
    description:
        'Build your daily Quran habit by learning key lessons, reading verses, and listening to beautiful recitations in one place.',
  ),
  OnboardingSlide(
    illustrationAsset: 'assets/icons/brain_ob_page_2.svg',
    title: 'Increase your general knowledge about the Quran',
    description:
        'Expand your understanding with AI guided insights, practical explanations, and bite-sized learning designed for steady progress.',
  ),
  OnboardingSlide(
    illustrationAsset: 'assets/icons/ob_page_3.svg',
    title: 'Share the "Torch" of knowledge with Others',
    description:
        'Pass on beneficial knowledge by sharing verses, reflections, and reminders with family and friends.',
  ),
];
