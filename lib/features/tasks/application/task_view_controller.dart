import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/services/task_query_engine.dart';

/// UI state for the task views: what is being shown, how, and what is selected.
///
/// Kept separate from the data providers on purpose. Filters, grouping and the
/// current selection are *view* concerns — they belong to the screen, not to
/// the workspace, and they must not survive a page reload as if they were data.

class TaskQueryController extends Notifier<TaskQuery> {
  @override
  TaskQuery build() => const TaskQuery();

  void setQuery(TaskQuery query) => state = query;

  void update(TaskQuery Function(TaskQuery current) transform) =>
      state = transform(state);

  void setSearch(String text) => state = state.copyWith(searchText: text);

  void toggleStatus(TaskStatus status) {
    final Set<TaskStatus> next = <TaskStatus>{...state.statuses};
    if (!next.remove(status)) next.add(status);
    state = state.copyWith(statuses: next);
  }

  void togglePriority(TaskPriority priority) {
    final Set<TaskPriority> next = <TaskPriority>{...state.priorities};
    if (!next.remove(priority)) next.add(priority);
    state = state.copyWith(priorities: next);
  }

  void toggleAssignee(String userId) {
    final Set<String> next = <String>{...state.assigneeIds};
    if (!next.remove(userId)) next.add(userId);
    state = state.copyWith(assigneeIds: next);
  }

  void toggleLabel(String labelId) {
    final Set<String> next = <String>{...state.labelIds};
    if (!next.remove(labelId)) next.add(labelId);
    state = state.copyWith(labelIds: next);
  }

  void setGrouping(TaskGrouping grouping) =>
      state = state.copyWith(grouping: grouping);

  void setSort(TaskSortField field) {
    // Tapping the active sort field flips its direction, which is what a table
    // header is expected to do.
    state = state.sortField == field
        ? state.copyWith(sortDirection: state.sortDirection.flipped)
        : state.copyWith(sortField: field);
  }

  void clearFilters() => state = state.cleared();
}

final NotifierProvider<TaskQueryController, TaskQuery> taskQueryProvider =
    NotifierProvider<TaskQueryController, TaskQuery>(TaskQueryController.new);

/// The view a task screen is currently rendering. Seeded from the user's
/// preferred default view.
class TaskViewTypeController extends Notifier<TaskViewType> {
  @override
  TaskViewType build() => ref.watch(
    preferencesProvider.select((UserPreferences p) => p.defaultTaskView),
  );

  void set(TaskViewType type) => state = type;
}

final NotifierProvider<TaskViewTypeController, TaskViewType>
taskViewTypeProvider = NotifierProvider<TaskViewTypeController, TaskViewType>(
  TaskViewTypeController.new,
);

/// Multi-select state for bulk actions.
class TaskSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool get isActive => state.isNotEmpty;

  void toggle(String taskId, {required bool selected}) {
    final Set<String> next = <String>{...state};
    if (selected) {
      next.add(taskId);
    } else {
      next.remove(taskId);
    }
    state = next;
  }

  void selectAll(Iterable<String> ids) => state = ids.toSet();

  void clear() => state = const <String>{};
}

final NotifierProvider<TaskSelectionController, Set<String>>
taskSelectionProvider = NotifierProvider<TaskSelectionController, Set<String>>(
  TaskSelectionController.new,
);

/// Tasks after the active query is applied. This is what every task view reads.
final Provider<List<Task>> filteredTasksProvider = Provider<List<Task>>((
  Ref ref,
) {
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final TaskQuery query = ref.watch(taskQueryProvider);
  return TaskQueryEngine.apply(tasks, query);
});

/// Tasks scoped to a single project, using the same engine so a project board
/// behaves exactly like the workspace board.
final filteredProjectTasksProvider = Provider.family<List<Task>, String>((
  Ref ref,
  String projectId,
) {
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final TaskQuery query = ref
      .watch(taskQueryProvider)
      .copyWith(projectId: projectId);
  return TaskQueryEngine.apply(tasks, query);
});

/// The signed-in person's open work, used by the dashboard and "My Tasks".
final Provider<List<Task>> myOpenTasksProvider = Provider<List<Task>>((
  Ref ref,
) {
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final String? userId = ref.watch(currentUserValueProvider)?.id;
  return tasks
      .where((Task t) => !t.isArchived && !t.isDone && t.assigneeId == userId)
      .toList(growable: false)
    ..sort((Task a, Task b) {
      final int byDue = _compareDue(a.dueDate, b.dueDate);
      if (byDue != 0) return byDue;
      return b.priority.weight.compareTo(a.priority.weight);
    });
});

int _compareDue(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
