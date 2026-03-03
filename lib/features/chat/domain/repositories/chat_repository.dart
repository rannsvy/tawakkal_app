import '../entities/chat_context.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
    ChatContext? surahContext,
  });
}
