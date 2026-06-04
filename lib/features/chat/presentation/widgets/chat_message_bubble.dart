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
                maxWidth:
                    MediaQuery.sizeOf(context).width *
                    (isAssistant ? 0.88 : 0.8),
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
              child: isAssistant
                  ? _AssistantResponseContent(
                      content: message.content,
                      textColor: textColor,
                      isDark: isDark,
                    )
                  : SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
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

class _AssistantResponseContent extends StatelessWidget {
  const _AssistantResponseContent({
    required this.content,
    required this.textColor,
    required this.isDark,
  });

  final String content;
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final blocks = _AssistantResponseParser.parse(content);
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          switch (blocks[index]) {
            _ParagraphBlock(:final text) => SelectableText.rich(
              TextSpan(children: _buildInlineSpans(text), style: textStyle),
            ),
            _TableBlock(:final headers, :final rows) => _AssistantTableBlock(
              headers: headers,
              rows: rows,
              textColor: textColor,
              isDark: isDark,
            ),
          },
        ],
      ],
    );
  }
}

class _AssistantTableBlock extends StatelessWidget {
  const _AssistantTableBlock({
    required this.headers,
    required this.rows,
    required this.textColor,
    required this.isDark,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labelHeader = headers.isNotEmpty ? headers.first : 'Aspek';
    final detailHeader = headers.length > 1 ? headers[1] : 'Detail';
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: TawakkalColors.primary,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.38);
    final borderColor = isDark
        ? const Color(0x18FFFFFF)
        : const Color(0x14000000);
    final rowColor = isDark
        ? TawakkalColors.surfaceDark.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.58);

    return Semantics(
      label: 'Formatted response table',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$labelHeader / $detailHeader',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TawakkalColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    rows[index].isNotEmpty ? rows[index].first : '',
                    style: labelStyle,
                  ),
                  if (rows[index].length > 1 && rows[index][1].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SelectableText.rich(
                      TextSpan(
                        children: _buildInlineSpans(rows[index][1]),
                        style: detailStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

sealed class _AssistantBlock {
  const _AssistantBlock();
}

class _ParagraphBlock extends _AssistantBlock {
  const _ParagraphBlock(this.text);

  final String text;
}

class _TableBlock extends _AssistantBlock {
  const _TableBlock({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

class _AssistantResponseParser {
  static List<_AssistantBlock> parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_AssistantBlock>[];
    final paragraph = <String>[];

    void flushParagraph() {
      final text = paragraph.join('\n').trim();
      if (text.isNotEmpty) {
        blocks.add(_ParagraphBlock(text));
      }
      paragraph.clear();
    }

    var index = 0;
    while (index < lines.length) {
      final line = lines[index].trim();
      final nextLine = index + 1 < lines.length ? lines[index + 1].trim() : '';
      if (_looksLikeTableHeader(line) && _looksLikeSeparator(nextLine)) {
        flushParagraph();
        final headers = _splitTableLine(line);
        index += 2;
        final rows = <List<String>>[];
        while (index < lines.length && _looksLikeTableRow(lines[index])) {
          final cells = _splitTableLine(lines[index]);
          if (cells.any((cell) => cell.isNotEmpty)) {
            rows.add(_normalizeRow(cells, headers.length));
          }
          index++;
        }
        if (headers.isNotEmpty && rows.isNotEmpty) {
          blocks.add(_TableBlock(headers: headers, rows: rows));
        }
        continue;
      }

      if (line.isEmpty) {
        flushParagraph();
      } else {
        paragraph.add(lines[index].trimRight());
      }
      index++;
    }

    flushParagraph();
    return blocks.isEmpty ? [_ParagraphBlock(source.trim())] : blocks;
  }

  static bool _looksLikeTableHeader(String line) {
    return _looksLikeTableRow(line) && _splitTableLine(line).length >= 2;
  }

  static bool _looksLikeTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('|') && trimmed.endsWith('|');
  }

  static bool _looksLikeSeparator(String line) {
    final cells = _splitTableLine(line);
    return cells.length >= 2 &&
        cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
  }

  static List<String> _splitTableLine(String line) {
    final trimmed = line.trim();
    final withoutEdges = trimmed.substring(1, trimmed.length - 1);
    return withoutEdges
        .split('|')
        .map((cell) => _stripMarkdown(cell.trim()))
        .toList(growable: false);
  }

  static List<String> _normalizeRow(List<String> cells, int expectedLength) {
    if (expectedLength <= 2 || cells.length <= 2) {
      return cells;
    }
    return [cells.first, cells.sublist(1).join(' | ')];
  }
}

List<TextSpan> _buildInlineSpans(String source) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var cursor = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: source.substring(cursor, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
    cursor = match.end;
  }

  if (cursor < source.length) {
    spans.add(TextSpan(text: source.substring(cursor)));
  }
  return spans.isEmpty ? [TextSpan(text: _stripMarkdown(source))] : spans;
}

String _stripMarkdown(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(RegExp(r'`(.+?)`'), (match) => match.group(1) ?? '')
      .trim();
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
