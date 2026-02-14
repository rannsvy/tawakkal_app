import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class CompactExpandableText extends StatelessWidget {
  const CompactExpandableText({
    super.key,
    required this.fullText,
    required this.compactText,
    required this.isTruncated,
    required this.label,
    required this.isEnglish,
    this.style,
    this.linkColor,
  });

  final String fullText;
  final String compactText;
  final bool isTruncated;
  final String label;
  final bool isEnglish;
  final TextStyle? style;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final textToShow = compactText.trim().isEmpty
        ? fullText.trim()
        : compactText.trim();
    final hasText = textToShow.isNotEmpty;
    if (!hasText) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(textToShow, style: style),
        if (isTruncated) ...[
          const SizedBox(height: 2),
          TextButton(
            onPressed: () => _showFullTextSheet(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: linkColor ?? TawakkalColors.primary,
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              isEnglish ? 'Read more' : 'Lihat lengkap',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showFullTextSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ExpandedTextSheet(
        label: label,
        text: fullText,
        isEnglish: isEnglish,
      ),
    );
  }
}

class _ExpandedTextSheet extends StatelessWidget {
  const _ExpandedTextSheet({
    required this.label,
    required this.text,
    required this.isEnglish,
  });

  final String label;
  final String text;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162421) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x12000000),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x22000000),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnglish ? 'Full text view' : 'Tampilan teks lengkap',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TawakkalColors.textSecondary,
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? TawakkalColors.textPrimaryDark
                          : TawakkalColors.textPrimaryLight,
                      height: 1.4,
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
