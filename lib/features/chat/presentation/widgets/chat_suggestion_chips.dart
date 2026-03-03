import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class ChatSuggestionChips extends StatelessWidget {
  const ChatSuggestionChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const List<String> _suggestions = <String>[
    'Apa tema utama surah ini?',
    'Jelaskan tafsir ayat pertama.',
    'How can I apply this ayah today?',
    'Ringkas pelajaran dari surah ini.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((suggestion) {
        return ActionChip(
          label: Text(
            suggestion,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
            ),
          ),
          backgroundColor: isDark
              ? TawakkalColors.surfaceDarkAlt
              : TawakkalColors.surfaceLightAlt,
          side: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x1A000000),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: () => onSelected(suggestion),
        );
      }).toList(),
    );
  }
}
