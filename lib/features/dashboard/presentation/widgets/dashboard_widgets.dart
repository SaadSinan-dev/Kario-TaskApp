import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/charts/line_area_chart.dart';
import 'package:kairo/core/widgets/completion_check.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';

/// A headline number with a trend sparkline.
///
/// Deliberately not all identical: the hero score card is much larger, and the
/// four metric tiles are compact. A dashboard where every card has the same
/// weight tells the reader nothing about what matters.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.trend,
    this.onTap,
    this.index = 0,
    super.key,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? caption;
  final List<double>? trend;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Entrance(
      index: index,
      child: AppCard(
        onTap: onTap,
        hoverable: onTap != null,
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: colors.isDark ? 0.20 : 0.12),
                    borderRadius: Radii.brSm,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            AnimatedCounter(
              value: value,
              style: AppTypography.numeric.copyWith(
                fontSize: 30,
                height: 1.05,
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ),
            if (trend != null && trend!.length > 1) ...<Widget>[
              const SizedBox(height: Spacing.md),
              Sparkline(values: trend!, color: color, height: 28),
            ],
          ],
        ),
      ),
    );
  }
}

/// The hero panel: productivity score, its inputs, and the week's insights.
class ProductivityHero extends StatelessWidget {
  const ProductivityHero({required this.snapshot, super.key});

  final ProductivitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool compact = context.isCompact;

    final Widget dial = ScoreDial(
      score: snapshot.productivityScore,
      size: compact ? 150 : 178,
      label: context.l10n.dashboardProductivityScore,
      caption: 'this week',
    );

