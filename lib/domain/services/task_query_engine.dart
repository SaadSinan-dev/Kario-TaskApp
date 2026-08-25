import 'package:kairo/core/utils/fuzzy_match.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';

/// Turns a raw task list plus a [TaskQuery] into what a view should render.
///
/// Pure functions, no Flutter, no I/O — which is what makes the filtering,
/// sorting and grouping rules cheap to unit-test and impossible to duplicate
/// across the list, board, calendar and timeline.
abstract final class TaskQueryEngine {
  static List<Task> apply(List<Task> tasks, TaskQuery query) =>
      sort(filter(tasks, query), query);

  static List<Task> filter(List<Task> tasks, TaskQuery query) {
    final String needle = query.searchText.trim();
    return tasks
        .where((Task task) {
          if (!query.includeArchived && task.isArchived) return false;
          if (query.includeArchived && !task.isArchived) return false;
          if (query.projectId != null && task.projectId != query.projectId) {
            return false;
          }
          if (query.statuses.isNotEmpty &&
              !query.statuses.contains(task.status)) {
            return false;
          }
          if (query.priorities.isNotEmpty &&
              !query.priorities.contains(task.priority)) {
            return false;
          }
          if (query.onlyUnassigned && task.assigneeId != null) return false;
          if (query.assigneeIds.isNotEmpty &&
              (task.assigneeId == null ||
                  !query.assigneeIds.contains(task.assigneeId))) {
            return false;
          }
          if (query.labelIds.isNotEmpty &&
              !task.labelIds.any(query.labelIds.contains)) {
            return false;
          }
          if (query.onlyFavorites && !task.isFavorite) return false;
          if (query.onlyOverdue && !task.isOverdue) return false;
          if (query.dueFrom != null) {
            final DateTime? due = task.dueDate;
            if (due == null || due.isBefore(query.dueFrom!)) return false;
          }
          if (query.dueTo != null) {
            final DateTime? due = task.dueDate;
            if (due == null || due.isAfter(query.dueTo!)) return false;
          }
          if (needle.isNotEmpty) {
            final FuzzyMatch hit = Fuzzy.matchAny(<String>[
              task.title,
              task.description,
            ], needle);
            if (!hit.isMatch) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  static List<Task> sort(List<Task> tasks, TaskQuery query) {
    final List<Task> sorted = <Task>[...tasks];
    final int direction = query.sortDirection == SortDirection.ascending
        ? 1
        : -1;

    int compare(Task a, Task b) {
      switch (query.sortField) {
        case TaskSortField.manual:
          final int byIndex = a.sortIndex.compareTo(b.sortIndex);
          return byIndex != 0 ? byIndex : a.createdAt.compareTo(b.createdAt);
        case TaskSortField.dueDate:
          return _compareNullableDates(a.dueDate, b.dueDate);
        case TaskSortField.priority:
          return b.priority.weight.compareTo(a.priority.weight);
        case TaskSortField.createdAt:
          return a.createdAt.compareTo(b.createdAt);
        case TaskSortField.updatedAt:
          return b.updatedAt.compareTo(a.updatedAt);
        case TaskSortField.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    }

    sorted.sort((Task a, Task b) {
      final int primary = compare(a, b) * direction;
      // Stable tiebreak keeps rows from shuffling between rebuilds.
      return primary != 0 ? primary : a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// Groups an already filtered and sorted list.
  ///
  /// [labelFor] resolves a group key to display text, supplied by the
  /// presentation layer so this file stays free of localisation.
  static List<TaskGroup<Task>> group(
    List<Task> tasks,
    TaskQuery query, {
    required String Function(TaskGrouping grouping, String key) labelFor,
    int? Function(TaskGrouping grouping, String key)? colorFor,
    bool includeEmptyStatuses = false,
  }) {
    if (query.grouping == TaskGrouping.none) {
      return <TaskGroup<Task>>[
        TaskGroup<Task>(
          key: 'all',
          label: labelFor(TaskGrouping.none, 'all'),
          items: tasks,
        ),
      ];
    }

    final Map<String, List<Task>> buckets = <String, List<Task>>{};
    if (query.grouping == TaskGrouping.status && includeEmptyStatuses) {
      for (final TaskStatus status in TaskStatus.values) {
        buckets[status.name] = <Task>[];
      }
    }

    for (final Task task in tasks) {
      buckets
          .putIfAbsent(_keyFor(task, query.grouping), () => <Task>[])
          .add(task);
    }

    final List<String> orderedKeys = buckets.keys.toList()
      ..sort(
        (String a, String b) => _keyOrder(
          query.grouping,
          a,
        ).compareTo(_keyOrder(query.grouping, b)),
      );

    return <TaskGroup<Task>>[
      for (final String key in orderedKeys)
        TaskGroup<Task>(
          key: key,
          label: labelFor(query.grouping, key),
          items: buckets[key]!,
          accentColorValue: colorFor?.call(query.grouping, key),
        ),
    ];
  }

  static String _keyFor(Task task, TaskGrouping grouping) => switch (grouping) {
    TaskGrouping.none => 'all',
    TaskGrouping.status => task.status.name,
    TaskGrouping.priority => task.priority.name,
    TaskGrouping.project => task.projectId ?? '__none__',
    TaskGrouping.assignee => task.assigneeId ?? '__none__',
    TaskGrouping.dueDate => _dueBucket(task.dueDate),
  };

  /// Buckets used when grouping by date. Ordered by [_keyOrder] below.
  static String _dueBucket(DateTime? due) {
    if (due == null) return 'z_none';
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(due.year, due.month, due.day);
    final DateTime start = DateTime(today.year, today.month, today.day);
    final int delta = day.difference(start).inDays;
    if (delta < 0) return 'a_overdue';
    if (delta == 0) return 'b_today';
    if (delta == 1) return 'c_tomorrow';
    if (delta <= 7) return 'd_week';
    if (delta <= 30) return 'e_month';
    return 'f_later';
  }

  static int _keyOrder(TaskGrouping grouping, String key) {
    switch (grouping) {
      case TaskGrouping.status:
        final int index = TaskStatus.values.indexWhere(
          (TaskStatus s) => s.name == key,
        );
        return index < 0 ? 99 : index;
      case TaskGrouping.priority:
        final int index = TaskPriority.values.indexWhere(
          (TaskPriority p) => p.name == key,
        );
        return index < 0 ? 99 : index;
      case TaskGrouping.dueDate:
        return key.codeUnitAt(0);
      case TaskGrouping.project:
      case TaskGrouping.assignee:
        // Unassigned/no-project always sorts last.
        return key == '__none__' ? 999 : 0;
      case TaskGrouping.none:
        return 0;
    }
  }

  static int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    // Tasks without a due date sort after those with one, in both directions —
    // "no date" is not "far future", it is "not scheduled".
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// True when making [taskId] depend on [dependsOnId] would close a cycle.
  ///
  /// Walks the existing edges from the candidate ancestor; if it can reach
  /// [taskId], adding the edge would create a loop.
  static bool wouldCreateCycle({
    required String taskId,
    required String dependsOnId,
    required Map<String, List<String>> dependencies,
  }) {
    if (taskId == dependsOnId) return true;
    final Set<String> visited = <String>{};
    final List<String> stack = <String>[dependsOnId];
    while (stack.isNotEmpty) {
      final String current = stack.removeLast();
      if (current == taskId) return true;
      if (!visited.add(current)) continue;
      stack.addAll(dependencies[current] ?? const <String>[]);
    }
    return false;
  }

  /// Ids of tasks blocked by [taskId] — the reverse edge, derived rather than
  /// stored so the two directions can never disagree.
  static List<String> blockedBy(String taskId, List<Task> tasks) => tasks
      .where((Task t) => t.dependsOnIds.contains(taskId))
      .map((Task t) => t.id)
      .toList(growable: false);
}
