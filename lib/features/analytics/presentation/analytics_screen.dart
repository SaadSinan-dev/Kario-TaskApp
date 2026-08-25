import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/responsive/adaptive_grid.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/charts/bar_donut_charts.dart';
import 'package:kairo/core/widgets/charts/chart_core.dart';
import 'package:kairo/core/widgets/charts/line_area_chart.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Productivity insights.
///
/// Same snapshot as the dashboard, examined rather than summarised: rates,
/// distributions and a focus heatmap. Nothing here is invented — every figure
/// is derived from the workspace's own tasks and focus sessions.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AsyncValue<ProductivitySnapshot> async = ref.watch(snapshotProvider);

    return ShellPage(
      title: l10n.analyticsTitle,
      subtitle: 'Everything below is computed from this workspace',
      padded: false,
      toolbar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.hairline)),
        ),
        child: Row(
          children: <Widget>[
            // Expanded so the control has a width to divide: a bare child of a
            // Row is handed unbounded constraints, which `expand` cannot use.
            Expanded(
              child: AppSegmentedControl<int>(
                value: _rangeDays,
                dense: true,
                // Fills the row on a phone instead of taking its natural width
                // and spilling out of it.
                expand: context.breakpoint.isCompact,
                options: <SegmentOption<int>>[
                  SegmentOption<int>(value: 7, label: l10n.analyticsRangeWeek),
                  SegmentOption<int>(
                    value: 30,
                    label: l10n.analyticsRangeMonth,
                  ),
                  SegmentOption<int>(
                    value: 90,
                    label: l10n.analyticsRangeQuarter,
                  ),
                ],
                onChanged: (int value) => setState(() => _rangeDays = value),
              ),
            ),
          ],
        ),
      ),
      child: async.when(
        loading: () => ListView(
          padding: EdgeInsets.all(context.gutter),
          children: const <Widget>[
            ChartSkeleton(),
            SizedBox(height: Spacing.lg),
            ChartSkeleton(),
          ],
        ),
        error: (Object error, _) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(snapshotProvider),
        ),
        data: (ProductivitySnapshot snapshot) =>
            _Body(snapshot: snapshot, rangeDays: _rangeDays),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.snapshot, required this.rangeDays});

  final ProductivitySnapshot snapshot;
  final int rangeDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final colors = context.colors;
    final ScreenSize size = context.breakpoint;
    final bool wide = size.index >= ScreenSize.expanded.index;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);

    final List<DailyMetric> daily = snapshot.daily
        .skip(
          snapshot.daily.length > rangeDays
              ? snapshot.daily.length - rangeDays
              : 0,
        )
        .toList(growable: false);

    final int rangeCompleted = daily.fold<int>(
      0,
      (int sum, DailyMetric m) => sum + m.completed,
    );
    final int rangeFocus = daily.fold<int>(
      0,
      (int sum, DailyMetric m) => sum + m.focusMinutes,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.lg,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        AdaptiveCardGrid(
          columns: switch (size) {
            ScreenSize.compact => 2,
            ScreenSize.medium => 2,
            _ => 4,
          },
          children: <Widget>[
            _RateTile(
              index: 0,
              label: l10n.analyticsCompletionRate,
              percent: snapshot.completionRate,
              color: colors.success,
              caption: '${snapshot.completedTasks} completed',
            ),
            _RateTile(
              index: 1,
              label: l10n.analyticsOverdueRate,
              percent: snapshot.overdueRate,
              color: colors.danger,
              caption: '${snapshot.overdueTasks} overdue now',
              invert: true,
            ),
            MetricTile(
              index: 2,
              label: l10n.analyticsAvgCompletion,
              value: snapshot.averageCompletion.inHours,
              icon: AppIcons.estimate,
              color: colors.brand,
              caption: 'hours from created to done',
            ),
            MetricTile(
              index: 3,
              label: l10n.analyticsFocusTime,
              value: rangeFocus,
              icon: AppIcons.focus,
              color: colors.accent,
              caption: 'minutes in range',
            ),
          ],
        ),

        const SizedBox(height: Spacing.lg),
        Entrance(
          index: 4,
          child: ChartPanel(
            title: l10n.analyticsWeeklyProductivity,
            subtitle:
                '$rangeCompleted tasks completed over the last $rangeDays days',
            height: 240,
            legend: ChartLegend(
              entries: <({String label, Color color, String? value})>[
                (
                  label: l10n.dashboardCompleted,
                  color: colors.chartSeries[0],
                  value: '$rangeCompleted',
                ),
                (label: 'Created', color: colors.chartSeries[1], value: null),
                (
                  label: l10n.analyticsFocusTime,
                  color: colors.chartSeries[2],
                  value: Dates.duration(rangeFocus),
                ),
              ],
            ),
            child: LineAreaChart(
              maxLabels: rangeDays > 40 ? 6 : 8,
              series: <ChartSeries>[
                ChartSeries(
                  name: l10n.dashboardCompleted,
                  color: colors.chartSeries[0],
                  points: <ChartPoint>[
                    for (final DailyMetric m in daily)
                      ChartPoint(
                        label: Dates.dayMonth(m.day),
                        value: m.completed.toDouble(),
                        meta: Dates.dayMonthYear(m.day),
                      ),
                  ],
                ),
                ChartSeries(
                  name: 'Created',
                  color: colors.chartSeries[1],
                  filled: false,
                  points: <ChartPoint>[
                    for (final DailyMetric m in daily)
                      ChartPoint(
                        label: Dates.dayMonth(m.day),
                        value: m.created.toDouble(),
                        meta: Dates.dayMonthYear(m.day),
                      ),
                  ],
                ),
                ChartSeries(
                  name: l10n.analyticsFocusTime,
                  color: colors.chartSeries[2],
                  filled: false,
                  points: <ChartPoint>[
                    for (final DailyMetric m in daily)
                      ChartPoint(
                        label: Dates.dayMonth(m.day),
                        // Scaled to the task axis so three series share one
                        // grid without a second axis to misread.
                        value: m.focusMinutes / 25,
                        meta: Dates.dayMonthYear(m.day),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        _Split(
          wide: wide,
          left: Entrance(
            index: 5,
            child: ChartPanel(
              title: l10n.analyticsTasksByPriority,
              subtitle: 'Open and completed work by urgency',
              height: 190,
              legend: ChartLegend(
                entries: <({String label, Color color, String? value})>[
                  for (final TaskPriority priority in TaskPriority.values)
                    (
                      label: priority.label(l10n),
                      color: priority.color(colors),
                      value: '${snapshot.byPriority[priority] ?? 0}',
                    ),
                ],
              ),
              child: DonutChart(
                centerValue: '${snapshot.totalTasks}',
                centerLabel: 'tasks',
                slices: <DonutSlice>[
                  for (final TaskPriority priority in TaskPriority.values)
                    if ((snapshot.byPriority[priority] ?? 0) > 0)
                      DonutSlice(
                        label: priority.label(l10n),
                        value: (snapshot.byPriority[priority] ?? 0).toDouble(),
                        color: priority.color(colors),
                      ),
                ],
              ),
            ),
          ),
          right: Entrance(
            index: 6,
            child: ChartPanel(
              title: l10n.analyticsTasksByProject,
              subtitle: 'Completed work, most productive project first',
              height: 190,
              child: HorizontalBarList(
                entries: <({String label, double value, Color color})>[
                  for (final MapEntry<String, int> entry
                      in snapshot.byProject.entries)
                    (
                      label: entry.key == '__none__'
                          ? l10n.fieldNoProject
                          : projects[entry.key]?.name ?? l10n.fieldNoProject,
                      value: entry.value.toDouble(),
                      color: entry.key == '__none__'
                          ? colors.inkFaint
                          : Color(
                              projects[entry.key]?.colorValue ??
                                  colors.brand.toARGB32(),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        _Split(
          wide: wide,
          left: Entrance(
            index: 7,
            child: ChartPanel(
              title: l10n.analyticsWorkload,
              subtitle: 'Where open work currently sits',
              height: 190,
              child: HorizontalBarList(
                entries: <({String label, double value, Color color})>[
                  for (final TaskStatus status in TaskStatus.values)
                    (
                      label: status.label(l10n),
                      value: (snapshot.byStatus[status] ?? 0).toDouble(),
                      color: status.color(colors),
                    ),
                ],
              ),
            ),
          ),
          right: Entrance(
            index: 8,
            child: ChartPanel(
              title: 'Focus rhythm',
              subtitle: 'Minutes of focused work per day',
              height: 190,
              child: FocusHeatmap(daily: daily),
            ),
          ),
        ),

        const SizedBox(height: Spacing.lg),
        Entrance(
          index: 9,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSectionHeader(
                  title: l10n.dashboardInsights,
                  icon: AppIcons.brandSpark,
                  subtitle: 'Generated from the numbers above',
                ),
                const SizedBox(height: Spacing.md),
                if (snapshot.insights.isEmpty)
                  Text(
                    'Not enough activity yet to say anything useful.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  )
                else
                  for (final Insight insight in snapshot.insights)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(
                              switch (insight.tone) {
                                InsightTone.positive => AppIcons.brandSpark,
                                InsightTone.warning => AppIcons.warning,
                                InsightTone.neutral => AppIcons.info,
                              },
                              size: 14,
                              color: switch (insight.tone) {
                                InsightTone.positive => colors.success,
                                InsightTone.warning => colors.warning,
                                InsightTone.neutral => colors.brand,
                              },
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              insight.message,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: colors.inkSoft,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Split extends StatelessWidget {
  const _Split({required this.wide, required this.left, required this.right});

  final bool wide;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
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
        Expanded(child: left),
        const SizedBox(width: Spacing.lg),
        Expanded(child: right),
      ],
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.label,
    required this.percent,
    required this.color,
    required this.caption,
    this.invert = false,
    this.index = 0,
  });

  final String label;
  final double percent;
  final Color color;
  final String caption;

  /// True when a *lower* number is the good outcome.
  final bool invert;

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Entrance(
      index: index,
      child: AppCard(
        child: Row(
          children: <Widget>[
            ProgressRing(
              value: percent,
              size: 52,
              strokeWidth: 5,
              color: color,
              child: Text(
                '${(percent * 100).round()}',
                style: AppTypography.numeric.copyWith(
                  fontSize: 14,
                  color: colors.ink,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    maxLines: 2,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A contribution-graph style heatmap of focused minutes.
class FocusHeatmap extends StatelessWidget {
  const FocusHeatmap({required this.daily, super.key});

  final List<DailyMetric> daily;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (daily.isEmpty) return const SizedBox.shrink();

    final int max = daily
        .map((DailyMetric m) => m.focusMinutes)
        .fold<int>(0, (int a, int b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int rows = 7;
        final int columns = (daily.length / rows).ceil();
        final double cell =
            ((constraints.maxWidth - (columns - 1) * 4) / columns).clamp(
              8.0,
              22.0,
            );

        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < columns; column++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: <Widget>[
                      for (int row = 0; row < rows; row++)
                        () {
                          final int index = column * rows + row;
                          if (index >= daily.length) {
                            return SizedBox(height: cell + 4, width: cell);
                          }
                          final DailyMetric metric = daily[index];
                          final double intensity = max == 0
                              ? 0
                              : metric.focusMinutes / max;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Tooltip(
                              message:
                                  '${Dates.dayMonth(metric.day)} · '
                                  '${Dates.duration(metric.focusMinutes)}',
                              child: Container(
                                width: cell,
                                height: cell,
                                decoration: BoxDecoration(
                                  color: intensity == 0
                                      ? colors.surfaceSunken
                                      : Color.lerp(
                                          colors.brand.withValues(alpha: 0.18),
                                          colors.brand,
                                          intensity,
                                        ),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: colors.hairline),
                                ),
                              ),
                            ),
                          );
                        }(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
