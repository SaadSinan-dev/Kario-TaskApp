import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/services/project_stats_calculator.dart';
import 'package:kairo/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_row.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Starred projects and tasks in one place.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final List<Task> tasks = (ref.watch(tasksProvider).value ?? const <Task>[])
        .where((Task t) => t.isFavorite && !t.isArchived)
        .toList(growable: false);
    final List<Project> projects =
        (ref.watch(projectsProvider).value ?? const <Project>[])
            .where((Project p) => p.isFavorite)
            .toList(growable: false);
    final List<Task> allTasks =
        ref.watch(tasksProvider).value ?? const <Task>[];

    if (tasks.isEmpty && projects.isEmpty) {
      return ShellPage(
        title: l10n.navFavorites,
        child: AppEmptyState(
          icon: AppIcons.favorites,
          title: l10n.emptyFavoritesTitle,
          message: l10n.emptyFavoritesBody,
          actionLabel: l10n.navProjects,
          onAction: () => context.go(Routes.projects),
        ),
      );
    }

    return ShellPage(
      title: l10n.navFavorites,
      subtitle:
          '${projects.length} projects · ${l10n.tasksCount(tasks.length)}',
      padded: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          Spacing.lg,
          context.gutter,
          Spacing.huge,
        ),
        children: <Widget>[
          if (projects.isNotEmpty) ...<Widget>[
            AppSectionHeader(
              title: l10n.navProjects,
              icon: AppIcons.projects,
              count: projects.length,
            ),
            const SizedBox(height: Spacing.md),
            GridView.count(
              crossAxisCount: context.isCompact ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Spacing.md,
              crossAxisSpacing: Spacing.md,
              childAspectRatio: context.isCompact ? 2.4 : 1.9,
              children: <Widget>[
                for (int i = 0; i < projects.length; i++)
                  ProjectProgressCard(
                    index: i,
                    project: projects[i],
                    stats: ProjectStatsCalculator.forProject(
                      projects[i].id,
                      allTasks,
                    ),
                    onOpen: () => context.go(Routes.project(projects[i].id)),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xxl),
          ],
          if (tasks.isNotEmpty) ...<Widget>[
            AppSectionHeader(
              title: l10n.tasksTitle,
              icon: AppIcons.tasks,
              count: tasks.length,
            ),
            const SizedBox(height: Spacing.sm),
            _SimpleTaskList(tasks: tasks),
          ],
        ],
      ),
    );
  }
}

/// Archived tasks and projects, restorable.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final List<Task> tasks = (ref.watch(tasksProvider).value ?? const <Task>[])
        .where((Task t) => t.isArchived)
        .toList(growable: false);
    final List<Project> projects =
        (ref.watch(allProjectsProvider).value ?? const <Project>[])
            .where((Project p) => p.isArchived)
            .toList(growable: false);
    final List<Task> allTasks =
        ref.watch(tasksProvider).value ?? const <Task>[];

    if (tasks.isEmpty && projects.isEmpty) {
      return ShellPage(
        title: l10n.navArchive,
        child: AppEmptyState(
          icon: AppIcons.archive,
          title: l10n.emptyArchiveTitle,
          message: l10n.emptyArchiveBody,
        ),
      );
    }

    return ShellPage(
      title: l10n.navArchive,
      subtitle: 'Archived work stays searchable and can be restored',
      padded: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          Spacing.lg,
          context.gutter,
          Spacing.huge,
        ),
        children: <Widget>[
          if (projects.isNotEmpty) ...<Widget>[
            AppSectionHeader(
              title: l10n.navProjects,
              icon: AppIcons.projects,
              count: projects.length,
            ),
            const SizedBox(height: Spacing.md),
            for (final Project project in projects)
              _ArchivedProjectRow(project: project, tasks: allTasks),
            const SizedBox(height: Spacing.xxl),
          ],
          if (tasks.isNotEmpty) ...<Widget>[
            AppSectionHeader(
              title: l10n.tasksTitle,
              icon: AppIcons.tasks,
              count: tasks.length,
            ),
            const SizedBox(height: Spacing.sm),
            _SimpleTaskList(tasks: tasks),
          ],
        ],
      ),
    );
  }
}

/// A plain task list without the filter bar — used by collection screens where
/// the collection itself is the filter.
class _SimpleTaskList extends ConsumerWidget {
  const _SimpleTaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final TaskActions actions = ref.read(taskActionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: context.colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < tasks.length; i++)
            TaskRow(
              key: ValueKey<String>(tasks[i].id),
              task: tasks[i],
              index: i,
              onOpen: () => openTaskDetail(context, tasks[i].id),
              onToggleComplete: (bool value) => actions.setCompleted(
                l10n: l10n,
                task: tasks[i],
                completed: value,
              ),
              onEdit: () => openTaskComposer(context, ref, task: tasks[i]),
              onDuplicate: () => actions.duplicate(l10n: l10n, task: tasks[i]),
              onToggleFavorite: () => actions.toggleFavorite(tasks[i].id),
              onArchive: () => actions.setArchived(
                l10n: l10n,
                task: tasks[i],
                archived: !tasks[i].isArchived,
              ),
              onDelete: () => actions.delete(l10n: l10n, task: tasks[i]),
            ),
        ],
      ),
    );
  }
}

class _ArchivedProjectRow extends ConsumerWidget {
  const _ArchivedProjectRow({required this.project, required this.tasks});

  final Project project;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ProjectStats stats = ProjectStatsCalculator.forProject(
      project.id,
      tasks,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brMd,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: <Widget>[
          Text(project.iconEmoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(project.name, style: context.textStyles.titleSmall),
                Text(
                  context.l10n.projectsTaskCount(stats.total),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => ref
                .read(projectRepositoryProvider)
                .setArchived(project.id, archived: false),
            icon: const Icon(AppIcons.retry, size: 14),
            label: Text(context.l10n.actionRestore),
          ),
        ],
      ),
    );
  }
}

/// "My Tasks" — the signed-in person's open work, no filter bar.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final AsyncValue<List<Task>> raw = ref.watch(tasksProvider);
    final List<Task> tasks = ref.watch(myOpenTasksProvider);

    return ShellPage(
      title: l10n.navMyTasks,
      subtitle: l10n.tasksCount(tasks.length),
      padded: false,
      actions: const <Widget>[CreateTaskAction()],
      child: TaskListView(
        tasks: tasks,
        isLoading: raw.isLoading,
        onOpenTask: (Task task) => openTaskDetail(context, task.id),
        onCreate: () => openTaskComposer(context, ref),
        emptyTitle: l10n.emptyTasksTitle,
        emptyMessage: l10n.emptyTasksBody,
      ),
    );
  }
}
