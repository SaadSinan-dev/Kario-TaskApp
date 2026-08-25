import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/shell/presentation/widgets/nav_item.dart';
import 'package:kairo/features/shell/presentation/widgets/workspace_switcher.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';

/// The desktop navigation surface.
///
/// Three bands: identity at the top, destinations and projects in the middle,
/// the signed-in person at the bottom. Collapsing keeps the icons and drops the
/// labels — the muscle memory of the vertical positions survives, which is the
/// whole point of collapsing rather than hiding.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    required this.collapsed,
    required this.onToggleCollapse,
    super.key,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final String location = GoRouterState.of(context).uri.path;
    final int unread = ref.watch(unreadNotificationCountProvider);
    final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final List<Project> projects =
        ref.watch(projectsProvider).value ?? const <Project>[];
    final User? user = ref.watch(currentUserValueProvider);

    final int myOpenTasks = tasks
        .where(
          (Task t) => !t.isDone && !t.isArchived && t.assigneeId == user?.id,
        )
        .length;
    final int favoriteCount =
        tasks.where((Task t) => t.isFavorite && !t.isArchived).length +
        projects.where((Project p) => p.isFavorite).length;

    return AnimatedContainer(
      duration: context.motion(Motion.medium),
      curve: Motion.emphasized,
      width: collapsed
          ? ShellMetrics.sidebarCollapsedWidth
          : ShellMetrics.sidebarWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(end: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
              Spacing.sm,
            ),
            child: WorkspaceSwitcher(collapsed: collapsed),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: collapsed
                ? AppIconButton(
                    icon: AppIcons.add,
                    tooltip: context.l10n.actionCreateTask,
                    size: 38,
                    background: colors.brand,
                    color: Colors.white,
                    onPressed: () => openTaskComposer(context, ref),
                  )
                : AppButton.primary(
                    label: context.l10n.actionCreateTask,
                    icon: AppIcons.add,
                    isFullWidth: true,
                    onPressed: () => openTaskComposer(context, ref),
                  ),
          ),
          const SizedBox(height: Spacing.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              children: <Widget>[
                _navItem(
                  context,
                  icon: AppIcons.dashboard,
                  label: context.l10n.navDashboard,
                  route: Routes.dashboard,
                  location: location,
                ),
                _navItem(
                  context,
                  icon: AppIcons.tasks,
                  label: context.l10n.navMyTasks,
                  route: Routes.tasks,
                  location: location,
                  badge: myOpenTasks,
                ),
                _navItem(
                  context,
                  icon: AppIcons.inbox,
                  label: context.l10n.navInbox,
                  route: Routes.notifications,
                  location: location,
                  badge: unread,
                ),
                _navItem(
                  context,
                  icon: AppIcons.calendar,
                  label: context.l10n.navCalendar,
                  route: Routes.calendar,
                  location: location,
                ),
                _navItem(
                  context,
                  icon: AppIcons.timeline,
                  label: context.l10n.navTimeline,
                  route: Routes.timeline,
                  location: location,
                ),
                _navItem(
                  context,
                  icon: AppIcons.focus,
                  label: context.l10n.navFocus,
                  route: Routes.focus,
                  location: location,
                ),
                _navItem(
                  context,
                  icon: AppIcons.analytics,
                  label: context.l10n.navAnalytics,
                  route: Routes.analytics,
                  location: location,
                ),

                if (!collapsed)
                  SidebarSectionLabel(
                    label: context.l10n.navProjects,
                    action: AppIcons.add,
                    actionTooltip: context.l10n.actionCreateProject,
                    onAction: () => context.go(Routes.projects),
                  )
                else
                  const SizedBox(height: Spacing.lg),

                _navItem(
                  context,
                  icon: AppIcons.projects,
                  label: context.l10n.navProjects,
                  route: Routes.projects,
                  location: location,
                ),
                for (final Project project in projects.take(collapsed ? 0 : 6))
                  SidebarNavItem(
                    icon: AppIcons.projects,
                    emoji: project.iconEmoji,
                    label: project.name,
                    indent: Spacing.md,
                    isSelected: location == Routes.project(project.id),
                    collapsed: collapsed,
                    onTap: () => context.go(Routes.project(project.id)),
                    trailing: project.isFavorite
                        ? Icon(
                            AppIcons.favorites,
                            size: 12,
                            color: colors.warning,
                          )
                        : null,
                  ),

                if (!collapsed)
                  SidebarSectionLabel(label: context.l10n.commonMore)
                else
                  const SizedBox(height: Spacing.lg),

                _navItem(
                  context,
                  icon: AppIcons.favorites,
                  label: context.l10n.navFavorites,
                  route: Routes.favorites,
                  location: location,
                  badge: favoriteCount,
                ),
                _navItem(
                  context,
                  icon: AppIcons.archive,
                  label: context.l10n.navArchive,
                  route: Routes.archive,
                  location: location,
                ),
                _navItem(
                  context,
                  icon: AppIcons.settings,
                  label: context.l10n.navSettings,
                  route: Routes.settings,
                  location: location,
                ),
                const SizedBox(height: Spacing.lg),
              ],
            ),
          ),
          Divider(color: colors.hairline, height: 1),
          _SidebarFooter(
            collapsed: collapsed,
            onToggleCollapse: onToggleCollapse,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String location,
    int? badge,
  }) {
    return SidebarNavItem(
      icon: icon,
      label: label,
      collapsed: collapsed,
      badgeCount: badge,
      isSelected:
          location == route ||
          (route != Routes.dashboard && location.startsWith('$route/')),
      onTap: () => context.go(route),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final User? user = ref.watch(currentUserValueProvider);

    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () => context.go(Routes.settingsFor('profile')),
              borderRadius: Radii.brMd,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: <Widget>[
                    AppAvatar(user: user, size: 28, showTooltip: collapsed),
                    if (!collapsed) ...<Widget>[
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              user?.name ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelLarge,
                            ),
                            Text(
                              user?.jobTitle.isNotEmpty ?? false
                                  ? user!.jobTitle
                                  : (user?.email ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelSmall?.copyWith(
                                color: colors.inkFaint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!collapsed)
            AppIconButton(
              icon: AppIcons.sidebarClose,
              tooltip: context.l10n.paletteToggleSidebar,
              onPressed: onToggleCollapse,
            ),
        ],
      ),
    );
  }
}
