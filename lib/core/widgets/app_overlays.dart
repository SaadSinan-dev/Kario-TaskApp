import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_button.dart';

/// Modal helpers.
///
/// Every dialog and sheet in the app goes through these functions, so entrance
/// motion, barrier colour, corner radius and dismiss behaviour are decided once
/// rather than per call site.

/// Scale-and-fade entrance. Modals grow from 96% so they read as arriving
/// rather than being pasted on.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  double maxWidth = 460,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: context.motion(Motion.base),
    pageBuilder: (BuildContext context, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
    ),
    transitionBuilder:
        (BuildContext context, Animation<double> animation, _, Widget child) {
          final Animation<double> eased = CurvedAnimation(
            parent: animation,
            curve: Motion.emphasized,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(eased),
              child: child,
            ),
          );
        },
  );
}

/// A framed dialog: title row, scrollable body, action bar.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.icon,
    this.iconColor,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final IconData? icon;
  final Color? iconColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xxl,
        0,
        Spacing.xxl,
        Spacing.lg,
      ),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: Radii.brXl,
        border: Border.all(color: colors.hairline),
        boxShadow: Shadows.xl(colors.isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xxl,
              Spacing.xl,
              Spacing.md,
              Spacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (iconColor ?? colors.brand).withValues(
                        alpha: 0.13,
                      ),
                      borderRadius: Radii.brMd,
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: iconColor ?? colors.brand,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: context.textStyles.headlineSmall),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.close,
                  tooltip: context.l10n.actionClose,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: scrollable ? SingleChildScrollView(child: body) : body,
          ),
          if (actions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                border: Border(top: BorderSide(color: colors.hairline)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(Radii.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: Spacing.sm),
                    actions[i],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Confirmation for destructive actions. Returns true only on explicit
/// confirmation; dismissing the barrier means "no".
Future<bool> confirmAction({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
  IconData? icon,
}) async {
  final bool? result = await showAppDialog<bool>(
    context: context,
    maxWidth: 420,
    child: Builder(
      builder: (BuildContext context) => AppDialogShell(
        title: title,
        icon: icon ?? (destructive ? AppIcons.warning : AppIcons.info),
        iconColor: destructive ? context.colors.danger : context.colors.brand,
        scrollable: false,
        actions: <Widget>[
          AppButton(
            label: cancelLabel ?? context.l10n.actionCancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: confirmLabel ?? context.l10n.actionConfirm,
            variant: destructive
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
        child: Text(
          message,
          style: context.textStyles.bodyMedium?.copyWith(height: 1.55),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Bottom sheet used on compact layouts wherever a dialog would be used on
/// desktop. Draggable, keyboard-aware, and capped at 92% of the screen.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double initialSize = 0.62,
  bool expand = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (BuildContext context) {
      final Widget content = Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceOverlay,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Radii.xxl),
          ),
          border: Border(top: BorderSide(color: context.colors.hairline)),
        ),
        clipBehavior: Clip.antiAlias,
        child: builder(context),
      );

      // The keyboard is subtracted from the sheet's height budget, in both
      // modes.
      //
      // This is the whole bug behind "adding a task breaks on my phone". The
      // task composer autofocuses its title, so the keyboard is up before the
      // sheet has finished opening. `DraggableScrollableSheet` sizes itself as
      // a *fraction of its parent*, and its parent was the full screen — so
      // asking for 0.9 gave a sheet 90% of the screen tall while only ~60% of
      // the screen was actually visible. Everything below the fold, including
      // the "New task" button, was laid out underneath the keyboard, and the
      // sheet's own column had nowhere to put it.
      //
      // Padding *outside* the sheet is what makes the fractions mean what they
      // say: 0.9 of the space the user can actually see.
      final double keyboard = context.keyboardInset;

      if (!expand) {
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: content,
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: 0.35,
          maxChildSize: 1,
          expand: false,
          // `snap` keeps a half-dragged sheet from resting at an arbitrary
          // height when the keyboard opens or closes underneath it.
          snap: true,
          snapSizes: <double>[initialSize],
          builder: (BuildContext context, ScrollController controller) =>
              PrimaryScrollController(controller: controller, child: content),
        ),
      );
    },
  );
}

/// Title bar for a bottom sheet: drag handle, title, close.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    required this.title,
    this.trailing,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
        Spacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: context.textStyles.titleLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
          AppIconButton(
            icon: AppIcons.close,
            tooltip: context.l10n.actionClose,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// One option in an [AppSelectMenu].
class MenuOption<T> {
  const MenuOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.trailing,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;
  final bool isDestructive;
}

/// A themed dropdown built on [MenuAnchor].
///
/// Used everywhere a property is picked — status, priority, assignee, project,
/// grouping, sorting — so those pickers all look and behave identically.
class AppSelectMenu<T> extends StatelessWidget {
  const AppSelectMenu({
    required this.options,
    required this.onSelected,
    required this.builder,
    this.selected,
    this.alignmentOffset = const Offset(0, 6),
    super.key,
  });

  final List<MenuOption<T>> options;
  final ValueChanged<T> onSelected;
  final T? selected;

  /// The trigger. Receives a callback that opens the menu.
  final Widget Function(BuildContext context, VoidCallback open) builder;

  final Offset alignmentOffset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MenuAnchor(
      alignmentOffset: alignmentOffset,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(colors.surfaceOverlay),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        elevation: const WidgetStatePropertyAll<double>(0),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(vertical: Spacing.xs),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: Radii.brMd,
            side: BorderSide(color: colors.hairline),
          ),
        ),
      ),
      menuChildren: <Widget>[
        for (final MenuOption<T> option in options)
          _MenuRow<T>(
            option: option,
            isSelected: option.value == selected,
            onTap: () => onSelected(option.value),
          ),
      ],
      builder: (BuildContext context, MenuController controller, Widget? _) =>
          builder(context, () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          }),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final MenuOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = option.isDestructive
        ? colors.danger
        : (option.color ?? colors.ink);

    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 2),
        ),
        minimumSize: const WidgetStatePropertyAll<Size>(Size(190, 34)),
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.surfaceSunken;
          }
          return Colors.transparent;
        }),
      ),
      child: Row(
        children: <Widget>[
          if (option.icon != null) ...<Widget>[
            Icon(option.icon, size: 15, color: foreground),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            child: Text(
              option.label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (option.trailing != null) option.trailing!,
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.sm),
              child: Icon(AppIcons.check, size: 14, color: colors.brand),
            ),
        ],
      ),
    );
  }
}

/// Context menu trigger (the "…" button) with a themed list of actions.
class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({
    required this.options,
    required this.onSelected,
    this.icon = AppIcons.moreVertical,
    this.tooltip,
    this.size = 30,
    super.key,
  });

  final List<MenuOption<String>> options;
  final ValueChanged<String> onSelected;
  final IconData icon;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<String>(
      options: options,
      onSelected: onSelected,
      builder: (BuildContext context, VoidCallback open) => AppIconButton(
        icon: icon,
        tooltip: tooltip ?? context.l10n.commonOptions,
        size: size,
        onPressed: open,
      ),
    );
  }
}
