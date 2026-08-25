import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/adaptive_grid.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/charts/bar_donut_charts.dart';
import 'package:kairo/core/widgets/charts/chart_core.dart';
import 'package:kairo/core/widgets/charts/line_area_chart.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/services/project_stats_calculator.dart';
import 'package:kairo/features/dashboard/application/dashboard_data.dart';
import 'package:kairo/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/activity_feed.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The home screen.
///
/// Reading order is deliberate: the score answers "how am I doing", the metric
/// row answers "what is the shape of the work", then today's tasks and
/// deadlines answer "what do I do next". Charts and activity sit below the
/// fold because they are context, not instructions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProductivitySnapshot> snapshotAsync = ref.watch(
      snapshotProvider,
    );
    final User? user = ref.watch(currentUserValueProvider);
    final AppL10n l10n = context.l10n;

    final int hour = DateTime.now().hour;
    final String name = user?.firstName ?? l10n.commonYou;
    final String greeting = hour < 12
        ? l10n.dashboardGreetingMorning(name)
        : (hour < 18
              ? l10n.dashboardGreetingAfternoon(name)
              : l10n.dashboardGreetingEvening(name));

    return ShellPage(
      title: greeting,
      subtitle:
          '${Dates.weekdayLong(DateTime.now())} · '
          '${Dates.dayMonthYear(DateTime.now())}',
      actions: const <Widget>[CreateTaskAction()],
      padded: false,
      child: snapshotAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (Object error, _) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(snapshotProvider),
        ),
        data: (ProductivitySnapshot snapshot) =>
            _DashboardBody(snapshot: snapshot),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.snapshot});

  final ProductivitySnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final ScreenSize size = context.breakpoint;
    final List<Task> allTasks =
        ref.watch(tasksProvider).value ?? const <Task>[];
    final List<Project> projects =
        ref.watch(projectsProvider).value ?? const <Project>[];
    final List<Activity> activity =
        ref.watch(workspaceActivityProvider).value ?? const <Activity>[];

    // Filtering, sorting and mapping happen in `dashboardDataProvider`, not
    // here: this widget rebuilds on every breakpoint change, and re-sorting
    // every task in the workspace while a window is being dragged is the kind
    // of work that shows up as dropped frames.
    final DashboardData data = ref.watch(dashboardDataProvider);
    final List<Task> dueToday = data.dueToday;
    final List<Task> upcoming = data.upcoming;
    final List<Task> recentlyUpdated = data.recentlyUpdated;
    final List<double> completedTrend = data.completedTrend;

    final int columns = switch (size) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      _ => 4,
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.lg,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        ProductivityHero(snapshot: snapshot),
        const SizedBox(height: Spacing.lg),

        AdaptiveCardGrid(
          columns: columns,
          children: <Widget>[
            MetricTile(
              index: 0,
              label: l10n.dashboardCompleted,
              value: snapshot.completedTasks,
              icon: AppIcons.complete,
              color: context.colors.success,
              caption: l10n.dashboardThisWeek.toLowerCase(),
              trend: completedTrend,
            ),
            MetricTile(
              index: 1,
              label: l10n.dashboardRemaining,
              value: snapshot.remainingTasks,
              icon: AppIcons.tasks,
              color: context.colors.brand,
              caption: '${snapshot.dueTodayTasks} due today',
              onTap: () => context.go(Routes.tasks),
            ),
            MetricTile(
              index: 2,
              label: l10n.dashboardOverdue,
              value: snapshot.overdueTasks,
              icon: AppIcons.overdue,
              color: context.colors.danger,
              caption: snapshot.overdueTasks == 0
                  ? 'All on track'
                  : 'Needs attention',
              onTap: () => context.go(Routes.tasks),
            ),
            MetricTile(
              index: 3,
              label: l10n.analyticsFocusTime,
              value: snapshot.focusMinutes,
              icon: AppIcons.focus,
              color: context.colors.accent,
              caption: 'minutes this week',
              onTap: () => context.go(Routes.focus),
            ),
          ],
        ),

        const SizedBox(height: Spacing.lg),
        _ResponsiveRow(
          size: size,
          left: DashboardPanel(
            index: 4,
            title: l10n.dashboardTodaysFocus,
            icon: AppIcons.target,
            count: dueToday.length,
            actionLabel: l10n.actionViewAll,
            onAction: () => context.go(Routes.tasks),
            child: dueToday.isEmpty
                ? _MiniEmpty(
                    icon: AppIcons.complete,
                    message: 'Nothing due today. Pull something forward?',
                    actionLabel: l10n.actionCreateTask,
                    onAction: () =>
                        openTaskComposer(context, ref, dueDate: DateTime.now()),
                  )
                : Column(
                    children: <Widget>[
                      for (int i = 0; i < dueToday.length && i < 6; i++)
                        DashboardTaskRow(
                          index: i,
                          task: dueToday[i],
                          showDue: false,
                          onOpen: () => openTaskDetail(context, dueToday[i].id),
                        ),
                    ],
                  ),
          ),
          right: DashboardPanel(
            index: 5,
            title: l10n.dashboardUpcoming,
            icon: AppIcons.dueDate,
            count: upcoming.length,
            child: upcoming.isEmpty
                ? const _MiniEmpty(
                    icon: AppIcons.calendar,
                    message: 'No deadlines in the next two weeks.',
                  )
                : Column(
                    children: <Widget>[
                      for (int i = 0; i < upcoming.length; i++)
                        DashboardTaskRow(
                          index: i,
                          task: upcoming[i],
                          onOpen: () => openTaskDetail(context, upcoming[i].id),
                        ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        _ResponsiveRow(
          size: size,
          leftFlex: 3,
          rightFlex: 2,
          left: Entrance(
            index: 6,
            child: ChartPanel(
              title: l10n.dashboardTrend,
              subtitle: 'Tasks completed and created over the last 30 days',
              height: 200,
              legend: ChartLegend(
                entries: <({String label, Color color, String? value})>[
                  (
                    label: l10n.dashboardCompleted,
                    color: context.colors.chartSeries[0],
                    value: '${snapshot.completedTasks}',
                  ),
                  (
                    label: 'Created',
                    color: context.colors.chartSeries[1],
                    value: null,
                  ),
                ],
              ),
              child: LineAreaChart(
                series: <ChartSeries>[
                  ChartSeries(
                    name: l10n.dashboardCompleted,
                    color: context.colors.chartSeries[0],
                    points: <ChartPoint>[
                      for (final DailyMetric m in snapshot.daily)
                        ChartPoint(
                          label: Dates.dayMonth(m.day),
                          value: m.completed.toDouble(),
                          meta: Dates.dayMonthYear(m.day),
                        ),
                    ],
                  ),
                  ChartSeries(
                    name: 'Created',
                    color: context.colors.chartSeries[1],
                    filled: false,
                    points: <ChartPoint>[
                      for (final DailyMetric m in snapshot.daily)
                        ChartPoint(
                          label: Dates.dayMonth(m.day),
                          value: m.created.toDouble(),
                          meta: Dates.dayMonthYear(m.day),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          right: Entrance(
            index: 7,
            child: ChartPanel(
              title: l10n.dashboardWorkload,
              subtitle: 'Completed per day, last 7 days',
              height: 200,
              child: AppBarChart(
                color: context.colors.chartSeries[0],
                points: <ChartPoint>[
                  for (final DailyMetric m in snapshot.daily.skip(
                    snapshot.daily.length > 7 ? snapshot.daily.length - 7 : 0,
                  ))
                    ChartPoint(
                      label: Dates.weekdayShort(m.day),
                      value: m.completed.toDouble(),
                      meta: Dates.dayMonthYear(m.day),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        Entrance(
          index: 8,
          child: DashboardPanel(
            title: l10n.dashboardActiveProjects,
            icon: AppIcons.projects,
            count: projects.length,
            actionLabel: l10n.actionViewAll,
            onAction: () => context.go(Routes.projects),
            child: projects.isEmpty
                ? _MiniEmpty(
                    icon: AppIcons.projects,
                    message: l10n.emptyProjectsBody,
                    actionLabel: l10n.actionCreateProject,
                    onAction: () => context.go(Routes.projects),
                  )
                : AdaptiveCardGrid(
                    columns: columns == 1 ? 1 : (columns == 2 ? 2 : 3),
                    children: <Widget>[
                      for (int i = 0; i < projects.length && i < 6; i++)
                        ProjectProgressCard(
                          index: i,
                          project: projects[i],
                          stats: ProjectStatsCalculator.forProject(
                            projects[i].id,
                            allTasks,
                          ),
                          onOpen: () =>
                              context.go(Routes.project(projects[i].id)),
                        ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        _ResponsiveRow(
          size: size,
          left: DashboardPanel(
            index: 9,
            title: l10n.dashboardRecentlyUpdated,
            icon: AppIcons.retry,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < recentlyUpdated.length && i < 6; i++)
                  DashboardTaskRow(
                    index: i,
                    task: recentlyUpdated[i],
                    onOpen: () =>
                        openTaskDetail(context, recentlyUpdated[i].id),
                  ),
              ],
            ),
          ),
          right: DashboardPanel(
            index: 10,
            title: l10n.fieldActivity,
            icon: AppIcons.activity,
            child: ActivityFeed(
              activities: activity,
              showTaskTitles: true,
              limit: 6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Two panels side by side on wide screens, stacked below.
class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({
    required this.size,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final ScreenSize size;
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    if (size.index <= ScreenSize.medium.index) {
      return Column(
        children: <Widget>[
          left,
          const SizedBox(height: Spacing.lg),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: Spacing.lg),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 20, color: colors.inkFaint),
          const SizedBox(height: Spacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.inkMuted,
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.lg,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: Radii.brXl,
            border: Border.all(color: context.colors.hairline),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          children: <Widget>[
            for (int i = 0; i < 4; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Spacing.md),
              const Expanded(child: MetricCardSkeleton()),
            ],
          ],
        ),
        const SizedBox(height: Spacing.lg),
        const ChartSkeleton(),
      ],
    );
  }
}
