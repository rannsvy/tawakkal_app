import 'package:equatable/equatable.dart';

import 'chat_message.dart';

enum ChatReaction { up, down }

class ChatState extends Equatable {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isLoading = false,
    this.error,
    this.reactionsByMessageId = const <String, ChatReaction>{},
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final Map<String, ChatReaction> reactionsByMessageId;

  static const Object _errorSentinel = Object();

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    Object? error = _errorSentinel,
    Map<String, ChatReaction>? reactionsByMessageId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorSentinel) ? this.error : error as String?,
      reactionsByMessageId: reactionsByMessageId ?? this.reactionsByMessageId,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, reactionsByMessageId];
}
