import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import 'chat_bottom_sheet.dart';

class ChatFloatingDock extends StatelessWidget {
  const ChatFloatingDock({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Ask Tawakkal AI',
      child: Semantics(
        button: true,
        label: 'Open Tawakkal AI chat',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _openChat(context),
            child: Ink(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary,
                border: Border.all(
                  color: isDark ? TawakkalColors.backgroundDark : Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TawakkalColors.primary.withValues(
                      alpha: isDark ? 0.28 : 0.23,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: TawakkalColors.backgroundDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatBottomSheet(),
    );
  }
}
