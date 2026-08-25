import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// The panel every piece of content sits on.
///
/// Elevation is expressed as a level rather than a shadow so a card can be
/// nested without guessing which shadow recipe stays legible.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.elevation = 1,
    this.onTap,
    this.borderColor,
    this.background,
    this.borderRadius = Radii.brLg,
    this.isSelected = false,
    this.hoverable = false,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 0 = flat (hairline only), 1 = resting card, 2 = raised, 3 = overlay.
  final int elevation;

  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? background;
  final BorderRadius borderRadius;
  final bool isSelected;
  final bool hoverable;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget card = AnimatedContainer(
      duration: context.motion(Motion.fast),
      curve: Motion.entrance,
      padding: padding,
      decoration: BoxDecoration(
        color:
            background ?? (isSelected ? colors.selectionTint : colors.surface),
        borderRadius: borderRadius,
        border: Border.all(
          color:
              borderColor ??
              (isSelected ? colors.brandBorder : colors.hairline),
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: switch (elevation) {
          <= 0 => null,
          1 => Shadows.xs(colors.isDark),
          2 => Shadows.md(colors.isDark),
          _ => Shadows.lg(colors.isDark),
        },
      ),
      child: clip ? ClipRRect(borderRadius: borderRadius, child: child) : child,
    );

    if (onTap == null) return card;
    return HoverLift(
      enabled: hoverable,
      child: PressableScale(onTap: onTap, scale: 0.99, child: card),
    );
  }
}

/// Title, optional subtitle, optional trailing action. Used above every list
/// and dashboard panel so section rhythm is identical everywhere.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.count,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final int? count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: colors.inkMuted),
            const SizedBox(width: Spacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        title,
                        style: context.textStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null) ...<Widget>[
                      const SizedBox(width: Spacing.sm),
                      Text(
                        '$count',
                        style: context.textStyles.labelMedium?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// All-caps micro heading used inside panels and the sidebar.
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: color ?? context.colors.inkFaint,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// A collapsible section. Used by task detail panels and settings groups.
class AppDisclosure extends StatefulWidget {
  const AppDisclosure({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.trailing,
    this.count,
    super.key,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;
  final int? count;

  @override
  State<AppDisclosure> createState() => _AppDisclosureState();
}

class _AppDisclosureState extends State<AppDisclosure> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _expanded,
          label: widget.title,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: Radii.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Row(
                children: <Widget>[
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: context.motion(Motion.fast),
                    child: Icon(
                      AppIcons.chevronDown,
                      size: 15,
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  // Section titles are content, not chrome — a long one has to
                  // give way rather than push the count and trailing widget
                  // off the end of the row.
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                  ),
                  if (widget.count != null) ...<Widget>[
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '${widget.count}',
                      style: context.textStyles.labelMedium?.copyWith(
                        color: colors.inkFaint,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: SizedBox(width: double.infinity, child: widget.child),
          secondChild: const SizedBox(width: double.infinity, height: 0),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: context.motion(Motion.base),
          sizeCurve: Motion.entrance,
        ),
      ],
    );
  }
}

/// Constrains content to a comfortable measure and applies the page gutter.
class PageContainer extends StatelessWidget {
  const PageContainer({
    required this.child,
    this.maxWidth = ShellMetrics.maxContentWidth,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: context.gutter),
          child: child,
        ),
      ),
    );
  }
}
