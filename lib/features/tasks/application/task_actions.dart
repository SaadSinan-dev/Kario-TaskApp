import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/error/failure_messages.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The application layer for tasks.
///
/// Sits between widgets and [TaskRepository] and owns the things a repository
/// should not: user feedback, undo, and translating a [Failure] into a toast.
/// Widgets call these methods and stay free of error handling.
///
/// Note the parameter type: these take [AppL10n], not a `BuildContext`. Passing
/// a context into async application code invites use-after-dispose bugs; the
/// caller resolves the strings synchronously and hands over plain data.
class TaskActions {
  const TaskActions(this._ref);

  final Ref _ref;

  TaskRepository get _repository => _ref.read(taskRepositoryProvider);
  ToastController get _toasts => _ref.read(toastProvider.notifier);

  Future<Task?> create({required AppL10n l10n, required Task draft}) {
    return _run(l10n, () async {
      final Task task = await _repository.createTask(draft);
      _toasts.success(l10n.toastTaskCreated, description: task.title);
      return task;
    });
  }

  Future<Task?> update({
    required AppL10n l10n,
    required Task task,
    bool silent = false,
  }) {
    return _run(l10n, () async {
      final Task updated = await _repository.updateTask(task);
      if (!silent) _toasts.success(l10n.toastTaskUpdated);
      return updated;
    });
  }

  /// Completing shows an undo affordance rather than a confirmation — the
  /// action is cheap to reverse, so it should not be interrupted.
  Future<Task?> setCompleted({
    required AppL10n l10n,
    required Task task,
    required bool completed,
  }) {
    return _run(l10n, () async {
      final Task updated = await _repository.setCompleted(
        task.id,
        completed: completed,
      );
      if (completed) {
        _toasts.success(
          l10n.toastTaskCompleted,
          description: task.title,
          actionLabel: l10n.toastUndo,
          onAction: () => _repository.setCompleted(task.id, completed: false),
        );
      } else {
        _toasts.show(l10n.toastTaskReopened, description: task.title);
      }
      return updated;
    });
  }

  Future<void> setStatus({
    required AppL10n l10n,
    required String taskId,
    required TaskStatus status,
  }) => _run(l10n, () => _repository.setStatus(taskId, status));

  Future<void> move({
    required AppL10n l10n,
    required String taskId,
    required TaskStatus status,
    required int index,
  }) => _run(
    l10n,
    () => _repository.moveTask(
      taskId: taskId,
      status: status,
      targetIndex: index,
    ),
  );

  Future<void> reorderWithin({
    required AppL10n l10n,
    required TaskStatus status,
    required List<String> orderedIds,
  }) => _run(l10n, () => _repository.reorderWithin(status, orderedIds));

  Future<void> delete({required AppL10n l10n, required Task task}) {
    return _run(l10n, () async {
      await _repository.deleteTask(task.id);
      _toasts.show(l10n.toastTaskDeleted, description: task.title);
    });
  }

  Future<void> setArchived({
    required AppL10n l10n,
    required Task task,
    required bool archived,
  }) {
    return _run(l10n, () async {
      await _repository.setArchived(task.id, archived: archived);
      _toasts.success(
        archived ? l10n.toastTaskArchived : l10n.toastTaskRestored,
        description: task.title,
        actionLabel: l10n.toastUndo,
        onAction: () => _repository.setArchived(task.id, archived: !archived),
      );
    });
  }

  Future<void> duplicate({required AppL10n l10n, required Task task}) {
    return _run(l10n, () async {
      final Task copy = await _repository.duplicateTask(task.id);
      _toasts.success(l10n.toastTaskDuplicated, description: copy.title);
    });
  }

  Future<void> toggleFavorite(String taskId) async {
    await _repository.toggleFavorite(taskId);
  }

  Future<void> upsertSubtask({
    required AppL10n l10n,
    required String taskId,
    required Subtask subtask,
  }) => _run(l10n, () => _repository.upsertSubtask(taskId, subtask));

  Future<void> deleteSubtask({
    required AppL10n l10n,
    required String taskId,
    required String subtaskId,
  }) => _run(l10n, () => _repository.deleteSubtask(taskId, subtaskId));

  Future<void> reorderSubtasks({
    required AppL10n l10n,
    required String taskId,
    required List<String> orderedIds,
  }) => _run(l10n, () => _repository.reorderSubtasks(taskId, orderedIds));

  Future<void> addDependency({
    required AppL10n l10n,
    required String taskId,
    required String dependsOnId,
  }) => _run(
    l10n,
    () => _repository.addDependency(taskId: taskId, dependsOnId: dependsOnId),
  );

  Future<void> removeDependency({
    required AppL10n l10n,
    required String taskId,
    required String dependsOnId,
  }) => _run(
    l10n,
    () =>
        _repository.removeDependency(taskId: taskId, dependsOnId: dependsOnId),
  );

  Future<void> bulkUpdate({
    required AppL10n l10n,
    required List<String> taskIds,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? projectId,
    DateTime? dueDate,
    bool? archived,
  }) {
    return _run(l10n, () async {
      await _repository.bulkUpdate(
        taskIds: taskIds,
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        projectId: projectId,
        dueDate: dueDate,
        archived: archived,
      );
      _toasts.success(
        l10n.toastTaskUpdated,
        description: l10n.tasksCount(taskIds.length),
      );
    });
  }

  Future<void> bulkDelete({
    required AppL10n l10n,
    required List<String> taskIds,
  }) {
    return _run(l10n, () async {
      await _repository.bulkDelete(taskIds);
      _toasts.show(
        l10n.toastTaskDeleted,
        description: l10n.tasksCount(taskIds.length),
      );
    });
  }

  /// Every mutation funnels through here, so a failure always produces a
  /// readable toast instead of an unhandled exception.
  Future<T?> _run<T>(AppL10n l10n, Future<T> Function() action) async {
    try {
      return await action();
    } on Failure catch (failure) {
      final FailureMessage message = failure.describe(l10n);
      _toasts.error(message.title, description: message.body);
      return null;
    }
  }
}

final Provider<TaskActions> taskActionsProvider = Provider<TaskActions>(
  TaskActions.new,
);

/// A blank task scoped to the active workspace, used as the starting point for
/// every create flow.
Task draftTask(
  WidgetRef ref, {
  String? projectId,
  TaskStatus status = TaskStatus.todo,
  DateTime? dueDate,
  String? assigneeId,
}) {
  final String workspaceId = ref.read(activeWorkspaceIdProvider) ?? '';
  final String userId = ref.read(currentUserValueProvider)?.id ?? '';
  final DateTime now = DateTime.now();
  return Task(
    id: '',
    workspaceId: workspaceId,
    projectId: projectId,
    title: '',
    status: status,
    dueDate: dueDate,
    assigneeId: assigneeId,
    createdAt: now,
    updatedAt: now,
    createdById: userId,
  );
}
