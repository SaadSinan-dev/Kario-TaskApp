import 'dart:async';

import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Computes one [ProductivitySnapshot] per change to the task set.
///
/// The dashboard and the analytics screen both read this single value, which is
/// how they stay in agreement — and why the numbers only get recomputed when
/// the underlying data actually moves rather than on every rebuild.
class LocalAnalyticsRepository implements AnalyticsRepository {
  LocalAnalyticsRepository({required KairoDatabase database}) : _db = database;

  final KairoDatabase _db;

  @override
  Stream<ProductivitySnapshot> watchSnapshot(
    String workspaceId, {
    int days = 30,
  }) async* {
    await for (final List<Task> _ in _db.tasks.stream) {
      yield compute(
        tasks: _db.tasks.value
            .where((Task t) => t.workspaceId == workspaceId)
            .toList(growable: false),
        sessions: _db.focusSessions.value
            .where((FocusSession s) => s.workspaceId == workspaceId)
            .toList(growable: false),
        projects: _db.projects.value
            .where((Project p) => p.workspaceId == workspaceId)
            .toList(growable: false),
        days: days,
      );
    }
  }

  /// Pure computation, exposed statically so it can be unit-tested against a
  /// fixed task list without any storage.
  static ProductivitySnapshot compute({
    required List<Task> tasks,
    required List<FocusSession> sessions,
    required List<Project> projects,
    int days = 30,
  }) {
    final DateTime today = Dates.today();
    final DateTime rangeStart = today.subtract(Duration(days: days - 1));
    final List<Task> live = tasks
        .where((Task t) => !t.isArchived)
        .toList(growable: false);

    if (live.isEmpty) {
      return ProductivitySnapshot(
        rangeStart: rangeStart,
        rangeEnd: today,
        daily: _emptyDaily(rangeStart, days),
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
    }

    // --- Headline counters --------------------------------------------------
    int completed = 0, overdue = 0, dueToday = 0;
    final Map<TaskPriority, int> byPriority = <TaskPriority, int>{};
    final Map<TaskStatus, int> byStatus = <TaskStatus, int>{};
    final Map<String, int> completedByProject = <String, int>{};
    Duration totalCompletionTime = Duration.zero;
    int completionSamples = 0;

    for (final Task task in live) {
      byStatus[task.status] = (byStatus[task.status] ?? 0) + 1;
      byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;

      if (task.isDone) {
        completed++;
        final String projectKey = task.projectId ?? '__none__';
        completedByProject[projectKey] =
            (completedByProject[projectKey] ?? 0) + 1;
        final Duration? elapsed = task.timeToComplete;
        if (elapsed != null && elapsed > Duration.zero) {
          totalCompletionTime += elapsed;
          completionSamples++;
        }
      } else {
        if (task.isOverdue) overdue++;
        if (Dates.isSameDay(task.dueDate, today)) dueToday++;
      }
    }

    // --- Daily series -------------------------------------------------------
    final Map<String, _DayAccumulator> byDay = <String, _DayAccumulator>{
      for (int i = 0; i < days; i++)
        _key(rangeStart.add(Duration(days: i))): _DayAccumulator(),
    };

    for (final Task task in live) {
      final String createdKey = _key(task.createdAt);
      byDay[createdKey]?.created++;
      final DateTime? completedAt = task.completedAt;
      if (completedAt != null) byDay[_key(completedAt)]?.completed++;
      if (task.isOverdue && task.dueDate != null) {
        byDay[_key(task.dueDate!)]?.overdue++;
      }
    }
    for (final FocusSession session in sessions) {
      if (session.phase != FocusPhase.focus) continue;
      byDay[_key(session.startedAt)]?.focusMinutes += session.actualMinutes;
    }

    final List<DailyMetric> daily = <DailyMetric>[
      for (int i = 0; i < days; i++)
        () {
          final DateTime day = rangeStart.add(Duration(days: i));
          final _DayAccumulator acc = byDay[_key(day)] ?? _DayAccumulator();
          return DailyMetric(
            day: day,
            created: acc.created,
            completed: acc.completed,
            overdue: acc.overdue,
            focusMinutes: acc.focusMinutes,
          );
        }(),
    ];

    // --- Week-over-week -----------------------------------------------------
    final DateTime weekStart = today.subtract(const Duration(days: 6));
    final DateTime previousWeekStart = today.subtract(const Duration(days: 13));
    int completedThisWeek = 0, completedPreviousWeek = 0;
    for (final DailyMetric metric in daily) {
      if (!metric.day.isBefore(weekStart)) {
        completedThisWeek += metric.completed;
      } else if (!metric.day.isBefore(previousWeekStart)) {
        completedPreviousWeek += metric.completed;
      }
    }

    // --- Busiest weekday ----------------------------------------------------
    final Map<int, int> perWeekday = <int, int>{};
    for (final DailyMetric metric in daily) {
      if (metric.completed == 0) continue;
      perWeekday[metric.day.weekday] =
          (perWeekday[metric.day.weekday] ?? 0) + metric.completed;
    }
    int? busiestWeekday;
    int busiestCount = 0;
    perWeekday.forEach((int weekday, int count) {
      if (count > busiestCount) {
        busiestCount = count;
        busiestWeekday = weekday;
      }
    });

    final int focusMinutes = daily
        .where((DailyMetric m) => !m.day.isBefore(weekStart))
        .fold<int>(0, (int sum, DailyMetric m) => sum + m.focusMinutes);

    final Map<String, int> orderedByProject = Map<String, int>.fromEntries(
      completedByProject.entries.toList()..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      ),
    );

    final ProductivitySnapshot snapshot = ProductivitySnapshot(
      rangeStart: rangeStart,
      rangeEnd: today,
      daily: daily,
      totalTasks: live.length,
      completedTasks: completed,
      remainingTasks: live.length - completed,
      overdueTasks: overdue,
      dueTodayTasks: dueToday,
      completedThisWeek: completedThisWeek,
      completedPreviousWeek: completedPreviousWeek,
      byPriority: byPriority,
      byProject: orderedByProject,
      byStatus: byStatus,
      averageCompletion: completionSamples == 0
          ? Duration.zero
          : Duration(
              minutes: totalCompletionTime.inMinutes ~/ completionSamples,
            ),
      focusMinutes: focusMinutes,
      busiestWeekday: busiestWeekday,
      insights: const <Insight>[],
    );

    return ProductivitySnapshot(
      rangeStart: snapshot.rangeStart,
      rangeEnd: snapshot.rangeEnd,
      daily: snapshot.daily,
      totalTasks: snapshot.totalTasks,
      completedTasks: snapshot.completedTasks,
      remainingTasks: snapshot.remainingTasks,
      overdueTasks: snapshot.overdueTasks,
      dueTodayTasks: snapshot.dueTodayTasks,
      completedThisWeek: snapshot.completedThisWeek,
      completedPreviousWeek: snapshot.completedPreviousWeek,
      byPriority: snapshot.byPriority,
      byProject: snapshot.byProject,
      byStatus: snapshot.byStatus,
      averageCompletion: snapshot.averageCompletion,
      focusMinutes: snapshot.focusMinutes,
      busiestWeekday: snapshot.busiestWeekday,
      insights: _insights(snapshot, live, projects),
    );
  }

