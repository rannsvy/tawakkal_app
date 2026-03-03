import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == ChatRole.user;

    final bubbleColor = isUser
        ? TawakkalColors.primary.withValues(alpha: isDark ? 0.22 : 0.18)
        : (isDark
              ? TawakkalColors.surfaceDarkAlt
              : TawakkalColors.surfaceLightAlt);
    final textColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          message.content,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}
