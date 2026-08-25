import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';

/// Building blocks for the settings area.
///
/// Settings screens rot fastest when every section invents its own row layout.
/// These four widgets cover every control in the product's settings, which is
/// what keeps the alignment identical from Profile to Danger Zone.

/// A titled group of settings rows.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.children,
    this.description,
    this.icon,
    this.isDanger = false,
    this.index = 0,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final IconData? icon;
  final bool isDanger;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Entrance(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: AppCard(
          borderColor: isDanger ? colors.danger.withValues(alpha: 0.35) : null,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(
                        icon,
                        size: 16,
                        color: isDanger ? colors.danger : colors.inkMuted,
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: context.textStyles.titleMedium?.copyWith(
                              color: isDanger ? colors.danger : colors.ink,
                            ),
                          ),
                          if (description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                description!,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: colors.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.hairline),
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, color: colors.hairline),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label, optional description, and a trailing control.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.description,
    this.trailing,
    this.onTap,
    this.isDanger = false,
    super.key,
  });

  final String label;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: isDanger ? colors.danger : colors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.inkMuted,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: Spacing.lg),
            trailing!,
          ],
          if (onTap != null && trailing == null)
            Icon(AppIcons.chevronRight, size: 15, color: colors.inkFaint),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// A settings row whose control is a switch.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      description: description,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// A settings row whose control is a set of exclusive choices.
class SettingsChoice<T> extends StatelessWidget {
  const SettingsChoice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String label;
  final String? description;
  final T value;
  final List<({T value, String label, IconData? icon})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SettingsRow(
      label: label,
      description: description,
      trailing: Wrap(
        spacing: Spacing.sm - 2,
        children: <Widget>[
          for (final ({T value, String label, IconData? icon}) option
              in options)
            PressableScale(
              onTap: () => onChanged(option.value),
              scale: 0.94,
              child: AnimatedContainer(
                duration: context.motion(Motion.fast),
                padding: EdgeInsets.symmetric(
                  horizontal: option.icon == null ? Spacing.md : Spacing.sm + 2,
                  vertical: Spacing.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: option.value == value
                      ? colors.brandSoft
                      : colors.surfaceSunken,
                  borderRadius: Radii.brSm,
                  border: Border.all(
                    color: option.value == value
                        ? colors.brandBorder
                        : colors.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (option.icon != null) ...<Widget>[
                      Icon(
                        option.icon,
                        size: 13,
                        color: option.value == value
                            ? colors.brand
                            : colors.inkMuted,
                      ),
                      const SizedBox(width: Spacing.xs + 1),
                    ],
                    Text(
                      option.label,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: option.value == value
                            ? colors.brand
                            : colors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
