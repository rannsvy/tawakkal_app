import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/chat_repository_impl.dart';
import '../../domain/entities/chat_context.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_state.dart';
import '../../domain/repositories/chat_repository.dart';

final activeSurahContextProvider = StateProvider<ChatContext?>((ref) => null);

final chatHttpClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final httpClient = ref.watch(chatHttpClientProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ChatRepositoryImpl(
    httpClient: httpClient,
    supabaseClient: supabaseClient,
  );
});

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  static const int _maxRetainedMessages = 50;
  int _sequence = 0;

  @override
  ChatState build() {
    return const ChatState();
  }

  Future<void> sendMessage(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = _createMessage(role: ChatRole.user, content: input);
    final messagesAfterUser = _appendAndTrim(state.messages, userMessage);
    state = state.copyWith(
      messages: messagesAfterUser,
      isLoading: true,
      error: null,
    );

    final repository = ref.read(chatRepositoryProvider);
    final surahContext = ref.read(activeSurahContextProvider);
    final requestHistory = messagesAfterUser.length <= 10
        ? messagesAfterUser
        : messagesAfterUser.sublist(messagesAfterUser.length - 10);

    try {
      final reply = await repository.sendMessage(
        message: input,
        conversationHistory: requestHistory,
        surahContext: surahContext,
      );
      final assistantMessage = _createMessage(
        role: ChatRole.assistant,
        content: reply,
      );
      state = state.copyWith(
        messages: _appendAndTrim(messagesAfterUser, assistantMessage),
        isLoading: false,
        error: null,
      );
    } catch (error, stackTrace) {
      debugPrint('[ChatController] sendMessage failed:\n$error\n$stackTrace');
      state = state.copyWith(isLoading: false, error: _mapError(error));
    }
  }

  void clearError() {
    if (state.error == null) {
      return;
    }
    state = state.copyWith(error: null);
  }

  void clearConversation() {
    state = const ChatState();
  }

  void toggleReaction({
    required String messageId,
    required ChatReaction reaction,
  }) {
    final next = <String, ChatReaction>{...state.reactionsByMessageId};
    final current = next[messageId];

    if (current == reaction) {
      next.remove(messageId);
    } else {
      next[messageId] = reaction;
    }

    state = state.copyWith(reactionsByMessageId: next);
  }

  ChatMessage _createMessage({
    required ChatRole role,
    required String content,
  }) {
    _sequence += 1;
    return ChatMessage(
      id: '${role.name}_${DateTime.now().microsecondsSinceEpoch}_$_sequence',
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  List<ChatMessage> _appendAndTrim(
    List<ChatMessage> current,
    ChatMessage next,
  ) {
    final nextMessages = <ChatMessage>[...current, next];
    if (nextMessages.length <= _maxRetainedMessages) {
      return nextMessages;
    }
    return nextMessages.sublist(nextMessages.length - _maxRetainedMessages);
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Terjadi kendala saat menghubungi Tawakkal AI.';
  }
}
