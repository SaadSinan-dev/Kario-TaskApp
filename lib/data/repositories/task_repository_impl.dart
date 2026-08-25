import 'dart:async';

import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:kairo/domain/services/task_query_engine.dart';

/// The task repository owns every rule that must hold no matter which part of
/// the UI triggered a change — completing a recurring task, refusing a
/// dependency cycle, renumbering a Kanban column, writing the activity record.
///
/// Keeping these here (rather than in controllers) is why the checkbox, the
/// keyboard shortcut, the board drag and the bulk toolbar all behave the same.
class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository({
    required KairoDatabase database,
    required String Function() actorId,
  }) : _db = database,
       _actorId = actorId;

  final KairoDatabase _db;
  final String Function() _actorId;

  @override
  Stream<List<Task>> watchTasks(String workspaceId) async* {
    await for (final List<Task> tasks in _db.tasks.stream) {
      yield tasks
          .where((Task t) => t.workspaceId == workspaceId)
          .toList(growable: false);
    }
  }

  @override
  Stream<Task?> watchTask(String taskId) async* {
    await for (final List<Task> tasks in _db.tasks.stream) {
      yield tasks.where((Task t) => t.id == taskId).firstOrNull;
    }
  }

  @override
  Future<Task?> findTask(String taskId) async => _db.taskById(taskId);

  @override
  Future<Task> createTask(Task draft) => Failure.guard(() async {
    await _db.latency(0.7);
    if (draft.title.trim().isEmpty) {
      throw const ValidationFailure(<String, String>{
        'title': 'A task needs a title.',
      });
    }
    if (draft.startDate != null &&
        draft.dueDate != null &&
        draft.dueDate!.isBefore(draft.startDate!)) {
      throw const ValidationFailure(<String, String>{
        'dueDate': 'The due date can’t be before the start date.',
      });
    }

    final Task task = draft.copyWith(
      title: draft.title.trim(),
      sortIndex: _nextIndexIn(draft.status, draft.workspaceId),
      updatedAt: DateTime.now(),
    );
    final Task created = Task(
      id: task.id.isEmpty ? Ids.task() : task.id,
      workspaceId: task.workspaceId,
      projectId: task.projectId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      assigneeId: task.assigneeId,
      labelIds: task.labelIds,
      dueDate: task.dueDate,
      startDate: task.startDate,
      estimateMinutes: task.estimateMinutes,
      subtasks: task.subtasks,
      dependsOnIds: task.dependsOnIds,
      attachments: task.attachments,
      recurrence: task.recurrence,
      sortIndex: task.sortIndex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdById: _actorId(),
    );

    _db.commit<Task>(_db.tasks, <Task>[
      ..._db.tasks.value,
      created,
    ], Collections.tasks);
    _log(created, ActivityType.taskCreated, to: created.title);
    _notifyAssignment(created, previousAssignee: null);
    return created;
  });

  @override
  Future<Task> updateTask(Task task) => Failure.guard(() async {
    await _db.latency(0.4);
    final Task previous =
        _db.taskById(task.id) ?? (throw NotFoundFailure('task', task.id));

    if (task.title.trim().isEmpty) {
      throw const ValidationFailure(<String, String>{
        'title': 'A task needs a title.',
      });
    }
    if (task.startDate != null &&
        task.dueDate != null &&
        task.dueDate!.isBefore(task.startDate!)) {
      throw const ValidationFailure(<String, String>{
        'dueDate': 'The due date can’t be before the start date.',
      });
    }

    final Task updated = task.copyWith(
      title: task.title.trim(),
      updatedAt: DateTime.now(),
    );
    _write(updated);
    _logDiff(previous, updated);
    if (previous.assigneeId != updated.assigneeId) {
      _notifyAssignment(updated, previousAssignee: previous.assigneeId);
    }
    return updated;
  });

  @override
  Future<void> deleteTask(String taskId) => Failure.guard(() async {
    await _db.latency(0.4);
    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value
          .where((Task t) => t.id != taskId)
          .map(
            // Drop the edge from anything that depended on it, so no task is
            // left blocked by something that no longer exists.
            (Task t) => t.dependsOnIds.contains(taskId)
                ? t.copyWith(
                    dependsOnIds: t.dependsOnIds
                        .where((String id) => id != taskId)
                        .toList(),
                  )
                : t,
          )
          .toList(),
      Collections.tasks,
    );
    _db.commit<Comment>(
      _db.comments,
      _db.comments.value.where((Comment c) => c.taskId != taskId).toList(),
      Collections.comments,
    );
  });

  @override
  Future<Task> setCompleted(String taskId, {required bool completed}) =>
      Failure.guard(() async {
        final Task task =
            _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));

        if (completed && task.dependsOnIds.isNotEmpty) {
          final List<Task> blockers = _db.tasks.value
              .where((Task t) => task.dependsOnIds.contains(t.id) && !t.isDone)
              .toList();
          if (blockers.isNotEmpty) {
            throw ConflictFailure(
              blockers.length == 1
                  ? '“${blockers.first.title}” has to finish first.'
                  : '${blockers.length} blocking tasks have to finish first.',
            );
          }
        }

        final Task updated = task.copyWith(
          status: completed ? TaskStatus.completed : TaskStatus.reopened,
          completedAt: completed ? DateTime.now() : null,
          clearCompletedAt: !completed,
          updatedAt: DateTime.now(),
        );
        _write(updated);
        _log(
          updated,
          completed ? ActivityType.taskCompleted : ActivityType.taskReopened,
        );

        // Completing a recurring task schedules the next occurrence rather than
        // resurrecting the finished one, so history stays intact.
        if (completed && task.recurrence.isEnabled) {
          final DateTime? next = task.recurrence.nextOccurrence(
            task.dueDate ?? DateTime.now(),
          );
          if (next != null) {
            final Task nextOccurrence = Task(
              id: Ids.task(),
              workspaceId: task.workspaceId,
              projectId: task.projectId,
              title: task.title,
              description: task.description,
              status: TaskStatus.todo,
              priority: task.priority,
              assigneeId: task.assigneeId,
              labelIds: task.labelIds,
              dueDate: next,
              estimateMinutes: task.estimateMinutes,
              subtasks: task.subtasks
                  .map((Subtask s) => s.copyWith(isDone: false))
                  .toList(),
              recurrence: task.recurrence,
              sortIndex: _nextIndexIn(TaskStatus.todo, task.workspaceId),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdById: task.createdById,
            );
            _db.commit<Task>(_db.tasks, <Task>[
              ..._db.tasks.value,
              nextOccurrence,
            ], Collections.tasks);
          }
        }
        return updated;
      });

  @override
  Future<Task> setStatus(String taskId, TaskStatus status) =>
      Failure.guard(() async {
        final Task task =
            _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
        if (status.isDone) return setCompleted(taskId, completed: true);
        if (task.isDone) return setCompleted(taskId, completed: false);

        final Task updated = task.copyWith(
          status: status,
          sortIndex: _nextIndexIn(status, task.workspaceId),
          updatedAt: DateTime.now(),
        );
        _write(updated);
        _log(
          updated,
          ActivityType.statusChanged,
          from: task.status.name,
          to: status.name,
        );
        return updated;
      });

  @override
  Future<Task> setArchived(String taskId, {required bool archived}) =>
      Failure.guard(() async {
        final Task task =
            _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
        final Task updated = task.copyWith(
          isArchived: archived,
          updatedAt: DateTime.now(),
        );
        _write(updated);
        _log(
          updated,
          archived ? ActivityType.taskArchived : ActivityType.taskRestored,
        );
        return updated;
      });

  @override
  Future<Task> toggleFavorite(String taskId) => Failure.guard(() async {
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
    final Task updated = task.copyWith(isFavorite: !task.isFavorite);
    _write(updated);
    return updated;
  });

  @override
  Future<Task> duplicateTask(String taskId) => Failure.guard(() async {
    await _db.latency(0.5);
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
    final Task copy = Task(
      id: Ids.task(),
      workspaceId: task.workspaceId,
      projectId: task.projectId,
      title: '${task.title} (copy)',
      description: task.description,
      status: task.status,
      priority: task.priority,
      assigneeId: task.assigneeId,
      labelIds: task.labelIds,
      dueDate: task.dueDate,
      startDate: task.startDate,
      estimateMinutes: task.estimateMinutes,
      // Subtasks come along unchecked; dependencies do not, because a copy is
      // not the thing the original was blocked on.
      subtasks: task.subtasks
          .map(
            (Subtask s) => Subtask(
              id: Ids.subtask(),
              title: s.title,
              sortIndex: s.sortIndex,
            ),
          )
          .toList(),
      recurrence: task.recurrence,
      sortIndex: _nextIndexIn(task.status, task.workspaceId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdById: _actorId(),
    );
    _db.commit<Task>(_db.tasks, <Task>[
      ..._db.tasks.value,
      copy,
    ], Collections.tasks);
    _log(copy, ActivityType.taskCreated, to: copy.title);
    return copy;
  });

  @override
  Future<void> moveTask({
    required String taskId,
    required TaskStatus status,
    required int targetIndex,
  }) => Failure.guard(() async {
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));

    final bool statusChanged = task.status != status;
    final bool completing = status.isDone && !task.isDone;
    final bool reopening = !status.isDone && task.isDone;

    if (completing && task.dependsOnIds.isNotEmpty) {
      final bool blocked = _db.tasks.value.any(
        (Task t) => task.dependsOnIds.contains(t.id) && !t.isDone,
      );
      if (blocked) {
        throw const ConflictFailure(
          'This task is blocked — finish what it depends on first.',
        );
      }
    }

    // Renumber the destination column in one pass so indices stay dense.
    final List<Task> column =
        _db.tasks.value
            .where(
              (Task t) =>
                  t.workspaceId == task.workspaceId &&
                  t.status == status &&
                  t.id != taskId &&
                  !t.isArchived,
            )
            .toList()
          ..sort((Task a, Task b) => a.sortIndex.compareTo(b.sortIndex));

    final int index = targetIndex.clamp(0, column.length);
    final Task moved = task.copyWith(
      status: status,
      completedAt: completing ? DateTime.now() : null,
      clearCompletedAt: reopening,
      updatedAt: DateTime.now(),
    );
    column.insert(index, moved);

    final Map<String, int> newIndices = <String, int>{
      for (int i = 0; i < column.length; i++) column[i].id: i,
    };

    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value.map((Task t) {
        if (t.id == taskId) {
          return moved.copyWith(sortIndex: newIndices[taskId]);
        }
        final int? next = newIndices[t.id];
        return next == null ? t : t.copyWith(sortIndex: next);
      }).toList(),
      Collections.tasks,
    );

    if (completing) {
      _log(moved, ActivityType.taskCompleted);
    } else if (reopening) {
      _log(moved, ActivityType.taskReopened);
    } else if (statusChanged) {
      _log(
        moved,
        ActivityType.statusChanged,
        from: task.status.name,
        to: status.name,
      );
    }
  });

  @override
  Future<void> reorderWithin(TaskStatus status, List<String> orderedIds) =>
      Failure.guard(() async {
        final Map<String, int> order = <String, int>{
          for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
        };
        _db.commit<Task>(
          _db.tasks,
          _db.tasks.value
              .map(
                (Task t) => order.containsKey(t.id)
                    ? t.copyWith(sortIndex: order[t.id], status: status)
                    : t,
              )
              .toList(),
          Collections.tasks,
        );
      });

  @override
  Future<Task> addDependency({
    required String taskId,
    required String dependsOnId,
  }) => Failure.guard(() async {
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
    if (_db.taskById(dependsOnId) == null) {
      throw NotFoundFailure('task', dependsOnId);
    }
    if (task.dependsOnIds.contains(dependsOnId)) return task;

    final Map<String, List<String>> edges = <String, List<String>>{
      for (final Task t in _db.tasks.value) t.id: t.dependsOnIds,
    };
    if (TaskQueryEngine.wouldCreateCycle(
      taskId: taskId,
      dependsOnId: dependsOnId,
      dependencies: edges,
    )) {
      throw const ConflictFailure(
        'That would create a circular dependency between these tasks.',
      );
    }

    final Task updated = task.copyWith(
      dependsOnIds: <String>[...task.dependsOnIds, dependsOnId],
      updatedAt: DateTime.now(),
    );
    _write(updated);
    _log(
      updated,
      ActivityType.dependencyAdded,
      to: _db.taskById(dependsOnId)?.title,
    );
    return updated;
  });

  @override
  Future<Task> removeDependency({
    required String taskId,
    required String dependsOnId,
  }) => Failure.guard(() async {
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
    final Task updated = task.copyWith(
      dependsOnIds: task.dependsOnIds
          .where((String id) => id != dependsOnId)
          .toList(),
      updatedAt: DateTime.now(),
    );
    _write(updated);
    return updated;
  });

  @override
  Future<Task> upsertSubtask(String taskId, Subtask subtask) => Failure.guard(
    () async {
      final Task task =
          _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
      if (subtask.title.trim().isEmpty) {
        throw const ValidationFailure(<String, String>{
          'title': 'A subtask needs a title.',
        });
      }
      final bool exists = task.subtasks.any((Subtask s) => s.id == subtask.id);
      final Subtask normalised = subtask.copyWith(title: subtask.title.trim());
      final List<Subtask> next = exists
          ? task.subtasks
                .map((Subtask s) => s.id == subtask.id ? normalised : s)
                .toList()
          : <Subtask>[
              ...task.subtasks,
              normalised.copyWith(sortIndex: task.subtasks.length),
            ];

      final Task updated = task.copyWith(
        subtasks: next,
        updatedAt: DateTime.now(),
      );
      _write(updated);
      if (exists && normalised.isDone) {
        _log(updated, ActivityType.subtaskCompleted, to: normalised.title);
      }
      return updated;
    },
  );

  @override
  Future<Task> deleteSubtask(String taskId, String subtaskId) =>
      Failure.guard(() async {
        final Task task =
            _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
        final Task updated = task.copyWith(
          subtasks: task.subtasks
              .where((Subtask s) => s.id != subtaskId)
              .toList(),
          updatedAt: DateTime.now(),
        );
        _write(updated);
        return updated;
      });

  @override
  Future<Task> reorderSubtasks(String taskId, List<String> orderedIds) =>
      Failure.guard(() async {
        final Task task =
            _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));
        final Map<String, int> order = <String, int>{
          for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
        };
        final List<Subtask> next =
            task.subtasks
                .map(
                  (Subtask s) => order.containsKey(s.id)
                      ? s.copyWith(sortIndex: order[s.id])
                      : s,
                )
                .toList()
              ..sort(
                (Subtask a, Subtask b) => a.sortIndex.compareTo(b.sortIndex),
              );
        final Task updated = task.copyWith(
          subtasks: next,
          updatedAt: DateTime.now(),
        );
        _write(updated);
        return updated;
      });

  @override
  Future<void> bulkUpdate({
    required List<String> taskIds,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? projectId,
    DateTime? dueDate,
    bool? archived,
  }) => Failure.guard(() async {
    await _db.latency(0.6);
    final Set<String> ids = taskIds.toSet();
    final DateTime now = DateTime.now();

    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value.map((Task task) {
        if (!ids.contains(task.id)) return task;
        final bool completing = status != null && status.isDone && !task.isDone;
        final bool reopening = status != null && !status.isDone && task.isDone;
        return task.copyWith(
          status: status,
          priority: priority,
          assigneeId: assigneeId,
          projectId: projectId,
          dueDate: dueDate,
          isArchived: archived,
          completedAt: completing ? now : null,
          clearCompletedAt: reopening,
          updatedAt: now,
        );
      }).toList(),
      Collections.tasks,
    );
  });

  @override
  Future<void> bulkDelete(List<String> taskIds) => Failure.guard(() async {
    await _db.latency(0.6);
    final Set<String> ids = taskIds.toSet();
    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value
          .where((Task t) => !ids.contains(t.id))
          .map(
            (Task t) => t.dependsOnIds.any(ids.contains)
                ? t.copyWith(
                    dependsOnIds: t.dependsOnIds
                        .where((String id) => !ids.contains(id))
                        .toList(),
                  )
                : t,
          )
          .toList(),
      Collections.tasks,
    );
    _db.commit<Comment>(
      _db.comments,
      _db.comments.value.where((Comment c) => !ids.contains(c.taskId)).toList(),
      Collections.comments,
    );
  });

  // --- Internals ------------------------------------------------------------

  void _write(Task task) {
    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value.map((Task t) => t.id == task.id ? task : t).toList(),
      Collections.tasks,
    );
  }

  int _nextIndexIn(TaskStatus status, String workspaceId) {
    final Iterable<Task> column = _db.tasks.value.where(
      (Task t) => t.workspaceId == workspaceId && t.status == status,
    );
    if (column.isEmpty) return 0;
    return column.fold<int>(
          0,
          (int max, Task t) => t.sortIndex > max ? t.sortIndex : max,
        ) +
        1;
  }

  void _log(Task task, ActivityType type, {String? from, String? to}) {
    _db.recordActivity(
      Activity(
        id: Ids.activity(),
        workspaceId: task.workspaceId,
        type: type,
        actorId: _actorId(),
        createdAt: DateTime.now(),
        taskId: task.id,
        projectId: task.projectId,
        from: from,
        to: to,
      ),
    );
  }

  /// Emits one activity record per field that actually changed, which is what
  /// makes the task history readable instead of a wall of "task updated".
  void _logDiff(Task before, Task after) {
    if (before.status != after.status) {
      _log(
        after,
        ActivityType.statusChanged,
        from: before.status.name,
        to: after.status.name,
      );
    }
    if (before.priority != after.priority) {
      _log(
        after,
        ActivityType.priorityChanged,
        from: before.priority.name,
        to: after.priority.name,
      );
    }
    if (before.assigneeId != after.assigneeId) {
      _log(
        after,
        ActivityType.assigneeChanged,
        from: _db.userById(before.assigneeId ?? '')?.name,
        to: _db.userById(after.assigneeId ?? '')?.name,
      );
    }
    if (before.dueDate != after.dueDate) {
      _log(
        after,
        ActivityType.dueDateChanged,
        from: before.dueDate?.toIso8601String(),
        to: after.dueDate?.toIso8601String(),
      );
    }
    for (final String added in after.labelIds.where(
      (String id) => !before.labelIds.contains(id),
    )) {
      _log(after, ActivityType.labelAdded, to: added);
    }
    for (final String removed in before.labelIds.where(
      (String id) => !after.labelIds.contains(id),
    )) {
      _log(after, ActivityType.labelRemoved, from: removed);
    }
  }

  void _notifyAssignment(Task task, {required String? previousAssignee}) {
    final String? assignee = task.assigneeId;
    if (assignee == null || assignee == previousAssignee) return;
    if (assignee == _actorId()) return; // No notification for self-assignment.
    _db.pushNotification(
      AppNotification(
        id: Ids.notification(),
        workspaceId: task.workspaceId,
        type: NotificationType.assignment,
        title:
            '${_db.userById(_actorId())?.name ?? 'Someone'} assigned you a task',
        body: task.title,
        createdAt: DateTime.now(),
        actorId: _actorId(),
        taskId: task.id,
        projectId: task.projectId,
      ),
    );
  }
}
