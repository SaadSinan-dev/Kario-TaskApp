import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';

class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
}

/// Sliding segmented control.
///
/// The selected pill animates between positions rather than snapping, which is
/// what makes switching a view feel like moving rather than reloading.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
    this.showLabels = true,
    this.dense = false,
    this.expand = false,
    super.key,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool showLabels;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final int selectedIndex = options.indexWhere(
      (SegmentOption<T> option) => option.value == value,
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: Radii.brMd,
        border: Border.all(color: colors.hairline),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool measurable =
              expand && constraints.maxWidth.isFinite && options.isNotEmpty;
          final double? segmentWidth = measurable
              ? (constraints.maxWidth - 6) / options.length
              : null;

          // Expanding: the segments share the width, and the selection is an
          // animated pill sliding behind them.
          //
          // Gated on `measurable`, not on `expand` alone. A caller can ask to
          // expand while sitting somewhere with no width to divide — a bare
          // child of a `Row` receives unbounded main-axis constraints — and
          // flex children under unbounded constraints are a hard layout error.
          // Falling through to the scrolling layout keeps the control working
          // instead of throwing.
          if (measurable) {
            return Stack(
              children: <Widget>[
                if (segmentWidth != null && selectedIndex >= 0)
                  AnimatedPositioned(
                    duration: context.motion(Motion.base),
                    curve: Motion.emphasized,
                    left: segmentWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: Radii.brSm,
                        boxShadow: Shadows.xs(colors.isDark),
                      ),
                    ),
                  ),
                Row(
                  children: <Widget>[
                    for (final SegmentOption<T> option in options)
                      Expanded(
                        child: _Segment<T>(
                          option: option,
                          selected: option.value == value,
                          floating: segmentWidth != null,
                          showLabel: showLabels,
                          // Bounded by `Expanded`, so a long label can shrink
                          // rather than push its neighbours out.
                          shrinkLabel: true,
                          dense: dense,
                          onTap: () => onChanged(option.value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }

          // Not expanding: each segment keeps the width it needs, and the
          // control scrolls if its parent is narrower than that.
          //
          // Letting the segments shrink instead only moves the overflow inside
          // them — a segment cannot be narrower than its own icon and padding,
          // so squeezing four of them into a 320px toolbar has to fail
          // somewhere. Scrolling is the failure that keeps every option
          // reachable and legible.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final SegmentOption<T> option in options)
                  _Segment<T>(
                    option: option,
                    selected: option.value == value,
                    floating: false,
                    showLabel: showLabels,
                    // Unbounded inside a horizontal scrollable: a flexible
                    // label here would be a layout error, not a nicety.
                    shrinkLabel: false,
                    dense: dense,
                    onTap: () => onChanged(option.value),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.floating,
    required this.showLabel,
    required this.shrinkLabel,
    required this.dense,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool selected;

  /// True when the animated pill is drawing the selection, so the segment
  /// itself must stay transparent.
  final bool floating;

  final bool showLabel;

  /// Whether the label may shrink. Only safe where the segment's width is
  /// bounded — inside a horizontal scrollable it is not.
  final bool shrinkLabel;

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (option.icon != null)
          Icon(
            option.icon,
            size: dense ? 13 : 15,
            color: selected ? colors.brand : colors.inkMuted,
          ),
        if (option.icon != null && showLabel)
          const SizedBox(width: Spacing.sm - 2),
        if (showLabel)
          () {
            final Widget label = Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: selected ? colors.ink : colors.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
            return shrinkLabel ? Flexible(child: label) : label;
          }(),
      ],
    );

    final Widget body = AnimatedContainer(
      duration: context.motion(Motion.fast),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Spacing.sm : Spacing.md,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: !floating && selected ? colors.surface : Colors.transparent,
        borderRadius: Radii.brSm,
        boxShadow: !floating && selected ? Shadows.xs(colors.isDark) : null,
      ),
      alignment: Alignment.center,
      child: content,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: option.tooltip ?? option.label,
      child: PressableScale(
        onTap: onTap,
        scale: 0.96,
        child: option.tooltip != null && !showLabel
            ? Tooltip(message: option.tooltip!, child: body)
            : body,
      ),
    );
  }
}

/// Underlined tab bar used inside project detail and settings.
class AppTabs extends StatelessWidget {
  const AppTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.scrollable = true,
    super.key,
  });

  final List<({String label, IconData? icon, int? count})> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        for (int i = 0; i < tabs.length; i++)
          _Tab(
            label: tabs[i].label,
            icon: tabs[i].icon,
            count: tabs[i].count,
            selected: i == selectedIndex,
            onTap: () => onChanged(i),
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: scrollable
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: row)
          : row,
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final IconData? icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = widget.selected
        ? colors.ink
        : (_hovered ? colors.inkSoft : colors.inkMuted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.selected ? colors.brand : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 15, color: foreground),
                  const SizedBox(width: Spacing.sm - 2),
                ],
                Text(
                  widget.label,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (widget.count != null) ...<Widget>[
                  const SizedBox(width: Spacing.sm - 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? colors.brandSoft
                          : colors.surfaceSunken,
                      borderRadius: Radii.brXs,
                    ),
                    child: Text(
                      '${widget.count}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: widget.selected ? colors.brand : colors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
