import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toApiJson() => <String, dynamic>{
    'role': role == ChatRole.user ? 'user' : 'assistant',
    'content': content,
  };

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
