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
    title: 'Team Up For Success',
    description:
        'Get ready to unleash your potential and witness the power of teamwork as we embark on this extraordinary project.',
  ),
  OnboardingSlide(
    illustrationAsset: 'assets/icons/brain_ob_page_2.svg',
    title: 'User-Friendly at its Core',
    description:
        'Discover the essence of user-friendliness as our interface empowers you with intuitive controls and effortless interactions.',
  ),
    OnboardingSlide(
    illustrationAsset: 'assets/icons/ob_page_3.svg',
    title: 'User-Friendly at its Core',
    description:
        'Discover the essence of user-friendliness as our interface empowers you with intuitive controls and effortless interactions.',
  ),
];
