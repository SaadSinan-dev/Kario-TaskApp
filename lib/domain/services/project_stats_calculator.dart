import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';

/// Derives a project's headline numbers from a list of tasks.
///
/// This lived as a static on the repository implementation, which meant four
/// presentation files imported `data/` directly to reach it — a dependency
/// pointing the wrong way for a calculation that touches no storage at all.
/// It is a pure function over entities, so it belongs here, and both the
/// repository and the screens now call the same one.
abstract final class ProjectStatsCalculator {
  /// Counts open, completed, overdue and due-this-week work for [projectId].
  ///
  /// Archived tasks are excluded: they are deliberately out of the plan, and
  /// counting them would make a tidied project look worse than a neglected one.
  static ProjectStats forProject(String projectId, List<Task> allTasks) {
    final List<Task> tasks = allTasks
        .where((Task t) => t.projectId == projectId && !t.isArchived)
        .toList(growable: false);
    if (tasks.isEmpty) return ProjectStats.empty;

    final DateTime weekEnd = Dates.today().add(const Duration(days: 7));
    int completed = 0;
    int inProgress = 0;
    int overdue = 0;
    int dueThisWeek = 0;

    for (final Task task in tasks) {
      if (task.isDone) {
        completed++;
        continue;
      }
      if (task.status.isActive) inProgress++;
      if (task.isOverdue) overdue++;

      // "Due this week" and "overdue" are separate states, not overlapping
      // ones — a task counted in both would inflate the workload figure.
      final DateTime? due = task.dueDate;
      if (due != null && !due.isAfter(weekEnd) && !task.isOverdue) {
        dueThisWeek++;
      }
    }

    return ProjectStats(
      total: tasks.length,
      completed: completed,
      inProgress: inProgress,
      overdue: overdue,
      dueThisWeek: dueThisWeek,
    );
  }
}
