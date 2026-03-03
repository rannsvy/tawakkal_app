import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/chat_state.dart';
import '../providers/chat_providers.dart';
import 'chat_message_bubble.dart';
import 'chat_suggestion_chips.dart';

class ChatBottomSheet extends ConsumerStatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  ConsumerState<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends ConsumerState<ChatBottomSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage([String? seeded]) {
    final text = (seeded ?? _inputController.text).trim();
    if (text.isEmpty) {
      return;
    }

    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _inputController.clear();
    _focusNode.requestFocus();
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        return;
      }
      _scrollController.animateTo(
        maxExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    ref.listen<ChatState>(chatControllerProvider, (previous, next) {
      final previousCount = previous?.messages.length ?? 0;
      final previousLoading = previous?.isLoading ?? false;
      if (previousCount != next.messages.length ||
          previousLoading != next.isLoading) {
        _scrollToLatest();
      }
    });

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.86,
        decoration: BoxDecoration(
          color: isDark
              ? TawakkalColors.surfaceDark
              : TawakkalColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? const Color(0x1EFFFFFF) : const Color(0x14000000),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x30FFFFFF)
                    : const Color(0x22000000),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _Header(chatState: chatState),
            const Divider(height: 1),
            Expanded(
              child: chatState.messages.isEmpty
                  ? _EmptyState(onSuggestionTap: _sendMessage)
                  : _MessageList(
                      chatState: chatState,
                      scrollController: _scrollController,
                    ),
            ),
            if (chatState.error != null && chatState.error!.isNotEmpty)
              _ErrorBanner(message: chatState.error!),
            _InputBar(
              controller: _inputController,
              focusNode: _focusNode,
              isLoading: chatState.isLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.chatState});

  final ChatState chatState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: TawakkalColors.primary,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: TawakkalColors.backgroundDark,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tawakkal AI',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: chatState.messages.isEmpty
                ? null
                : () => ref
                      .read(chatControllerProvider.notifier)
                      .clearConversation(),
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: TawakkalColors.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 14),
            Text(
              'What can I help with?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? TawakkalColors.textPrimaryDark
                    : TawakkalColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about surah meaning, tafsir, and practical reflections.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TawakkalColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ChatSuggestionChips(onSelected: onSuggestionTap),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.chatState, required this.scrollController});

  final ChatState chatState;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < chatState.messages.length) {
          return ChatMessageBubble(message: chatState.messages[index]);
        }
        return const _TypingIndicator();
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? TawakkalColors.surfaceDarkAlt
              : TawakkalColors.surfaceLightAlt,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark
                    ? TawakkalColors.textSecondary
                    : TawakkalColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tawakkal AI is thinking...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TawakkalColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: TawakkalColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: TawakkalColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: TawakkalColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () =>
                ref.read(chatControllerProvider.notifier).clearError(),
            icon: const Icon(Icons.close_rounded, size: 16),
            color: TawakkalColors.danger,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final void Function([String?]) onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 14),
      decoration: BoxDecoration(
        color: isDark
            ? TawakkalColors.surfaceDark
            : TawakkalColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x16FFFFFF) : const Color(0x12000000),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask anything about tafsir...',
                filled: true,
                fillColor: isDark
                    ? TawakkalColors.surfaceDarkAlt
                    : TawakkalColors.surfaceLightAlt,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: TawakkalColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton.filled(
              tooltip: 'Send',
              onPressed: isLoading ? null : () => onSend(),
              style: IconButton.styleFrom(
                backgroundColor: TawakkalColors.primary,
                disabledBackgroundColor: TawakkalColors.primary.withValues(
                  alpha: 0.45,
                ),
                foregroundColor: TawakkalColors.backgroundDark,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
