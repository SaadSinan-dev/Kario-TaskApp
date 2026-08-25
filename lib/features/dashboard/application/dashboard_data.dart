import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';

/// The lists the dashboard renders, derived once per data change.
@immutable
class DashboardData {
  const DashboardData({
    required this.dueToday,
    required this.upcoming,
    required this.recentlyUpdated,
    required this.completedTrend,
  });

  static const DashboardData empty = DashboardData(
    dueToday: <Task>[],
    upcoming: <Task>[],
    recentlyUpdated: <Task>[],
    completedTrend: <double>[],
  );

  final List<Task> dueToday;
  final List<Task> upcoming;
  final List<Task> recentlyUpdated;
  final List<double> completedTrend;
}

/// Derives the dashboard's lists outside the widget tree.
///
/// These four passes — two filters, a full sort of every task, and a map over
/// the daily metrics — used to run inside `build`. That meant they re-ran on
/// every rebuild, including each frame of a window resize on the web, because
/// the dashboard reads the current breakpoint. As a provider they run once per
/// change to the underlying data and are cached in between.
final Provider<DashboardData> dashboardDataProvider = Provider<DashboardData>((
  Ref ref,
) {
  final List<Task> allTasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final List<Task> mine = ref.watch(myOpenTasksProvider);
  final ProductivitySnapshot? snapshot = ref.watch(snapshotProvider).value;

  final DateTime today = Dates.today();

  final List<Task> dueToday = mine
      .where((Task t) => Dates.isSameDay(t.dueDate, today))
      .toList(growable: false);

  // The next fortnight, capped: the dashboard shows a preview, and the full
  // list lives one tap away on the tasks screen.
  final List<Task> upcoming = mine
      .where(
        (Task t) =>
            t.dueDate != null &&
            t.dueDate!.isAfter(today) &&
            Dates.daysBetween(today, t.dueDate!) <= 14,
      )
      .take(6)
      .toList(growable: false);

  final List<Task> recentlyUpdated = <Task>[...allTasks]
    ..sort((Task a, Task b) => b.updatedAt.compareTo(a.updatedAt));

  // The last fortnight of completions, for the sparkline on the metric tile.
  final List<DailyMetric> daily = snapshot?.daily ?? const <DailyMetric>[];
  final List<double> completedTrend = daily
      .skip(daily.length > 14 ? daily.length - 14 : 0)
      .map((DailyMetric m) => m.completed.toDouble())
      .toList(growable: false);

  return DashboardData(
    dueToday: dueToday,
    upcoming: upcoming,
    recentlyUpdated: recentlyUpdated,
    completedTrend: completedTrend,
  );
});
