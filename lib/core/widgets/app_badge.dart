import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/workspace.dart';

enum BadgeTone { neutral, brand, success, warning, danger, violet, teal }

/// A small tinted label. The tone maps to the semantic colour pairs in the
/// theme so a badge is never a one-off colour.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
    this.color,
    this.compact = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  /// Overrides the tone with an explicit colour — used by labels and projects,
  /// which carry a user-chosen colour.
  final Color? color;

  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = color ?? _toneColor(context);
    final Color background = color != null
        ? accent.withValues(alpha: colors.isDark ? 0.18 : 0.12)
        : _toneBackground(context);

    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Spacing.xs + 2 : Spacing.sm,
          vertical: compact ? 1 : 3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: Radii.brSm,
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: compact ? 10 : 12, color: accent),
              const SizedBox(width: 4),
            ],
            // Flexible rather than fixed: badges sit inside narrow columns and
            // toolbars, and a long label must ellipsize rather than overflow.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? context.textStyles.labelSmall
                            : context.textStyles.labelMedium)
                        ?.copyWith(color: accent, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) {
    final colors = context.colors;
    return switch (tone) {
      BadgeTone.neutral => colors.inkMuted,
      BadgeTone.brand => colors.brand,
      BadgeTone.success => colors.success,
      BadgeTone.warning => colors.warning,
      BadgeTone.danger => colors.danger,
      BadgeTone.violet => colors.violet,
      BadgeTone.teal => colors.teal,
    };
  }

  Color _toneBackground(BuildContext context) {
    final colors = context.colors;
    return switch (tone) {
      BadgeTone.neutral => colors.surfaceSunken,
      BadgeTone.brand => colors.brandSoft,
      BadgeTone.success => colors.successSoft,
      BadgeTone.warning => colors.warningSoft,
      BadgeTone.danger => colors.dangerSoft,
      BadgeTone.violet => colors.violet.withValues(alpha: 0.12),
      BadgeTone.teal => colors.teal.withValues(alpha: 0.12),
    };
  }
}

/// Status shown as a coloured dot plus its name — readable without colour.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, this.compact = false, super.key});

  final TaskStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = status.color(context.colors);
    return Semantics(
      label: '${context.l10n.fieldStatus}: ${status.label(context.l10n)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: Spacing.xs + 2),
          // Flexible so the pill survives a large system text scale inside the
          // list view's fixed-width status column.
          Flexible(
            child: Text(
              status.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? context.textStyles.labelSmall
                          : context.textStyles.labelMedium)
                      ?.copyWith(color: context.colors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority as an icon plus optional label. The icon differs per level so the
/// meaning survives without colour.
class PriorityPill extends StatelessWidget {
  const PriorityPill({
    required this.priority,
    this.showLabel = true,
    this.compact = false,
    super.key,
  });

  final TaskPriority priority;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = priority.color(context.colors);
    final Widget icon = Icon(
      priority.icon,
      size: compact ? 12 : 14,
      color: color,
    );

    if (!showLabel) {
      return Tooltip(
        message: priority.label(context.l10n),
        child: Semantics(
          label: priority.semanticLabel(context.l10n),
          child: icon,
        ),
      );
    }

    return Semantics(
      label: priority.semanticLabel(context.l10n),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon,
          const SizedBox(width: Spacing.xs + 2),
          Text(
            priority.label(context.l10n),
            style:
                (compact
                        ? context.textStyles.labelSmall
                        : context.textStyles.labelMedium)
                    ?.copyWith(color: context.colors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// A workspace label rendered as a coloured chip.
class LabelChip extends StatelessWidget {
  const LabelChip({
    required this.label,
    this.onRemove,
    this.compact = true,
    super.key,
  });

  final Label label;
  final VoidCallback? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(label.colorValue);
    return Container(
      padding: EdgeInsets.only(
        left: compact ? Spacing.xs + 2 : Spacing.sm,
        right: onRemove != null ? 2 : (compact ? Spacing.xs + 2 : Spacing.sm),
        top: compact ? 1 : 3,
        bottom: compact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.colors.isDark ? 0.18 : 0.11),
        borderRadius: Radii.brSm,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          // Label names are user-supplied and chips sit inside fixed-width
          // columns, so the text has to give way rather than overflow.
          Flexible(
            child: Text(
              label.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.isDark
                    ? Color.lerp(color, Colors.white, 0.35)
                    : Color.lerp(color, Colors.black, 0.25),
                height: 1.3,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(AppIcons.close, size: 11),
              onPressed: onRemove,
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              splashRadius: 10,
              color: color,
              tooltip: context.l10n.actionRemove,
            ),
        ],
      ),
    );
  }
}

/// Interactive filter chip used across filter bars and pickers.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.count,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = color ?? colors.brand;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.motion(Motion.fast),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm - 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: colors.isDark ? 0.2 : 0.12)
                : colors.surface,
            borderRadius: Radii.brSm,
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.5) : colors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? accent : colors.inkMuted,
                ),
                const SizedBox(width: Spacing.xs + 2),
              ],
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: selected ? accent : colors.inkSoft,
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: Spacing.xs + 2),
                Text(
                  '$count',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: selected
                        ? accent.withValues(alpha: 0.8)
                        : colors.inkFaint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Keyboard shortcut hint, e.g. `⌘ K`. Rendered as small keycaps.
class KeycapHint extends StatelessWidget {
  const KeycapHint(this.keys, {this.compact = false, super.key});

  final List<String> keys;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String key in keys)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              constraints: BoxConstraints(minWidth: compact ? 16 : 19),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : 5,
                vertical: compact ? 1 : 2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: Radii.brXs,
                border: Border.all(color: colors.hairline),
              ),
              child: Text(
                key,
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.inkMuted,
                  fontSize: compact ? 9.5 : 10.5,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
