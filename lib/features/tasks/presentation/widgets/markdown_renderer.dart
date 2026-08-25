import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// Renders the Markdown subset Kairo stores for task descriptions and comments.
///
/// Why Markdown and a hand-written renderer rather than a document model or an
/// editor package: the text has to round-trip through a backend, be searchable
/// as plain text, stay diff-able, and survive being read by something that is
/// not this app. Markdown gives all four. The subset is deliberately small —
/// headings, emphasis, code, quotes, lists, checkboxes, links and mentions —
/// because that is what task descriptions actually contain.
class MarkdownBody extends StatelessWidget {
  const MarkdownBody(
    this.source, {
    this.onMentionTap,
    this.onLinkTap,
    this.baseStyle,
    this.compact = false,
    super.key,
  });

  final String source;
  final ValueChanged<String>? onMentionTap;
  final ValueChanged<String>? onLinkTap;
  final TextStyle? baseStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<_Block> blocks = _parseBlocks(source);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gapFor(blocks[i])),
            child: _buildBlock(context, blocks[i]),
          ),
      ],
    );
  }

  double _gapFor(_Block block) => switch (block.type) {
    _BlockType.heading => compact ? Spacing.md : Spacing.lg,
    _BlockType.listItem || _BlockType.checkItem => Spacing.xs,
    _ => compact ? Spacing.sm : Spacing.md,
  };

  Widget _buildBlock(BuildContext context, _Block block) {
    final colors = context.colors;
    final TextStyle base =
        baseStyle ??
        context.textStyles.bodyMedium!.copyWith(
          color: colors.ink,
          height: 1.62,
        );

    switch (block.type) {
      case _BlockType.heading:
        final TextStyle style = switch (block.level) {
          1 => context.textStyles.headlineSmall!,
          2 => context.textStyles.titleLarge!,
          _ => context.textStyles.titleMedium!,
        };
        return Text.rich(_inlineSpan(context, block.text, style), style: style);

      case _BlockType.paragraph:
        return Text.rich(_inlineSpan(context, block.text, base), style: base);

      case _BlockType.listItem:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 4.0 + block.indent * 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 8, right: 10),
                decoration: BoxDecoration(
                  color: colors.inkFaint,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text.rich(
                  _inlineSpan(context, block.text, base),
                  style: base,
                ),
              ),
            ],
          ),
        );

      case _BlockType.orderedItem:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 4.0 + block.indent * 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Text(
                  '${block.level}.',
                  style: base.copyWith(
                    color: colors.inkFaint,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  _inlineSpan(context, block.text, base),
                  style: base,
                ),
              ),
            ],
          ),
        );

      case _BlockType.checkItem:
        final bool checked = block.level == 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 8),
              child: Icon(
                checked
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 16,
                color: checked ? colors.success : colors.inkFaint,
              ),
            ),
            Expanded(
              child: Text.rich(
                _inlineSpan(
                  context,
                  block.text,
                  checked
                      ? base.copyWith(
                          color: colors.inkFaint,
                          decoration: TextDecoration.lineThrough,
                        )
                      : base,
                ),
                style: base,
              ),
            ),
          ],
        );

      case _BlockType.quote:
        return Container(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: Radii.brSm,
            border: BorderDirectional(
              start: BorderSide(color: colors.brandBorder, width: 3),
            ),
          ),
          child: Text.rich(
            _inlineSpan(
              context,
              block.text,
              base.copyWith(color: colors.inkSoft, fontStyle: FontStyle.italic),
            ),
          ),
        );

      case _BlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.isDark
                ? colors.surfaceSunken
                : const Color(0xFF0E1728),
            borderRadius: Radii.brMd,
            border: Border.all(color: colors.hairline),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.text,
              style: AppTypography.mono.copyWith(
                color: colors.isDark ? colors.inkSoft : const Color(0xFFDCE6F8),
              ),
            ),
          ),
        );

      case _BlockType.divider:
        return Divider(color: colors.hairline, height: 1);
    }
  }

  /// Inline formatting: `**bold**`, `*italic*`, `` `code` ``, `[text](url)`
  /// and `@Mentions`.
  InlineSpan _inlineSpan(BuildContext context, String text, TextStyle base) {
    final colors = context.colors;
    final List<InlineSpan> spans = <InlineSpan>[];
    final RegExp pattern = RegExp(
      r'(\*\*.+?\*\*)|(\*[^*]+?\*)|(`[^`]+?`)|(\[[^\]]+?\]\([^)]+?\))|(@[A-Za-zÀ-ÿ]+(?:\s[A-Za-zÀ-ÿ]+)?)',
    );

    int cursor = 0;
    for (final RegExpMatch match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final String token = match.group(0)!;

      if (token.startsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (token.startsWith('`')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: AppTypography.mono.copyWith(
              backgroundColor: colors.surfaceSunken,
              color: colors.brand,
              fontSize: base.fontSize! * 0.92,
            ),
          ),
        );
      } else if (token.startsWith('[')) {
        final int split = token.indexOf('](');
        final String label = token.substring(1, split);
        final String url = token.substring(split + 2, token.length - 1);
        spans.add(
          TextSpan(
            text: label,
            style: base.copyWith(
              color: colors.brand,
              decoration: TextDecoration.underline,
              decorationColor: colors.brand.withValues(alpha: 0.4),
            ),
            recognizer: onLinkTap == null
                ? null
                : (TapGestureRecognizer()..onTap = () => onLinkTap!(url)),
          ),
        );
      } else if (token.startsWith('@')) {
        spans.add(
          TextSpan(
            text: token,
            style: base.copyWith(
              color: colors.brand,
              fontWeight: FontWeight.w600,
              backgroundColor: colors.brandSoft,
            ),
            recognizer: onMentionTap == null
                ? null
                : (TapGestureRecognizer()
                    ..onTap = () => onMentionTap!(token.substring(1))),
          ),
        );
      } else if (token.startsWith('*')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(children: spans, style: base);
  }
}

