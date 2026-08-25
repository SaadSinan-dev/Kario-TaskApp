import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';

import '../support/test_harness.dart';

/// Repository behaviour — the business rules that must hold no matter which
/// part of the UI triggered them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;
  late TaskRepository tasks;

  setUp(() async {
    harness = await TestHarness.create();
    tasks = harness.container.read(taskRepositoryProvider);
  });

  tearDown(() => harness.dispose());

  Task draft({
    String title = 'A new task',
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
    RecurrenceRule recurrence = RecurrenceRule.none,
    List<String> dependsOn = const <String>[],
  }) {
    final DateTime now = DateTime.now();
    return Task(
      id: '',
      workspaceId: harness.workspaceId,
      title: title,
      status: status,
      dueDate: dueDate,
      recurrence: recurrence,
      dependsOnIds: dependsOn,
      createdAt: now,
      updatedAt: now,
      createdById: harness.demoUser.id,
    );
  }

  group('create', () {
    test('assigns an id and records a creation activity', () async {
      final Task created = await tasks.createTask(
        draft(title: 'Ship the docs'),
      );

      expect(created.id, isNotEmpty);
      expect(created.title, 'Ship the docs');
      expect(await tasks.findTask(created.id), isNotNull);

      final List<Activity> activity = await harness.container
          .read(activityRepositoryProvider)
          .watchTaskActivity(created.id)
          .first;
      expect(activity.single.type, ActivityType.taskCreated);
    });

    test('rejects an empty title', () async {
      expect(
        () => tasks.createTask(draft(title: '   ')),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects a due date before the start date', () async {
      final DateTime now = DateTime.now();
      expect(
        () => tasks.createTask(
          Task(
            id: '',
            workspaceId: harness.workspaceId,
            title: 'Backwards',
            startDate: DateTime(now.year, now.month, now.day + 5),
            dueDate: DateTime(now.year, now.month, now.day + 1),
            createdAt: now,
            updatedAt: now,
            createdById: harness.demoUser.id,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('completion', () {
    test('sets status, completedAt, and clears them on reopen', () async {
      final Task created = await tasks.createTask(draft());

      final Task done = await tasks.setCompleted(created.id, completed: true);
      expect(done.status, TaskStatus.done);
      expect(done.completedAt, isNotNull);
      expect(done.isDone, isTrue);

      final Task reopened = await tasks.setCompleted(
        created.id,
        completed: false,
      );
      expect(reopened.status, TaskStatus.todo);
      expect(reopened.completedAt, isNull);
    });

    test('refuses to complete a task with an open blocker', () async {
      final Task blocker = await tasks.createTask(draft(title: 'Blocker'));
      final Task blocked = await tasks.createTask(
        draft(title: 'Blocked', dependsOn: <String>[blocker.id]),
      );

      expect(
        () => tasks.setCompleted(blocked.id, completed: true),
        throwsA(isA<ConflictFailure>()),
      );

      await tasks.setCompleted(blocker.id, completed: true);
      final Task now = await tasks.setCompleted(blocked.id, completed: true);
      expect(now.isDone, isTrue);
    });

    test('completing a recurring task schedules the next occurrence', () async {
      final DateTime due = DateTime.now();
      final Task created = await tasks.createTask(
        draft(
          title: 'Weekly report',
          dueDate: DateTime(due.year, due.month, due.day),
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
          ),
        ),
      );

      await tasks.setCompleted(created.id, completed: true);

      final List<Task> all = await tasks.watchTasks(harness.workspaceId).first;
      final List<Task> byTitle = all
          .where((Task t) => t.title == 'Weekly report')
          .toList();

      expect(byTitle.length, 2, reason: 'the original plus one new occurrence');
      expect(byTitle.where((Task t) => t.isDone).length, 1);

      final Task next = byTitle.firstWhere((Task t) => !t.isDone);
      expect(next.dueDate, isNotNull);
      expect(next.dueDate!.isAfter(created.dueDate!), isTrue);
    });
  });

  group('dependencies', () {
    test('adding a cyclic dependency is refused', () async {
      final Task a = await tasks.createTask(draft(title: 'A'));
      final Task b = await tasks.createTask(draft(title: 'B'));

      await tasks.addDependency(taskId: b.id, dependsOnId: a.id);

      expect(
        () => tasks.addDependency(taskId: a.id, dependsOnId: b.id),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('deleting a task removes edges pointing at it', () async {
      final Task blocker = await tasks.createTask(draft(title: 'Blocker'));
      final Task blocked = await tasks.createTask(
        draft(title: 'Blocked', dependsOn: <String>[blocker.id]),
      );

      await tasks.deleteTask(blocker.id);

      final Task? after = await tasks.findTask(blocked.id);
      expect(after!.dependsOnIds, isEmpty);
    });
  });

  group('board moves', () {
    test('moving to a column renumbers that column densely', () async {
      final Task a = await tasks.createTask(
        draft(title: 'A', status: TaskStatus.todo),
      );
      final Task b = await tasks.createTask(
        draft(title: 'B', status: TaskStatus.todo),
      );
      final Task c = await tasks.createTask(
        draft(title: 'C', status: TaskStatus.inProgress),
      );

      await tasks.moveTask(
        taskId: c.id,
        status: TaskStatus.todo,
        targetIndex: 0,
      );

      final List<Task> all = await tasks.watchTasks(harness.workspaceId).first;
      final List<Task> column =
          all
              .where((Task t) => t.status == TaskStatus.todo && !t.isArchived)
              .toList()
            ..sort((Task x, Task y) => x.sortIndex.compareTo(y.sortIndex));

      expect(column.first.id, c.id);
      expect(
        column.map((Task t) => t.sortIndex).toList(),
        List<int>.generate(column.length, (int i) => i),
      );
      expect(column.map((Task t) => t.id), containsAll(<String>[a.id, b.id]));
    });

    test('dropping into Done completes the task', () async {
      final Task created = await tasks.createTask(draft());
      await tasks.moveTask(
        taskId: created.id,
        status: TaskStatus.done,
        targetIndex: 0,
      );

      final Task? after = await tasks.findTask(created.id);
      expect(after!.isDone, isTrue);
      expect(after.completedAt, isNotNull);
    });
  });

  group('subtasks and duplication', () {
    test('subtask progress reflects completion', () async {
      Task created = await tasks.createTask(draft());
      created = await tasks.upsertSubtask(
        created.id,
        const Subtask(id: 's1', title: 'One'),
      );
      created = await tasks.upsertSubtask(
        created.id,
        const Subtask(id: 's2', title: 'Two'),
      );
      expect(created.subtaskProgress, 0);

      created = await tasks.upsertSubtask(
        created.id,
        const Subtask(id: 's1', title: 'One', isDone: true),
      );
      expect(created.completedSubtaskCount, 1);
      expect(created.subtaskProgress, 0.5);
    });

    test(
      'duplicating copies subtasks unchecked and drops dependencies',
      () async {
        final Task blocker = await tasks.createTask(draft(title: 'Blocker'));
        Task original = await tasks.createTask(
          draft(title: 'Original', dependsOn: <String>[blocker.id]),
        );
        original = await tasks.upsertSubtask(
          original.id,
          const Subtask(id: 's1', title: 'Step', isDone: true),
        );

        final Task copy = await tasks.duplicateTask(original.id);

        expect(copy.title, 'Original (copy)');
        expect(copy.subtasks.single.isDone, isFalse);
        expect(copy.dependsOnIds, isEmpty);
        expect(copy.id, isNot(original.id));
      },
    );
  });

  group('bulk operations', () {
    test('bulk update applies to every selected task', () async {
      final Task a = await tasks.createTask(draft(title: 'A'));
      final Task b = await tasks.createTask(draft(title: 'B'));

      await tasks.bulkUpdate(
        taskIds: <String>[a.id, b.id],
        priority: TaskPriority.urgent,
      );

      expect((await tasks.findTask(a.id))!.priority, TaskPriority.urgent);
      expect((await tasks.findTask(b.id))!.priority, TaskPriority.urgent);
    });

    test('bulk delete removes tasks and their comments', () async {
      final Task a = await tasks.createTask(draft(title: 'A'));
      await harness.container
          .read(commentRepositoryProvider)
          .addComment(
            taskId: a.id,
            authorId: harness.demoUser.id,
            body: 'A note',
          );

      await tasks.bulkDelete(<String>[a.id]);

      expect(await tasks.findTask(a.id), isNull);
      final List<Comment> comments = await harness.container
          .read(commentRepositoryProvider)
          .watchComments(a.id)
          .first;
      expect(comments, isEmpty);
    });
  });

  group('archive', () {
    test('archived tasks leave the default list but survive', () async {
      final Task created = await tasks.createTask(draft());
      await tasks.setArchived(created.id, archived: true);

      final Task? archived = await tasks.findTask(created.id);
      expect(archived!.isArchived, isTrue);

      await tasks.setArchived(created.id, archived: false);
      expect((await tasks.findTask(created.id))!.isArchived, isFalse);
    });
  });

  group('seeded demo workspace', () {
    test('loads a coherent story', () async {
      final List<Task> all = await tasks.watchTasks(harness.workspaceId).first;

      expect(all.length, greaterThan(20));
      expect(all.where((Task t) => t.isDone).length, greaterThan(5));
      expect(all.where((Task t) => t.isOverdue).length, greaterThan(0));
      expect(
        all.where((Task t) => t.dependsOnIds.isNotEmpty).length,
        greaterThan(0),
      );
      expect(
        all.where((Task t) => t.recurrence.isEnabled).length,
        greaterThan(0),
      );

      // Nothing generic slipped into the demo content.
      expect(
        all.any((Task t) => RegExp(r'^Task \d+$').hasMatch(t.title)),
        isFalse,
      );
    });

    test('projects and labels are scoped to the workspace', () async {
      final projects = await harness.container
          .read(projectRepositoryProvider)
          .watchProjects(harness.workspaceId)
          .first;
      expect(projects, isNotEmpty);
      expect(
        projects.every((p) => p.workspaceId == harness.workspaceId),
        isTrue,
      );

      final labels = await harness.container
          .read(workspaceRepositoryProvider)
          .watchLabels(harness.workspaceId)
          .first;
      expect(labels, isNotEmpty);
    });
  });
}
