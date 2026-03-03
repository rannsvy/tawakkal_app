import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_state.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.selectedReaction,
    this.onCopy,
    this.onThumbsUp,
    this.onThumbsDown,
  });

  final ChatMessage message;
  final ChatReaction? selectedReaction;
  final VoidCallback? onCopy;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == ChatRole.user;
    final isAssistant = message.role == ChatRole.assistant;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.8,
              ),
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
            if (isAssistant)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: _AssistantActions(
                  selectedReaction: selectedReaction,
                  onCopy: onCopy,
                  onThumbsUp: onThumbsUp,
                  onThumbsDown: onThumbsDown,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssistantActions extends StatelessWidget {
  const _AssistantActions({
    required this.selectedReaction,
    required this.onCopy,
    required this.onThumbsUp,
    required this.onThumbsDown,
  });

  final ChatReaction? selectedReaction;
  final VoidCallback? onCopy;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.56);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIconButton(
          tooltip: 'Copy response',
          iconAssetPath: 'assets/icons/copy.svg',
          iconColor: inactiveColor,
          onTap: onCopy,
        ),
        _ActionIconButton(
          tooltip: 'Helpful response',
          iconAssetPath: 'assets/icons/thumbs_up.svg',
          iconColor: selectedReaction == ChatReaction.up
              ? TawakkalColors.primary
              : inactiveColor,
          onTap: onThumbsUp,
        ),
        _ActionIconButton(
          tooltip: 'Not helpful response',
          iconAssetPath: 'assets/icons/thumbs_down.svg',
          iconColor: selectedReaction == ChatReaction.down
              ? TawakkalColors.primary
              : inactiveColor,
          onTap: onThumbsDown,
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.iconAssetPath,
    required this.iconColor,
    required this.onTap,
  });

  final String tooltip;
  final String iconAssetPath;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      splashRadius: 20,
      padding: const EdgeInsets.all(10),
      icon: SvgPicture.asset(
        iconAssetPath,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: iconColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
