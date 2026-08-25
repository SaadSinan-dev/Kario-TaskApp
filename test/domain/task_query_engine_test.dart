import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/services/task_query_engine.dart';

/// The filtering, sorting, grouping and dependency rules every task view
/// depends on. These are pure functions, so they get the densest coverage.
void main() {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  Task task({
    required String id,
    String title = 'Task',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String? assigneeId,
    String? projectId,
    List<String> labelIds = const <String>[],
    DateTime? dueDate,
    bool archived = false,
    bool favorite = false,
    int sortIndex = 0,
    List<String> dependsOn = const <String>[],
  }) {
    return Task(
      id: id,
      workspaceId: 'wsp',
      title: title,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      projectId: projectId,
      labelIds: labelIds,
      dueDate: dueDate,
      isArchived: archived,
      isFavorite: favorite,
      sortIndex: sortIndex,
      dependsOnIds: dependsOn,
      createdAt: today,
      updatedAt: today,
      createdById: 'usr',
    );
  }

  group('filter', () {
    test('excludes archived tasks unless asked for them', () {
      final List<Task> tasks = <Task>[
        task(id: 'a'),
        task(id: 'b', archived: true),
      ];

      expect(
        TaskQueryEngine.filter(tasks, const TaskQuery()).map((Task t) => t.id),
        <String>['a'],
      );
      expect(
        TaskQueryEngine.filter(
          tasks,
          const TaskQuery(includeArchived: true),
        ).map((Task t) => t.id),
        <String>['b'],
      );
    });

    test('matches status, priority, assignee and label filters', () {
      final List<Task> tasks = <Task>[
        task(
          id: 'match',
          status: TaskStatus.inProgress,
          priority: TaskPriority.urgent,
          assigneeId: 'usr_1',
          labelIds: <String>['lbl_a'],
        ),
        task(id: 'wrong-status', status: TaskStatus.done),
        task(id: 'wrong-priority', status: TaskStatus.inProgress),
      ];

      final List<Task> result = TaskQueryEngine.filter(
        tasks,
        const TaskQuery(
          statuses: <TaskStatus>{TaskStatus.inProgress},
          priorities: <TaskPriority>{TaskPriority.urgent},
          assigneeIds: <String>{'usr_1'},
          labelIds: <String>{'lbl_a'},
        ),
      );

      expect(result.map((Task t) => t.id), <String>['match']);
    });

    test('onlyUnassigned and assignee filters do not contradict', () {
      final List<Task> tasks = <Task>[
        task(id: 'unassigned'),
        task(id: 'assigned', assigneeId: 'usr_1'),
      ];

      expect(
        TaskQueryEngine.filter(
          tasks,
          const TaskQuery(onlyUnassigned: true),
        ).map((Task t) => t.id),
        <String>['unassigned'],
      );
    });

    test('search matches title and description fuzzily', () {
      final List<Task> tasks = <Task>[
        task(id: 'a', title: 'Finalize onboarding flow'),
        task(id: 'b', title: 'Create pricing page'),
      ];

      expect(
        TaskQueryEngine.filter(
          tasks,
          const TaskQuery(searchText: 'onboard'),
        ).map((Task t) => t.id),
        <String>['a'],
      );
      // Subsequence match: 'fnbrd' hits "FiNalize onBoaRDing".
      expect(
        TaskQueryEngine.filter(
          tasks,
          const TaskQuery(searchText: 'fnbrd'),
        ).map((Task t) => t.id),
        <String>['a'],
      );
    });

    test('onlyOverdue keeps past-due, incomplete tasks', () {
      final List<Task> tasks = <Task>[
        task(id: 'overdue', dueDate: today.subtract(const Duration(days: 2))),
        task(
          id: 'done-late',
          status: TaskStatus.done,
          dueDate: today.subtract(const Duration(days: 2)),
        ),
        task(id: 'future', dueDate: today.add(const Duration(days: 2))),
      ];

      expect(
        TaskQueryEngine.filter(
          tasks,
          const TaskQuery(onlyOverdue: true),
        ).map((Task t) => t.id),
        <String>['overdue'],
      );
    });
  });

  group('sort', () {
    test('undated tasks sort last regardless of direction', () {
      final List<Task> tasks = <Task>[
        task(id: 'none'),
        task(id: 'soon', dueDate: today.add(const Duration(days: 1))),
        task(id: 'later', dueDate: today.add(const Duration(days: 9))),
      ];

      final List<Task> ascending = TaskQueryEngine.sort(
        tasks,
        const TaskQuery(sortField: TaskSortField.dueDate),
      );
      expect(ascending.last.id, 'none');
    });

    test('priority sorts most urgent first', () {
      final List<Task> tasks = <Task>[
        task(id: 'low', priority: TaskPriority.low),
        task(id: 'urgent', priority: TaskPriority.urgent),
        task(id: 'medium', priority: TaskPriority.medium),
      ];

      expect(
        TaskQueryEngine.sort(
          tasks,
          const TaskQuery(sortField: TaskSortField.priority),
        ).first.id,
        'urgent',
      );
    });

    test('manual sort respects sortIndex and is stable', () {
      final List<Task> tasks = <Task>[
        task(id: 'c', sortIndex: 2),
        task(id: 'a', sortIndex: 0),
        task(id: 'b', sortIndex: 1),
      ];

      expect(
        TaskQueryEngine.sort(tasks, const TaskQuery()).map((Task t) => t.id),
        <String>['a', 'b', 'c'],
      );
    });
  });

  group('group', () {
    test('status grouping returns columns in workflow order', () {
      final List<Task> tasks = <Task>[
        task(id: 'done', status: TaskStatus.done),
        task(id: 'backlog', status: TaskStatus.backlog),
        task(id: 'progress', status: TaskStatus.inProgress),
      ];

      final List<TaskGroup<Task>> groups = TaskQueryEngine.group(
        tasks,
        const TaskQuery(),
        labelFor: (TaskGrouping grouping, String key) => key,
      );

      expect(groups.map((TaskGroup<Task> g) => g.key), <String>[
        'backlog',
        'inProgress',
        'done',
      ]);
    });

    test('project grouping puts unassigned projects last', () {
      final List<Task> tasks = <Task>[
        task(id: 'none'),
        task(id: 'in-project', projectId: 'prj_1'),
      ];

      final List<TaskGroup<Task>> groups = TaskQueryEngine.group(
        tasks,
        const TaskQuery(grouping: TaskGrouping.project),
        labelFor: (TaskGrouping grouping, String key) => key,
      );

      expect(groups.last.key, '__none__');
    });

    test('due-date grouping buckets overdue, today and later separately', () {
      final List<Task> tasks = <Task>[
        task(id: 'overdue', dueDate: today.subtract(const Duration(days: 1))),
        task(id: 'today', dueDate: today),
        task(id: 'later', dueDate: today.add(const Duration(days: 20))),
      ];

      final List<TaskGroup<Task>> groups = TaskQueryEngine.group(
        tasks,
        const TaskQuery(grouping: TaskGrouping.dueDate),
        labelFor: (TaskGrouping grouping, String key) => key,
      );

      expect(groups.first.key, 'a_overdue');
      expect(groups[1].key, 'b_today');
    });
  });

  group('dependencies', () {
    test('detects a direct cycle', () {
      expect(
        TaskQueryEngine.wouldCreateCycle(
          taskId: 'a',
          dependsOnId: 'b',
          dependencies: <String, List<String>>{
            'b': <String>['a'],
          },
        ),
        isTrue,
      );
    });

    test('detects an indirect cycle through a chain', () {
      expect(
        TaskQueryEngine.wouldCreateCycle(
          taskId: 'a',
          dependsOnId: 'c',
          dependencies: <String, List<String>>{
            'c': <String>['b'],
            'b': <String>['a'],
          },
        ),
        isTrue,
      );
    });

    test('allows an edge that keeps the graph acyclic', () {
      expect(
        TaskQueryEngine.wouldCreateCycle(
          taskId: 'a',
          dependsOnId: 'b',
          dependencies: <String, List<String>>{
            'b': <String>['c'],
          },
        ),
        isFalse,
      );
    });

    test('a task cannot depend on itself', () {
      expect(
        TaskQueryEngine.wouldCreateCycle(
          taskId: 'a',
          dependsOnId: 'a',
          dependencies: const <String, List<String>>{},
        ),
        isTrue,
      );
    });

    test('blockedBy derives the reverse edge', () {
      final List<Task> tasks = <Task>[
        task(id: 'a'),
        task(id: 'b', dependsOn: <String>['a']),
        task(id: 'c', dependsOn: <String>['a']),
      ];

      expect(TaskQueryEngine.blockedBy('a', tasks), <String>['b', 'c']);
    });
  });
}
