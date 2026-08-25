import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// A single sidebar destination.
///
/// The selected state is drawn as a tinted pill with a leading rail rather than
/// a full-bleed highlight — it keeps the sidebar calm when several sections
/// are visible at once, and the rail still reads at a glance when collapsed.
class SidebarNavItem extends StatefulWidget {
  const SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.collapsed = false,
    this.trailing,
    this.leadingColor,
    this.emoji,
    this.indent = 0,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool collapsed;
  final Widget? trailing;

  /// Project rows use their own colour for the leading dot.
  final Color? leadingColor;

  /// Project rows show an emoji instead of an icon.
  final String? emoji;

  final double indent;

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = widget.isSelected
        ? colors.brand
        : (_hovered ? colors.ink : colors.inkMuted);

    final Widget leading = widget.emoji != null
        ? SizedBox(
            width: 18,
            child: Text(
              widget.emoji!,
              style: const TextStyle(fontSize: 13, height: 1.2),
            ),
          )
        : (widget.leadingColor != null
              ? Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: widget.leadingColor,
                    shape: BoxShape.circle,
                  ),
                )
              : Icon(widget.icon, size: 17, color: foreground));

    final Widget content = AnimatedContainer(
      duration: context.motion(Motion.fast),
      curve: Motion.entrance,
      height: 34,
      padding: EdgeInsetsDirectional.only(
        start: Spacing.sm + widget.indent,
        end: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? colors.brandSoft
            : (_hovered ? colors.surfaceSunken : Colors.transparent),
        borderRadius: Radii.brSm,
      ),
      child: Row(
        children: <Widget>[
          leading,
          if (!widget.collapsed) ...<Widget>[
            const SizedBox(width: Spacing.md - 2),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelLarge?.copyWith(
                  color: widget.isSelected ? colors.brand : foreground,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (widget.badgeCount != null && widget.badgeCount! > 0)
              _Badge(count: widget.badgeCount!, selected: widget.isSelected),
            ?widget.trailing,
          ],
        ],
      ),
    );

    final Widget row = Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: widget.collapsed
          ? Tooltip(
              message: widget.label,
              waitDuration: const Duration(milliseconds: 300),
              child: row,
            )
          : row,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: selected ? colors.brand : colors.surfaceSunken,
        borderRadius: Radii.brPill,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: context.textStyles.labelSmall?.copyWith(
          color: selected ? Colors.white : colors.inkMuted,
          fontSize: 10,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Sidebar group heading with an optional inline action.
class SidebarSectionLabel extends StatelessWidget {
  const SidebarSectionLabel({
    required this.label,
    this.action,
    this.onAction,
    this.actionTooltip,
    super.key,
  });

  final String label;
  final IconData? action;
  final VoidCallback? onAction;
  final String? actionTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.sm,
        Spacing.lg,
        Spacing.xs,
        Spacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
                letterSpacing: 0.7,
                fontSize: 10,
              ),
            ),
          ),
          if (action != null)
            IconButton(
              icon: Icon(action, size: 13),
              onPressed: onAction,
              tooltip: actionTooltip,
              color: colors.inkFaint,
              splashRadius: 12,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            ),
        ],
      ),
    );
  }
}
