import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/features/tasks/presentation/widgets/markdown_renderer.dart';

/// Formatting operations the toolbar can apply.
enum _Format { bold, italic, heading, bullet, numbered, quote, code, link }

/// A Markdown editor with a formatting toolbar and a live preview.
///
/// The toolbar operates on the current selection using the same rules a person
/// would apply by hand — wrap for inline marks, prefix each selected line for
/// block marks — and toggling a mark that is already applied removes it.
/// Keyboard users get ⌘B / ⌘I / ⌘K without touching the toolbar.
class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    required this.controller,
    this.focusNode,
    this.hint,
    this.minLines = 5,
    this.maxLines = 18,
    this.showPreviewToggle = true,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool showPreviewToggle;
  final ValueChanged<String>? onChanged;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _previewing = false;

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _apply(_Format format) {
    final TextEditingController controller = widget.controller;
    final TextSelection selection = controller.selection;
    final String text = controller.text;

    if (!selection.isValid) {
      _focusNode.requestFocus();
      return;
    }

    final String selected = selection.textInside(text);

    String replacement;
    int caretOffset;

    switch (format) {
      case _Format.bold:
        (replacement, caretOffset) = _wrap(selected, '**');
      case _Format.italic:
        (replacement, caretOffset) = _wrap(selected, '*');
      case _Format.code:
        replacement = selected.contains('\n')
            ? '```\n$selected\n```'
            : '`$selected`';
        caretOffset = selected.contains('\n') ? 4 : 1;
      case _Format.link:
        replacement = '[${selected.isEmpty ? 'label' : selected}](https://)';
        caretOffset = replacement.length - 1;
      case _Format.heading:
        (replacement, caretOffset) = _prefixLines(selected, '## ');
      case _Format.bullet:
        (replacement, caretOffset) = _prefixLines(selected, '- ');
      case _Format.numbered:
        (replacement, caretOffset) = _numberLines(selected);
      case _Format.quote:
        (replacement, caretOffset) = _prefixLines(selected, '> ');
    }

    final String next = text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset:
            selection.start +
            (selected.isEmpty ? caretOffset : replacement.length),
      ),
    );
    widget.onChanged?.call(next);
    _focusNode.requestFocus();
  }

  /// Wraps or unwraps an inline mark.
  (String, int) _wrap(String selected, String token) {
    if (selected.startsWith(token) && selected.endsWith(token)) {
      return (
        selected.substring(token.length, selected.length - token.length),
        0,
      );
    }
    return ('$token$selected$token', token.length);
  }

  (String, int) _prefixLines(String selected, String prefix) {
    final List<String> lines = selected.isEmpty
        ? <String>['']
        : selected.split('\n');
    final bool allPrefixed = lines.every((String l) => l.startsWith(prefix));
    final List<String> next = lines
        .map(
          (String line) =>
              allPrefixed ? line.substring(prefix.length) : '$prefix$line',
        )
        .toList();
    return (next.join('\n'), allPrefixed ? 0 : prefix.length);
  }

  (String, int) _numberLines(String selected) {
    final List<String> lines = selected.isEmpty
        ? <String>['']
        : selected.split('\n');
    final List<String> next = <String>[
      for (int i = 0; i < lines.length; i++) '${i + 1}. ${lines[i]}',
    ];
    return (next.join('\n'), 3);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brMd,
        border: Border.all(
          color: _focusNode.hasFocus ? colors.brand : colors.hairline,
          width: _focusNode.hasFocus ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Toolbar(
            onFormat: _apply,
            previewing: _previewing,
            showPreviewToggle: widget.showPreviewToggle,
            onTogglePreview: (bool value) =>
                setState(() => _previewing = value),
          ),
          Divider(height: 1, color: colors.hairline),
          AnimatedSize(
            duration: context.motion(Motion.base),
            curve: Motion.entrance,
            alignment: Alignment.topCenter,
            child: _previewing ? _preview(context) : _editor(context),
          ),
        ],
      ),
    );
  }

  Widget _editor(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _apply(_Format.bold),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _apply(_Format.bold),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _apply(_Format.italic),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _apply(_Format.italic),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _apply(_Format.link),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _apply(_Format.link),
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          onTap: () => setState(() {}),
          style: context.textStyles.bodyMedium?.copyWith(height: 1.6),
          decoration: InputDecoration(
            hintText: widget.hint ?? context.l10n.editorPlaceholder,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final String text = widget.controller.text.trim();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(Spacing.md),
      child: text.isEmpty
          ? Text(
              context.l10n.editorPlaceholder,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.inkFaint,
              ),
            )
          : MarkdownBody(text),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onFormat,
    required this.previewing,
    required this.onTogglePreview,
    required this.showPreviewToggle,
  });

  final ValueChanged<_Format> onFormat;
  final bool previewing;
  final ValueChanged<bool> onTogglePreview;
  final bool showPreviewToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      height: 40,
      color: colors.surfaceSunken,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs + 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _ToolbarButton(
                    icon: AppIcons.bold,
                    tooltip: l10n.editorBold,
                    onTap: previewing ? null : () => onFormat(_Format.bold),
                  ),
                  _ToolbarButton(
                    icon: AppIcons.italic,
                    tooltip: l10n.editorItalic,
                    onTap: previewing ? null : () => onFormat(_Format.italic),
                  ),
                  _ToolbarButton(
                    icon: AppIcons.heading,
                    tooltip: l10n.editorHeading,
                    onTap: previewing ? null : () => onFormat(_Format.heading),
                  ),
                  _Separator(color: colors.hairline),
                  _ToolbarButton(
                    icon: AppIcons.bulletList,
                    tooltip: l10n.editorBulletList,
                    onTap: previewing ? null : () => onFormat(_Format.bullet),
                  ),
                  _ToolbarButton(
                    icon: AppIcons.numberedList,
                    tooltip: l10n.editorNumberedList,
                    onTap: previewing ? null : () => onFormat(_Format.numbered),
                  ),
                  _ToolbarButton(
                    icon: AppIcons.quote,
                    tooltip: l10n.editorQuote,
                    onTap: previewing ? null : () => onFormat(_Format.quote),
                  ),
                  _Separator(color: colors.hairline),
                  _ToolbarButton(
                    icon: AppIcons.code,
                    tooltip: l10n.editorCode,
                    onTap: previewing ? null : () => onFormat(_Format.code),
                  ),
                  _ToolbarButton(
                    icon: AppIcons.copyLink,
                    tooltip: l10n.editorLink,
                    onTap: previewing ? null : () => onFormat(_Format.link),
                  ),
                ],
              ),
            ),
          ),
          if (showPreviewToggle)
            AppSegmentedControl<bool>(
              value: previewing,
              dense: true,
              options: <SegmentOption<bool>>[
                SegmentOption<bool>(value: false, label: l10n.editorWrite),
                SegmentOption<bool>(value: true, label: l10n.editorPreview),
              ],
              onChanged: onTogglePreview,
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool enabled = widget.onTap != null;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: context.motion(Motion.instant),
            width: 30,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered && enabled ? colors.surface : Colors.transparent,
              borderRadius: Radii.brXs,
            ),
            child: Icon(
              widget.icon,
              size: 15,
              color: enabled ? colors.inkMuted : colors.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.xs + 2),
      color: color,
    );
  }
}

/// Read-only description block with an "edit" affordance, used in the task
/// detail panel so reading is the default and editing is a deliberate step.
class DescriptionView extends StatelessWidget {
  const DescriptionView({
    required this.markdown,
    required this.onEdit,
    super.key,
  });

  final String markdown;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (markdown.trim().isEmpty) {
      return InkWell(
        onTap: onEdit,
        borderRadius: Radii.brMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            borderRadius: Radii.brMd,
            border: Border.all(color: colors.hairline),
          ),
          child: Text(
            context.l10n.editorPlaceholder,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.inkFaint,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onDoubleTap: onEdit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: MarkdownBody(
            markdown,
            baseStyle: context.textStyles.bodyMedium?.copyWith(
              height: 1.65,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline code style shared by the editor hint strip.
TextStyle monoHint(BuildContext context) =>
    AppTypography.mono.copyWith(color: context.colors.inkFaint, fontSize: 11);