enum _BlockType {
  paragraph,
  heading,
  listItem,
  orderedItem,
  checkItem,
  quote,
  code,
  divider,
}

class _Block {
  const _Block(this.type, this.text, {this.level = 0, this.indent = 0});

  final _BlockType type;
  final String text;

  /// Heading level, ordered-list number, or 1/0 for a checked/unchecked item.
  final int level;

  final int indent;
}

List<_Block> _parseBlocks(String source) {
  final List<String> lines = source.split('\n');
  final List<_Block> blocks = <_Block>[];
  final StringBuffer paragraph = StringBuffer();
  bool inCode = false;
  final StringBuffer code = StringBuffer();
  int orderedCounter = 0;

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(_Block(_BlockType.paragraph, paragraph.toString().trim()));
    paragraph.clear();
  }

  for (final String rawLine in lines) {
    final String line = rawLine.trimRight();

    if (line.trimLeft().startsWith('```')) {
      if (inCode) {
        blocks.add(_Block(_BlockType.code, code.toString().trimRight()));
        code.clear();
        inCode = false;
      } else {
        flushParagraph();
        inCode = true;
      }
      continue;
    }
    if (inCode) {
      code.writeln(rawLine);
      continue;
    }

    if (line.trim().isEmpty) {
      flushParagraph();
      orderedCounter = 0;
      continue;
    }

    if (RegExp(r'^\s*(-{3,}|\*{3,})\s*$').hasMatch(line)) {
      flushParagraph();
      blocks.add(const _Block(_BlockType.divider, ''));
      continue;
    }

    final RegExpMatch? heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(
        _Block(
          _BlockType.heading,
          heading.group(2)!,
          level: heading.group(1)!.length,
        ),
      );
      continue;
    }

    final RegExpMatch? check = RegExp(
      r'^(\s*)[-*]\s+\[([ xX])\]\s+(.*)$',
    ).firstMatch(line);
    if (check != null) {
      flushParagraph();
      blocks.add(
        _Block(
          _BlockType.checkItem,
          check.group(3)!,
          level: check.group(2)!.trim().isEmpty ? 0 : 1,
          indent: check.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    final RegExpMatch? bullet = RegExp(r'^(\s*)[-*]\s+(.*)$').firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(
        _Block(
          _BlockType.listItem,
          bullet.group(2)!,
          indent: bullet.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    final RegExpMatch? ordered = RegExp(
      r'^(\s*)(\d+)[.)]\s+(.*)$',
    ).firstMatch(line);
    if (ordered != null) {
      flushParagraph();
      orderedCounter++;
      blocks.add(
        _Block(
          _BlockType.orderedItem,
          ordered.group(3)!,
          level: orderedCounter,
          indent: ordered.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    final RegExpMatch? quote = RegExp(r'^>\s?(.*)$').firstMatch(line);
    if (quote != null) {
      flushParagraph();
      blocks.add(_Block(_BlockType.quote, quote.group(1)!));
      continue;
    }

    if (paragraph.isNotEmpty) paragraph.write(' ');
    paragraph.write(line.trim());
  }

  if (inCode && code.isNotEmpty) {
    blocks.add(_Block(_BlockType.code, code.toString().trimRight()));
  }
  flushParagraph();
  return blocks;
}

/// Strips formatting for previews, search snippets and screen-reader labels.
String markdownToPlainText(String source) {
  return source
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+\[[ xX]\]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^>\s?', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp('`([^`]+)`'), r'$1')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'),
        (Match m) => m.group(1)!,
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