    final Widget breakdown = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ScoreFactor(
          label: 'Workload finished',
          value: snapshot.completionRate,
          color: colors.brand,
          detail: '${snapshot.completedTasks} of ${snapshot.totalTasks} tasks',
        ),
        const SizedBox(height: Spacing.md),
        _ScoreFactor(
          label: 'On time',
          value: 1 - snapshot.overdueRate,
          color: colors.success,
          detail: snapshot.overdueTasks == 0
              ? 'Nothing overdue'
              : '${snapshot.overdueTasks} overdue',
        ),
        const SizedBox(height: Spacing.md),
        _ScoreFactor(
          label: 'Focused time',
          value: (snapshot.focusMinutes / 300).clamp(0, 1),
          color: colors.accent,
          detail: Dates.duration(snapshot.focusMinutes),
        ),
      ],
    );

    return Entrance(
      child: Container(
        padding: EdgeInsets.all(compact ? Spacing.lg : Spacing.xxl),
        decoration: BoxDecoration(
          gradient: colors.sheenGradient,
          color: colors.surface,
          borderRadius: Radii.brXl,
          border: Border.all(color: colors.hairline),
          boxShadow: Shadows.sm(colors.isDark),
        ),
        child: compact
            ? Column(
                children: <Widget>[
                  dial,
                  const SizedBox(height: Spacing.xl),
                  breakdown,
                  if (snapshot.insights.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xl),
                    _InsightList(insights: snapshot.insights),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  dial,
                  const SizedBox(width: Spacing.xxxl),
                  Expanded(child: breakdown),
                  if (snapshot.insights.isNotEmpty) ...<Widget>[
                    const SizedBox(width: Spacing.xxxl),
                    Expanded(
                      flex: 2,
                      child: _InsightList(insights: snapshot.insights),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// One contributor to the score, shown with its weight made visible.
class _ScoreFactor extends StatelessWidget {
  const _ScoreFactor({
    required this.label,
    required this.value,
    required this.color,
    required this.detail,
  });

  final String label;
  final double value;
  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelMedium?.copyWith(
                  color: colors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              '${(value * 100).round()}%',
              style: AppTypography.numeric.copyWith(
                fontSize: 12,
                color: colors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AppLinearProgress(value: value, height: 5, color: color),
        const SizedBox(height: 3),
        Text(
          detail,
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.inkFaint,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _InsightList extends StatelessWidget {
  const _InsightList({required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppEyebrow(context.l10n.dashboardInsights),
        const SizedBox(height: Spacing.sm),
        for (int i = 0; i < insights.length; i++)
          Entrance(
            index: i + 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      switch (insights[i].tone) {
                        InsightTone.positive => AppIcons.brandSpark,
                        InsightTone.warning => AppIcons.warning,
                        InsightTone.neutral => AppIcons.info,
                      },
                      size: 13,
                      color: switch (insights[i].tone) {
                        InsightTone.positive => colors.success,
                        InsightTone.warning => colors.warning,
                        InsightTone.neutral => colors.brand,
                      },
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      insights[i].message,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.inkSoft,
                        height: 1.5,
                      ),
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

/// Compact task row used by the dashboard's "today" and "upcoming" panels.
class DashboardTaskRow extends ConsumerWidget {
  const DashboardTaskRow({
    required this.task,
    required this.onOpen,
    this.showDue = true,
    this.index = 0,
    super.key,
  });

  final Task task;
  final VoidCallback onOpen;
  final bool showDue;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Project? project = task.projectId == null
        ? null
        : projects[task.projectId!];

    return Entrance(
      index: index,
      offset: 6,
      child: InkWell(
        onTap: onOpen,
        borderRadius: Radii.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: <Widget>[
              CompletionCheckbox(
                isCompleted: task.isDone,
                size: 16,
                onChanged: (bool value) => ref
                    .read(taskActionsProvider)
                    .setCompleted(
                      l10n: context.l10n,
                      task: task,
                      completed: value,
                    ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: task.isDone ? colors.inkFaint : colors.ink,
                        fontWeight: FontWeight.w500,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (project != null)
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              PriorityPill(priority: task.priority, showLabel: false),
              if (showDue && task.dueDate != null) ...<Widget>[
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  width: 62,
                  child: Text(
                    Dates.dueLabel(task.dueDate, context.l10n),
                    textAlign: TextAlign.end,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: task.isOverdue ? colors.danger : colors.inkFaint,
                      fontWeight: task.isOverdue
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 10.5,
                    ),
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

/// Project progress card used on the dashboard and the projects grid.
class ProjectProgressCard extends StatelessWidget {
  const ProjectProgressCard({
    required this.project,
    required this.stats,
    required this.onOpen,
    this.index = 0,
    super.key,
  });

  final Project project;
  final ProjectStats stats;
  final VoidCallback onOpen;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = Color(project.colorValue);

    return Entrance(
      index: index,
      child: AppCard(
        onTap: onOpen,
        hoverable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                EmojiTile(
                  emoji: project.iconEmoji,
                  colorValue: project.colorValue,
                  size: 32,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        context.l10n.projectsTaskCount(stats.total),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (project.isFavorite)
                  Icon(AppIcons.favorites, size: 14, color: colors.warning),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: <Widget>[
                Text(
                  '${(stats.progress * 100).round()}%',
                  style: AppTypography.numeric.copyWith(
                    fontSize: 13,
                    color: colors.ink,
                  ),
                ),
                const Spacer(),
                if (stats.overdue > 0)
                  AppBadge(
                    label: '${stats.overdue} overdue',
                    tone: BadgeTone.danger,
                    compact: true,
                  )
                else if (project.dueDate != null)
                  Text(
                    Dates.dueLabel(project.dueDate, context.l10n),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm - 2),
            AppLinearProgress(value: stats.progress, height: 6, color: accent),
          ],
        ),
      ),
    );
  }
}

/// Panel wrapper used by every dashboard section, so headers, padding and the
/// "view all" affordance are consistent.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.title,
    required this.child,
    this.icon,
    this.count,
    this.actionLabel,
    this.onAction,
    this.index = 0,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      index: index,
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppSectionHeader(
              title: title,
              icon: icon,
              count: count,
              trailing: actionLabel == null
                  ? null
                  : TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
            const SizedBox(height: Spacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
