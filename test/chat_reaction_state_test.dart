import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/chat/domain/entities/chat_state.dart';
import 'package:tawakkal_app/features/chat/presentation/providers/chat_providers.dart';

void main() {
  test('toggleReaction sets, switches, and clears reactions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(chatControllerProvider.notifier);

    controller.toggleReaction(messageId: 'm1', reaction: ChatReaction.up);
    expect(
      container.read(chatControllerProvider).reactionsByMessageId['m1'],
      ChatReaction.up,
    );

    controller.toggleReaction(messageId: 'm1', reaction: ChatReaction.down);
    expect(
      container.read(chatControllerProvider).reactionsByMessageId['m1'],
      ChatReaction.down,
    );

    controller.toggleReaction(messageId: 'm1', reaction: ChatReaction.down);
    expect(
      container.read(chatControllerProvider).reactionsByMessageId['m1'],
      isNull,
    );
  });
}
