import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/debouncer.dart';

/// The standard text input.
///
/// Wraps [TextFormField] with the label/hint/error arrangement used across the
/// product, plus the password reveal toggle and character counter that would
/// otherwise be re-implemented per form.
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!,
            style: context.textStyles.labelMedium?.copyWith(
              color: widget.enabled ? colors.inkSoft : colors.inkFaint,
            ),
          ),
          const SizedBox(height: Spacing.xs + 2),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscured,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: _obscured ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          style: context.textStyles.bodyLarge,
          cursorRadius: const Radius.circular(2),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            errorText: widget.errorText,
            counterText: '',
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 17),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: _buildSuffix(context),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    if (widget.obscure) {
      return IconButton(
        icon: Icon(_obscured ? AppIcons.reveal : AppIcons.conceal, size: 17),
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
        splashRadius: 18,
      );
    }
    return widget.suffix;
  }
}

/// Search input with a debounced change callback and a clear affordance.
///
/// The debounce lives here rather than in each screen so every search field in
/// the app waits the same amount of time before firing.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hint,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 260),
    this.onSubmitted,
    this.trailing,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool autofocus;
  final Duration debounce;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final Debouncer _debouncer = Debouncer(delay: widget.debounce);
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleChanged);
  }

  void _handleChanged() {
    final bool hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    _debouncer.run(() {
      if (mounted) widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _debouncer.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      style: context.textStyles.bodyLarge,
      onSubmitted: (String value) {
        _debouncer.flush(() => widget.onChanged(value));
        widget.onSubmitted?.call(value);
      },
      decoration: InputDecoration(
        hintText: widget.hint ?? context.l10n.searchPlaceholder,
        prefixIcon: Icon(AppIcons.search, size: 17, color: colors.inkFaint),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: context.motion(Motion.fast),
              child: _hasText
                  ? IconButton(
                      key: const ValueKey<String>('clear'),
                      icon: const Icon(AppIcons.close, size: 15),
                      tooltip: context.l10n.actionClear,
                      splashRadius: 16,
                      onPressed: () {
                        _controller.clear();
                        _debouncer.flush(() => widget.onChanged(''));
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            if (widget.trailing != null) widget.trailing!,
            const SizedBox(width: Spacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Borderless inline editor used by task rows and the board.
///
/// Commits on Enter or blur, reverts on Escape — the behaviour people expect
/// from a spreadsheet, which is the mental model for inline editing.
class InlineEditableText extends StatefulWidget {
  const InlineEditableText({
    required this.value,
    required this.onCommit,
    this.style,
    this.hint,
    this.maxLines = 1,
    this.autofocus = true,
    this.onCancel,
    super.key,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final VoidCallback? onCancel;
  final TextStyle? style;
  final String? hint;
  final int maxLines;
  final bool autofocus;

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit();
    });
  }

  void _commit() {
    if (_committed) return;
    _committed = true;
    final String next = _controller.text.trim();
    if (next.isNotEmpty && next != widget.value) {
      widget.onCommit(next);
    } else {
      widget.onCancel?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _committed = true;
              widget.onCancel?.call();
              return null;
            },
          ),
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          style: widget.style ?? context.textStyles.titleSmall,
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,
          onSubmitted: (_) => _commit(),
          decoration: InputDecoration(
            hintText: widget.hint,
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: Radii.brSm,
              borderSide: BorderSide(color: context.colors.brand),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Radii.brSm,
              borderSide: BorderSide(color: context.colors.brand),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Radii.brSm,
              borderSide: BorderSide(color: context.colors.brand, width: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
