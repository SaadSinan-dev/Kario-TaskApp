import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/features/shell/presentation/widgets/app_top_bar.dart';
import 'package:kairo/features/shell/presentation/widgets/workspace_switcher.dart';

/// Bottom navigation for phones.
///
/// Four destinations plus a "More" sheet. Usability testing on the mobile
/// redesign (the project this app's demo data describes) is the same argument:
/// five tabs crowd the bar and make the fifth unfindable, four leaves room for
/// labels.
class MobileNavigationBar extends ConsumerWidget {
  const MobileNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final int unread = ref.watch(unreadNotificationCountProvider);

    final List<_Destination> destinations = <_Destination>[
      _Destination(
        route: Routes.dashboard,
        icon: AppIcons.dashboard,
        label: context.l10n.navDashboard,
      ),
      _Destination(
        route: Routes.tasks,
        icon: AppIcons.tasks,
        label: context.l10n.navMyTasks,
      ),
      _Destination(
        route: Routes.calendar,
        icon: AppIcons.calendar,
        label: context.l10n.navCalendar,
      ),
      _Destination(
        route: Routes.notifications,
        icon: AppIcons.inbox,
        label: context.l10n.navInbox,
        badge: unread,
      ),
    ];

    final int index = destinations.indexWhere(
      (_Destination d) => location.startsWith(d.route),
    );

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (int selected) {
        if (selected == destinations.length) {
          _openMoreSheet(context);
          return;
        }
        context.go(destinations[selected].route);
      },
      destinations: <Widget>[
        for (final _Destination destination in destinations)
          NavigationDestination(
            icon: destination.badge != null && destination.badge! > 0
                ? Badge.count(
                    count: destination.badge!,
                    child: Icon(destination.icon),
                  )
                : Icon(destination.icon),
            label: destination.label,
          ),
        NavigationDestination(
          icon: const Icon(AppIcons.more),
          label: context.l10n.navMore,
        ),
      ],
    );
  }

  Future<void> _openMoreSheet(BuildContext context) {
    return showAppSheet<void>(
      context: context,
      expand: true,
      initialSize: 0.6,
      builder: (BuildContext context) => const _MoreSheet(),
    );
  }
}

class _Destination {
  const _Destination({
    required this.route,
    required this.icon,
    required this.label,
    this.badge,
  });

  final String route;
  final IconData icon;
  final String label;
  final int? badge;
}

/// Everything that does not fit on the bar, plus the workspace switcher and
/// theme control that live in the desktop chrome.
class _MoreSheet extends ConsumerWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    final List<({String route, IconData icon, String label})> items =
        <({String route, IconData icon, String label})>[
          (
            route: Routes.projects,
            icon: AppIcons.projects,
            label: l10n.navProjects,
          ),
          (
            route: Routes.timeline,
            icon: AppIcons.timeline,
            label: l10n.navTimeline,
          ),
          (route: Routes.focus, icon: AppIcons.focus, label: l10n.navFocus),
          (
            route: Routes.analytics,
            icon: AppIcons.analytics,
            label: l10n.navAnalytics,
          ),
          (
            route: Routes.favorites,
            icon: AppIcons.favorites,
            label: l10n.navFavorites,
          ),
          (
            route: Routes.archive,
            icon: AppIcons.archive,
            label: l10n.navArchive,
          ),
          (route: Routes.search, icon: AppIcons.search, label: l10n.navSearch),
          (
            route: Routes.settings,
            icon: AppIcons.settings,
            label: l10n.navSettings,
          ),
        ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SheetHeader(title: l10n.navMore, trailing: const ThemeToggleButton()),
        const Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: WorkspaceSwitcher(),
        ),
        Divider(height: 1, color: colors.hairline),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            children: <Widget>[
              for (final ({String route, IconData icon, String label}) item
                  in items)
                ListTile(
                  leading: Icon(item.icon, size: 19),
                  title: Text(item.label),
                  trailing: const Icon(AppIcons.chevronRight, size: 15),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(item.route);
                  },
                ),
            ],
          ),
        ),
        const SafeArea(top: false, child: SizedBox(height: Spacing.sm)),
      ],
    );
  }
}
