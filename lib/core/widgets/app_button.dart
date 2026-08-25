import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';

enum AppButtonVariant {
  /// Filled brand blue. One per screen region — the thing you want done.
  primary,

  /// Bordered neutral surface. The common case.
  secondary,

  /// No border, no fill until hover.
  ghost,

  /// Filled danger. Destructive confirmations only.
  danger,

  /// Text-weight brand link.
  link,
}

enum AppButtonSize { small, medium, large }

/// The only button in the app.
///
/// Every state a button can be in — hover, pressed, focused, disabled, loading
/// — is handled here once, which is what stops the twelfth screen from
/// inventing a thirteenth button style.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.tooltip,
    this.semanticLabel,
    super.key,
  });

  /// Shorthand for the most common call site.
  const AppButton.primary({
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.tooltip,
    this.semanticLabel,
    super.key,
  }) : variant = AppButtonVariant.primary;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Swaps the label for a spinner and blocks input, without changing width —
  /// a button that resizes mid-submit is a layout jump.
  final bool isLoading;

  final bool isFullWidth;
  final String? tooltip;
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (
      double height,
      EdgeInsets padding,
      TextStyle textStyle,
      double iconSize,
    ) = _metrics(
      context,
    );

    final _ButtonPaint paint = _paint(context);

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null && !widget.isLoading) ...<Widget>[
          Icon(widget.icon, size: iconSize, color: paint.foreground),
          const SizedBox(width: Spacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: textStyle.copyWith(color: paint.foreground),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...<Widget>[
          const SizedBox(width: Spacing.sm),
          Icon(widget.trailingIcon, size: iconSize, color: paint.foreground),
        ],
      ],
    );

    // The spinner sits on top of an invisible label so the button keeps its
    // width while submitting.
    if (widget.isLoading) {
      content = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(opacity: 0, child: content),
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(paint.foreground),
            ),
          ),
        ],
      );
    }

    Widget button = AnimatedContainer(
      duration: context.motion(Motion.fast),
      curve: Motion.entrance,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: paint.background,
        borderRadius: Radii.brMd,
        border: paint.border == null
            ? null
            : Border.all(color: paint.border!, width: 1),
        boxShadow: paint.shadow,
      ),
      child: content,
    );

    if (_focused) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: Radii.brLg,
          border: Border.all(
            color: colors.brand.withValues(alpha: 0.9),
            width: 2,
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(2), child: button),
      );
    }

    Widget result = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: _enabled ? widget.onPressed : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _pressed && !context.reducedMotion ? 0.975 : 1,
            duration: context.motion(Motion.instant),
            child: button,
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      result = SizedBox(width: double.infinity, child: result);
    }
    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }

  (double, EdgeInsets, TextStyle, double) _metrics(BuildContext context) {
    final TextTheme text = context.textStyles;
    switch (widget.size) {
      case AppButtonSize.small:
        return (
          32,
          const EdgeInsets.symmetric(horizontal: Spacing.md),
          text.labelMedium!,
          14,
        );
      case AppButtonSize.medium:
        return (
          40,
          const EdgeInsets.symmetric(horizontal: Spacing.lg),
          text.labelLarge!,
          16,
        );
      case AppButtonSize.large:
        return (
          48,
          const EdgeInsets.symmetric(horizontal: Spacing.xxl),
          text.labelLarge!.copyWith(fontSize: 15),
          18,
        );
    }
  }

  _ButtonPaint _paint(BuildContext context) {
    final colors = context.colors;
    final bool disabled = !_enabled;
    final bool hot = _hovered || _pressed;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonPaint(
          background: disabled
              ? colors.brand.withValues(alpha: 0.4)
              : (_pressed
                    ? colors.brandStrong
                    : (hot
                          ? Color.lerp(colors.brand, colors.brandStrong, 0.35)!
                          : colors.brand)),
          foreground: Colors.white.withValues(alpha: disabled ? 0.75 : 1),
          shadow: disabled || !hot
              ? null
              : Shadows.glow(colors.brand, strength: 0.28),
        );
      case AppButtonVariant.secondary:
        return _ButtonPaint(
          background: hot && !disabled ? colors.surfaceSunken : colors.surface,
          foreground: disabled ? colors.inkFaint : colors.ink,
          border: hot && !disabled ? colors.hairlineStrong : colors.hairline,
          shadow: disabled ? null : Shadows.xs(colors.isDark),
        );
      case AppButtonVariant.ghost:
        return _ButtonPaint(
          background: hot && !disabled
              ? colors.surfaceSunken
              : Colors.transparent,
          foreground: disabled ? colors.inkFaint : colors.inkSoft,
        );
      case AppButtonVariant.danger:
        return _ButtonPaint(
          background: disabled
              ? colors.danger.withValues(alpha: 0.4)
              : (hot
                    ? Color.lerp(colors.danger, Colors.black, 0.12)!
                    : colors.danger),
          foreground: Colors.white,
        );
      case AppButtonVariant.link:
        return _ButtonPaint(
          background: Colors.transparent,
          foreground: disabled
              ? colors.inkFaint
              : (hot ? colors.brandStrong : colors.brand),
        );
    }
  }
}

class _ButtonPaint {
  const _ButtonPaint({
    required this.background,
    required this.foreground,
    this.border,
    this.shadow,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final List<BoxShadow>? shadow;
}

/// A square, icon-only button. Always carries a tooltip so its meaning is
/// available to both pointer users and screen readers.
///
/// The visual box and the *tap* box are separate. A 34px control reads well
/// under a mouse but is below the 44px minimum a finger needs, so on
/// touch-first layouts the button keeps its size on screen and grows an
/// invisible hit area around it. Enlarging the visual instead would make every
/// toolbar in the product bulkier on exactly the screens with the least room.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 34,
    this.iconSize = 17,
    this.color,
    this.background,
    this.isActive = false,
    this.badgeCount,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;
  final bool isActive;

  /// Draws a count bubble — used by the notifications button.
  final int? badgeCount;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  /// The smallest comfortable finger target, per the Material and HIG guidance
  /// that agree on roughly this number.
  static const double _minTouchTarget = 44;

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool enabled = widget.onPressed != null;
    final Color foreground = widget.isActive
        ? colors.brand
        : (widget.color ?? (enabled ? colors.inkMuted : colors.inkFaint));
    final Color background = widget.isActive
        ? colors.brandSoft
        : (_hovered && enabled
              ? colors.surfaceSunken
              : (widget.background ?? Colors.transparent));

    // Only where a finger is the likely input. On desktop the pointer is
    // precise and the extra padding would just push toolbars apart.
    final double target = context.breakpoint.isTouchFirst
        ? (widget.size < _minTouchTarget ? _minTouchTarget : widget.size)
        : widget.size;

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: PressableScale(
            onTap: widget.onPressed,
            child: SizedBox(
              width: target,
              height: target,
              child: Center(
                child: AnimatedContainer(
                  duration: context.motion(Motion.fast),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: Radii.brSm,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Icon(
                        widget.icon,
                        size: widget.iconSize,
                        color: foreground,
                      ),
                      if (widget.badgeCount != null && widget.badgeCount! > 0)
                        Positioned(
                          top: 3,
                          right: 2,
                          child: _CountBubble(count: widget.badgeCount!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 15),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colors.danger,
        borderRadius: Radii.brPill,
        border: Border.all(color: colors.surface, width: 1.5),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: context.textStyles.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
