import 'package:kairo/domain/entities/enums.dart';
import 'package:meta/meta.dart';

/// One day's worth of counters. The unit every chart in the app is built from.
@immutable
class DailyMetric {
  const DailyMetric({
    required this.day,
    required this.created,
    required this.completed,
    required this.overdue,
    required this.focusMinutes,
  });

  final DateTime day;
  final int created;
  final int completed;
  final int overdue;
  final int focusMinutes;
}

/// A single sentence derived from real numbers in the workspace.
///
/// Insights are computed, never invented: each one carries the figures it was
/// built from so the copy can never drift from the data.
@immutable
class Insight {
  const Insight({required this.id, required this.message, required this.tone});

  final String id;
  final String message;
  final InsightTone tone;
}

enum InsightTone { positive, neutral, warning }

/// Everything the dashboard and analytics screens need, computed in one pass by
/// `AnalyticsRepository` so the two screens can never disagree.
@immutable
class ProductivitySnapshot {
  const ProductivitySnapshot({
    required this.rangeStart,
    required this.rangeEnd,
    required this.daily,
    required this.totalTasks,
    required this.completedTasks,
    required this.remainingTasks,
    required this.overdueTasks,
    required this.dueTodayTasks,
    required this.completedThisWeek,
    required this.completedPreviousWeek,
    required this.byPriority,
    required this.byProject,
    required this.byStatus,
    required this.averageCompletion,
    required this.focusMinutes,
    required this.busiestWeekday,
    required this.insights,
  });

  static final ProductivitySnapshot empty = ProductivitySnapshot(
    rangeStart: DateTime.now(),
    rangeEnd: DateTime.now(),
    daily: const <DailyMetric>[],
    totalTasks: 0,
    completedTasks: 0,
    remainingTasks: 0,
    overdueTasks: 0,
    dueTodayTasks: 0,
    completedThisWeek: 0,
    completedPreviousWeek: 0,
    byPriority: const <TaskPriority, int>{},
    byProject: const <String, int>{},
    byStatus: const <TaskStatus, int>{},
    averageCompletion: Duration.zero,
    focusMinutes: 0,
    busiestWeekday: null,
    insights: const <Insight>[],
  );

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<DailyMetric> daily;

  final int totalTasks;
  final int completedTasks;
  final int remainingTasks;
  final int overdueTasks;
  final int dueTodayTasks;
  final int completedThisWeek;
  final int completedPreviousWeek;

  final Map<TaskPriority, int> byPriority;

  /// Project id to completed-task count, ordered most-completed first.
  final Map<String, int> byProject;

  final Map<TaskStatus, int> byStatus;
  final Duration averageCompletion;
  final int focusMinutes;

  /// [DateTime.monday]…[DateTime.sunday], or null when there is no data.
  final int? busiestWeekday;

  final List<Insight> insights;

  double get completionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  double get overdueRate =>
      remainingTasks == 0 ? 0 : overdueTasks / remainingTasks;

  /// Week-over-week change in completed tasks, as a signed fraction.
  double? get weekOverWeekChange {
    if (completedPreviousWeek == 0) return null;
    return (completedThisWeek - completedPreviousWeek) / completedPreviousWeek;
  }

  /// A 0–100 headline number.
  ///
  /// Deliberately transparent rather than magic: 55% of it is how much of the
  /// workload is finished, 30% is how little of the remaining work is overdue,
  /// and 15% is whether any focused work happened this week. The weights live
  /// here so the number can be explained in the UI.
  int get productivityScore {
    if (totalTasks == 0) return 0;
    final double completion = completionRate.clamp(0, 1);
    final double punctuality = (1 - overdueRate).clamp(0, 1);
    final double focus = (focusMinutes / 300).clamp(0, 1);
    final double raw = completion * 0.55 + punctuality * 0.30 + focus * 0.15;
    return (raw * 100).round().clamp(0, 100);
  }
}
