import 'package:flutter/material.dart';

/// Data model for onboarding slide content
class OnboardingSlide {
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlight,
    required this.verse,
    required this.verseTranslation,
  });

  final IconData icon;
  final String title;
  final String description;
  final String highlight;
  final String verse;
  final String verseTranslation;
}

/// Complete onboarding content with Quranic verses
const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    icon: Icons.menu_book_rounded,
    title: 'Begin Your Journey',
    description:
        'Discover the Quran with an AI companion that adapts to your learning pace and helps you build a lasting connection with the Holy Book.',
    highlight: 'Personalized learning paths • Smart progress tracking • Gentle, respectful feedback',
    verse: 'رَبِّ زِدْنِي عِلْمًا',
    verseTranslation: 'Quran 20:114',
  ),
  OnboardingSlide(
    icon: Icons.auto_stories_rounded,
    title: 'Read with Clarity',
    description:
        'Experience beautifully rendered Arabic text with transliteration and translation. Bookmark ayahs, add notes, and return exactly where you left off.',
    highlight: 'Crystal-clear Arabic • Multiple translations • Offline reading',
    verse: 'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
    verseTranslation: 'Quran 73:4',
  ),
  OnboardingSlide(
    icon: Icons.headphones_rounded,
    title: 'Listen with Peace',
    description:
        'Stream beautiful recitations from world-renowned Qaris. Download for offline listening and let the melody of the Quran fill your moments of reflection.',
    highlight: '20+ reciters • Background play • Offline downloads',
    verse: 'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ',
    verseTranslation: 'Quran 35:29',
  ),
];
