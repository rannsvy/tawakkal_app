import 'package:equatable/equatable.dart';

import 'chat_message.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isLoading = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  static const Object _errorSentinel = Object();

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    Object? error = _errorSentinel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorSentinel) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error];
}