  /// Insight copy is generated from the snapshot's own numbers. Nothing here
  /// invents a claim — if the data doesn't support a sentence, it isn't shown.
  static List<Insight> _insights(
    ProductivitySnapshot snapshot,
    List<Task> tasks,
    List<Project> projects,
  ) {
    final List<Insight> insights = <Insight>[];

    final double? change = snapshot.weekOverWeekChange;
    if (change != null && change.abs() >= 0.10) {
      final int percent = (change.abs() * 100).round();
      insights.add(
        Insight(
          id: 'wow',
          message: change > 0
              ? 'You completed $percent% more tasks this week than last.'
              : 'You completed $percent% fewer tasks this week than last.',
          tone: change > 0 ? InsightTone.positive : InsightTone.warning,
        ),
      );
    }

    if (snapshot.byProject.isNotEmpty) {
      final MapEntry<String, int> top = snapshot.byProject.entries.first;
      final int totalCompleted = snapshot.completedTasks;
      if (totalCompleted > 0 && top.value / totalCompleted >= 0.3) {
        final String name = top.key == '__none__'
            ? 'tasks outside any project'
            : projects
                      .where((Project p) => p.id == top.key)
                      .firstOrNull
                      ?.name ??
                  'one project';
        final int share = (top.value / totalCompleted * 100).round();
        insights.add(
          Insight(
            id: 'top-project',
            message: '$share% of your completed work comes from $name.',
            tone: InsightTone.neutral,
          ),
        );
      }
    }

    final int? weekday = snapshot.busiestWeekday;
    if (weekday != null && snapshot.completedTasks >= 5) {
      insights.add(
        Insight(
          id: 'busiest-day',
          message:
              '${Dates.weekdayLong(DateTime(2024, 1, weekday))} is your most '
              'productive day.',
          tone: InsightTone.neutral,
        ),
      );
    }

    final int urgentSoon = tasks
        .where(
          (Task t) =>
              !t.isDone &&
              t.priority == TaskPriority.urgent &&
              t.dueDate != null &&
              Dates.daysBetween(DateTime.now(), t.dueDate!) <= 3,
        )
        .length;
    if (urgentSoon > 0) {
      insights.add(
        Insight(
          id: 'urgent-soon',
          message: urgentSoon == 1
              ? '1 urgent task is due within three days.'
              : '$urgentSoon urgent tasks are due within three days.',
          tone: InsightTone.warning,
        ),
      );
    }

    if (snapshot.overdueTasks > 0) {
      insights.add(
        Insight(
          id: 'overdue',
          message: snapshot.overdueTasks == 1
              ? '1 task is past its due date.'
              : '${snapshot.overdueTasks} tasks are past their due date.',
          tone: InsightTone.warning,
        ),
      );
    }

    if (snapshot.focusMinutes >= 60) {
      insights.add(
        Insight(
          id: 'focus',
          message:
              'You logged ${Dates.duration(snapshot.focusMinutes)} of focused '
              'work this week.',
          tone: InsightTone.positive,
        ),
      );
    }

    if (insights.isEmpty && snapshot.totalTasks > 0) {
      insights.add(
        Insight(
          id: 'steady',
          message:
              '${snapshot.remainingTasks} tasks open, none overdue. Steady week.',
          tone: InsightTone.positive,
        ),
      );
    }

    return insights.take(4).toList(growable: false);
  }

  static List<DailyMetric> _emptyDaily(DateTime start, int days) =>
      <DailyMetric>[
        for (int i = 0; i < days; i++)
          DailyMetric(
            day: start.add(Duration(days: i)),
            created: 0,
            completed: 0,
            overdue: 0,
            focusMinutes: 0,
          ),
      ];

  static String _key(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';
}

class _DayAccumulator {
  int created = 0;
  int completed = 0;
  int overdue = 0;
  int focusMinutes = 0;
}
