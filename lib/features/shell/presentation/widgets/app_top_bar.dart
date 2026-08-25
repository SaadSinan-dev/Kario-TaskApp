import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/command_palette/presentation/command_palette.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';

/// The persistent command bar.
///
/// Search, notifications, theme and profile are reachable from every screen —
/// that constancy is what makes the app feel like a workspace rather than a set
/// of pages.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final int unread = ref.watch(unreadNotificationCountProvider);
    final User? user = ref.watch(currentUserValueProvider);
    final ScreenSize size = context.breakpoint;

    // The trailing cluster is fixed-width, so it is what decides whether the
    // bar fits. It sheds affordances as the screen narrows, in the order they
    // stop being worth their width:
    //
    //  * the search *field* becomes a search icon below `expanded`;
    //  * "create" disappears on phones, where the shell already shows a
    //    floating action button for exactly that;
    //  * the theme toggle disappears on phones, where it is a rarely-used
    //    preference that still lives in Settings › Appearance.
    //
    // Nothing here is merely hidden: every action that goes away is reachable
    // in one tap somewhere else on the same screen.
    final bool showSearchField = size.index >= ScreenSize.expanded.index;
    final bool showSecondaryChrome = size.index >= ScreenSize.medium.index;

    return Container(
      height: ShellMetrics.topBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: responsiveValue<double>(
          size,
          compact: Spacing.md,
          expanded: Spacing.lg,
        ),
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          ?leading,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // `maxLines` is explicit: `overflow` alone still allows the
                // text to wrap to a second line, which overflows the bar's
                // fixed height at large system text scales.
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleLarge,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          for (final Widget action in actions) ...<Widget>[
            action,
            const SizedBox(width: Spacing.sm),
          ],
          if (showSearchField) ...<Widget>[
            const _SearchTrigger(),
            const SizedBox(width: Spacing.sm),
          ] else
            AppIconButton(
              icon: AppIcons.search,
              tooltip: context.l10n.navSearch,
              onPressed: () => openCommandPalette(context),
            ),
          if (showSecondaryChrome)
            AppIconButton(
              icon: AppIcons.add,
              tooltip: context.l10n.actionCreateTask,
              onPressed: () => openTaskComposer(context, ref),
            ),
          AppIconButton(
            icon: AppIcons.notifications,
            tooltip: context.l10n.navNotifications,
            badgeCount: unread,
            onPressed: () => context.go(Routes.notifications),
          ),
          if (showSecondaryChrome) const ThemeToggleButton(),
          const SizedBox(width: Spacing.sm),
          _ProfileMenu(user: user),
        ],
      ),
    );
  }
}

/// Opens the command palette. Styled as an input so its purpose is obvious
/// before anyone learns the shortcut.
class _SearchTrigger extends StatefulWidget {
  const _SearchTrigger();

  @override
  State<_SearchTrigger> createState() => _SearchTriggerState();
}

class _SearchTriggerState extends State<_SearchTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => openCommandPalette(context),
        child: AnimatedContainer(
          duration: context.motion(Motion.fast),
          width: 232,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.brMd,
            border: Border.all(
              color: _hovered ? colors.hairlineStrong : colors.hairline,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.search, size: 15, color: colors.inkFaint),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  context.l10n.searchPlaceholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ),
              const KeycapHint(<String>['⌘', 'K'], compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles light → dark → system, with the icon reflecting the current choice.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemePreference theme = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.theme),
    );

    final (IconData icon, String label) = switch (theme) {
      ThemePreference.light => (
        AppIcons.themeLight,
        context.l10n.settingsThemeLight,
      ),
      ThemePreference.dark => (
        AppIcons.themeDark,
        context.l10n.settingsThemeDark,
      ),
      ThemePreference.system => (
        AppIcons.themeSystem,
        context.l10n.settingsThemeSystem,
      ),
    };

    return AppIconButton(
      icon: icon,
      tooltip: '${context.l10n.paletteToggleTheme} · $label',
      onPressed: () {
        final ThemePreference next = switch (theme) {
          ThemePreference.light => ThemePreference.dark,
          ThemePreference.dark => ThemePreference.system,
          ThemePreference.system => ThemePreference.light,
        };
        ref
            .read(preferencesProvider.notifier)
            .update((UserPreferences p) => p.copyWith(theme: next));
      },
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSelectMenu<String>(
      options: <MenuOption<String>>[
        MenuOption<String>(
          value: 'profile',
          label: context.l10n.settingsProfile,
          icon: AppIcons.assignee,
        ),
        MenuOption<String>(
          value: 'settings',
          label: context.l10n.navSettings,
          icon: AppIcons.settings,
        ),
        MenuOption<String>(
          value: 'shortcuts',
          label: context.l10n.shortcutsTitle,
          icon: AppIcons.command,
        ),
        MenuOption<String>(
          value: 'signout',
          label: context.l10n.authSignOut,
          icon: AppIcons.signOut,
          isDestructive: true,
        ),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'profile':
            context.go(Routes.settingsFor('profile'));
          case 'settings':
            context.go(Routes.settings);
          case 'shortcuts':
            await showShortcutsDialog(context);
          case 'signout':
            await ref.read(authRepositoryProvider).signOut();
        }
      },
      builder: (BuildContext context, VoidCallback open) => Tooltip(
        message: user?.name ?? '',
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(40),
          child: AppAvatar(user: user, size: 30, showTooltip: false),
        ),
      ),
    );
  }
}
