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
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/charts/bar_donut_charts.dart';
import 'package:kairo/core/widgets/charts/chart_core.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/services/project_stats_calculator.dart';
import 'package:kairo/features/calendar/presentation/widgets/calendar_views.dart';
import 'package:kairo/features/projects/presentation/projects_screen.dart';
import 'package:kairo/features/projects/presentation/widgets/project_editor.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/activity_feed.dart';
import 'package:kairo/features/tasks/presentation/widgets/markdown_renderer.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_board_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/timeline_bridge.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// A project, with every view of its work under one header.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Project?> async = ref.watch(
      projectByIdProvider(widget.projectId),
    );
    final AppL10n l10n = context.l10n;

    return async.when(
      loading: () => ShellPage(
        title: l10n.projectsTitle,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (Object error, _) => ShellPage(
        title: l10n.errorGenericTitle,
        child: AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(projectByIdProvider(widget.projectId)),
          onGoHome: () => context.go(Routes.projects),
        ),
      ),
      data: (Project? project) {
        if (project == null) {
          return ShellPage(
            title: l10n.errorNotFoundTitle,
            child: AppEmptyState(
              icon: AppIcons.projects,
              title: l10n.errorNotFoundTitle,
              message: l10n.errorNotFoundBody,
              actionLabel: l10n.projectsTitle,
              onAction: () => context.go(Routes.projects),
            ),
          );
        }
        return _body(context, project);
      },
    );
  }

  Widget _body(BuildContext context, Project project) {
    final AppL10n l10n = context.l10n;
    final List<Task> allTasks =
        ref.watch(tasksProvider).value ?? const <Task>[];
    final List<Task> projectTasks = ref.watch(
      filteredProjectTasksProvider(project.id),
    );
    final ProjectStats stats = ProjectStatsCalculator.forProject(
      project.id,
      allTasks,
    );

    final List<({String label, IconData? icon, int? count})>
    tabs = <({String label, IconData? icon, int? count})>[
      (label: l10n.projectsOverview, icon: AppIcons.dashboard, count: null),
      (
        label: l10n.tasksViewList,
        icon: AppIcons.viewList,
        count: projectTasks.length,
      ),
      (label: l10n.tasksViewBoard, icon: AppIcons.viewBoard, count: null),
      (label: l10n.tasksViewCalendar, icon: AppIcons.viewCalendar, count: null),
      (label: l10n.tasksViewTimeline, icon: AppIcons.viewTimeline, count: null),
      (label: l10n.fieldActivity, icon: AppIcons.activity, count: null),
    ];

    return ShellPage(
      title: '${project.iconEmoji}  ${project.name}',
      subtitle:
          '${(stats.progress * 100).round()}% complete · '
          '${l10n.projectsTaskCount(stats.total)}',
      padded: false,
      actions: <Widget>[
        CreateTaskAction(projectId: project.id),
        AppIconButton(
          icon: AppIcons.favorites,
          tooltip: project.isFavorite
              ? l10n.projectsUnfavorite
              : l10n.projectsFavorite,
          isActive: project.isFavorite,
          color: project.isFavorite ? context.colors.warning : null,
          onPressed: () =>
              ref.read(projectRepositoryProvider).toggleFavorite(project.id),
        ),
        AppOverflowMenu(
          options: <MenuOption<String>>[
            MenuOption<String>(
              value: 'edit',
              label: l10n.actionEdit,
              icon: AppIcons.edit,
            ),
            MenuOption<String>(
              value: 'archive',
              label: project.isArchived
                  ? l10n.actionRestore
                  : l10n.actionArchive,
              icon: AppIcons.archive,
            ),
            MenuOption<String>(
              value: 'delete',
              label: l10n.actionDelete,
              icon: AppIcons.delete,
              isDestructive: true,
            ),
          ],
          onSelected: (String value) async {
            switch (value) {
              case 'edit':
                await openProjectEditor(context, ref, project: project);
              case 'archive':
                await ref
                    .read(projectRepositoryProvider)
                    .setArchived(project.id, archived: !project.isArchived);
              case 'delete':
                await confirmDeleteProject(context, ref, project);
                if (context.mounted) context.go(Routes.projects);
            }
          },
        ),
      ],
      toolbar: Container(
        color: context.colors.canvas,
        padding: EdgeInsets.symmetric(horizontal: context.gutter),
        child: AppTabs(
          tabs: tabs,
          selectedIndex: _tab,
          onChanged: (int index) => setState(() => _tab = index),
        ),
      ),
      child: AnimatedSwitcher(
        duration: context.motion(Motion.base),
        child: switch (_tab) {
          0 => _Overview(
            key: const ValueKey<int>(0),
            project: project,
            stats: stats,
            tasks: allTasks
                .where((Task t) => t.projectId == project.id)
                .toList(growable: false),
          ),
          1 => TaskListView(
            key: const ValueKey<int>(1),
            tasks: projectTasks,
            showProject: false,
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
            onCreate: () =>
                openTaskComposer(context, ref, projectId: project.id),
          ),
          2 => TaskBoardView(
            key: const ValueKey<int>(2),
            tasks: projectTasks,
            projectId: project.id,
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
          ),
          3 => _ProjectCalendar(
            key: const ValueKey<int>(3),
            tasks: projectTasks,
          ),
          4 => TimelinePane(
            key: const ValueKey<int>(4),
            tasks: projectTasks,
            projectId: project.id,
          ),
          _ => _ProjectActivity(
            key: const ValueKey<int>(5),
            projectId: project.id,
          ),
        },
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({
    required this.project,
    required this.stats,
    required this.tasks,
    super.key,
  });

  final Project project;
  final ProjectStats stats;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final colors = context.colors;
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final ScreenSize size = context.breakpoint;
    final bool wide = size.index >= ScreenSize.expanded.index;

    final Map<TaskStatus, int> byStatus = <TaskStatus, int>{};
    for (final Task task in tasks) {
      if (task.isArchived) continue;
      byStatus[task.status] = (byStatus[task.status] ?? 0) + 1;
    }

    final List<Task> upcoming =
        tasks
            .where((Task t) => !t.isDone && t.dueDate != null)
            .toList(growable: false)
          ..sort((Task a, Task b) => a.dueDate!.compareTo(b.dueDate!));

    final Widget left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ProjectStatusBadge(status: project.status),
                  const SizedBox(width: Spacing.sm),
                  if (project.startDate != null || project.dueDate != null)
                    AppBadge(
                      label:
                          '${project.startDate == null ? '—' : Dates.dayMonth(project.startDate!)}'
                          ' → '
                          '${project.dueDate == null ? '—' : Dates.dayMonth(project.dueDate!)}',
                      icon: AppIcons.dueDate,
                    ),
                  const Spacer(),
                  AvatarStack(
                    users: <User>[
                      for (final String id in project.memberIds)
                        if (members[id] != null) members[id]!,
                    ],
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                MarkdownBody(project.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: l10n.dashboardCompleted,
                value: stats.completed,
                color: colors.success,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _StatTile(
                label: l10n.statusInProgress,
                value: stats.inProgress,
                color: colors.warning,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _StatTile(
                label: l10n.dashboardRemaining,
                value: stats.remaining,
                color: colors.brand,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _StatTile(
                label: l10n.dashboardOverdue,
                value: stats.overdue,
                color: colors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        if (project.milestones.isNotEmpty) _Milestones(project: project),
      ],
    );

    final Widget right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Column(
            children: <Widget>[
              AppSectionHeader(
                title: l10n.projectsProgress,
                icon: AppIcons.analytics,
              ),
              const SizedBox(height: Spacing.lg),
              SizedBox(
                height: 150,
                child: DonutChart(
                  centerValue: '${(stats.progress * 100).round()}%',
                  centerLabel: l10n.dashboardCompleted,
                  slices: <DonutSlice>[
                    for (final MapEntry<TaskStatus, int> entry
                        in byStatus.entries)
                      DonutSlice(
                        label: entry.key.name,
                        value: entry.value.toDouble(),
                        color: switch (entry.key) {
                          TaskStatus.backlog => colors.statusBacklog,
                          TaskStatus.todo => colors.statusTodo,
                          TaskStatus.inProgress => colors.statusInProgress,
                          TaskStatus.review => colors.statusReview,
                          TaskStatus.done => colors.statusDone,
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              ChartLegend(
                entries: <({String label, Color color, String? value})>[
                  for (final TaskStatus status in TaskStatus.values)
                    if ((byStatus[status] ?? 0) > 0)
                      (
                        label: status.name,
                        color: switch (status) {
                          TaskStatus.backlog => colors.statusBacklog,
                          TaskStatus.todo => colors.statusTodo,
                          TaskStatus.inProgress => colors.statusInProgress,
                          TaskStatus.review => colors.statusReview,
                          TaskStatus.done => colors.statusDone,
                        },
                        value: '${byStatus[status]}',
                      ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSectionHeader(
                title: l10n.dashboardUpcoming,
                icon: AppIcons.dueDate,
                count: upcoming.length,
              ),
              const SizedBox(height: Spacing.sm),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Text(
                    'No upcoming deadlines in this project.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
                )
              else
                for (final Task task in upcoming.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      onTap: () => openTaskDetail(context, task.id),
                      borderRadius: Radii.brSm,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            Dates.dueLabel(task.dueDate, l10n),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: task.isOverdue
                                  ? colors.danger
                                  : colors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.lg,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: left),
              const SizedBox(width: Spacing.lg),
              Expanded(flex: 2, child: right),
            ],
          )
        else ...<Widget>[left, const SizedBox(height: Spacing.lg), right],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brMd,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Spacing.sm - 2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm - 2),
          AnimatedCounter(
            value: value,
            style: AppTypography.numeric.copyWith(
              fontSize: 22,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionHeader(
            title: context.l10n.timelineMilestones,
            icon: AppIcons.milestone,
            count: project.milestones.length,
          ),
          const SizedBox(height: Spacing.md),
          for (final Milestone milestone in project.milestones)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  Icon(
                    milestone.isReached
                        ? AppIcons.statusDone
                        : AppIcons.milestone,
                    size: 15,
                    color: milestone.isReached ? colors.success : colors.violet,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: milestone.isReached
                            ? colors.inkFaint
                            : colors.ink,
                      ),
                    ),
                  ),
                  Text(
                    Dates.dayMonth(milestone.date),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCalendar extends ConsumerStatefulWidget {
  const _ProjectCalendar({required this.tasks, super.key});

  final List<Task> tasks;

  @override
  ConsumerState<_ProjectCalendar> createState() => _ProjectCalendarState();
}

class _ProjectCalendarState extends ConsumerState<_ProjectCalendar> {
  DateTime _month = Dates.startOfMonth(DateTime.now());
  DateTime _selected = Dates.today();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () =>
                    setState(() => _month = Dates.addMonths(_month, -1)),
                icon: const Icon(AppIcons.chevronLeft, size: 17),
                tooltip: 'Previous month',
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _month = Dates.addMonths(_month, 1)),
                icon: const Icon(AppIcons.chevronRight, size: 17),
                tooltip: 'Next month',
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                Dates.monthYear(_month),
                style: context.textStyles.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: MonthGrid(
            month: _month,
            tasks: widget.tasks,
            selectedDay: _selected,
            weekStartsOn: ref.watch(
              preferencesProvider.select((UserPreferences p) => p.weekStartsOn),
            ),
            onSelectDay: (DateTime day) => setState(() => _selected = day),
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
            onCreateOn: (DateTime day) =>
                openTaskComposer(context, ref, dueDate: day),
          ),
        ),
      ],
    );
  }
}

class _ProjectActivity extends ConsumerWidget {
  const _ProjectActivity({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Activity>> async = ref.watch(
      workspaceActivityProvider,
    );
    final List<Activity> activities = (async.value ?? const <Activity>[])
        .where((Activity a) => a.projectId == projectId)
        .toList(growable: false);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.xl,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ShellMetrics.maxReadingWidth,
          ),
          child: ActivityFeed(
            activities: activities,
            isLoading: async.isLoading,
            showTaskTitles: true,
          ),
        ),
      ],
    );
  }
}
