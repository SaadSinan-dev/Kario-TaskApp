import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/core/widgets/completion_check.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_board_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_row.dart';

import '../support/test_harness.dart';

/// Widget-level coverage of the interactions people actually perform: reading
/// the list, completing a task, filtering, and switching to the board.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create();
  });

  tearDown(() => harness.dispose());

  Future<List<Task>> workspaceTasks() => harness.container
      .read(taskRepositoryProvider)
      .watchTasks(harness.workspaceId)
      .first;

  testWidgets('the task list renders seeded tasks', (
    WidgetTester tester,
  ) async {
    setSurface(tester, Surfaces.desktop);
    final List<Task> tasks = await workspaceTasks();
    final List<Task> visible = tasks
        .where((Task t) => !t.isArchived)
        .take(8)
        .toList();

    await tester.pumpWidget(
      wrapForTest(
        TaskListView(tasks: visible, onOpenTask: (_) {}),
        container: harness.container,
      ),
    );
    await tester.pump();

    expect(find.byType(TaskRow), findsWidgets);
    expect(find.text(visible.first.title), findsOneWidget);
  });

  testWidgets('tapping the checkbox completes a task', (
    WidgetTester tester,
  ) async {
    setSurface(tester, Surfaces.desktop);
    final List<Task> tasks = await workspaceTasks();
    final Task open = tasks.firstWhere(
      (Task t) => !t.isDone && !t.isArchived && t.dependsOnIds.isEmpty,
    );

    await tester.pumpWidget(
      wrapForTest(
        TaskListView(tasks: <Task>[open], onOpenTask: (_) {}),
        container: harness.container,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CompletionCheckbox).first);
    await tester.pump();
    // Persistence is debounced; advance past the window so the write lands.
    await tester.pump(const Duration(milliseconds: 400));

    final Task? after = await harness.container
        .read(taskRepositoryProvider)
        .findTask(open.id);
    expect(after!.isDone, isTrue);

    // Completing raises an undo toast whose auto-dismiss timer would still be
    // pending at teardown. Dismissing it is the same path the close button
    // takes.
    harness.container.read(toastProvider.notifier).clear();
    await tester.pump();
  });

  testWidgets('an empty list shows the designed empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        TaskListView(tasks: const <Task>[], onOpenTask: (_) {}),
        container: harness.container,
      ),
    );
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No loose ends'), findsOneWidget);
  });

  testWidgets('the loading state shows skeletons, not a spinner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        TaskListView(
          tasks: const <Task>[],
          isLoading: true,
          onOpenTask: (_) {},
        ),
        container: harness.container,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppEmptyState), findsNothing);
  });

  testWidgets('the board renders one column per status', (
    WidgetTester tester,
  ) async {
    setSurface(tester, Surfaces.desktop);
    final List<Task> tasks = await workspaceTasks();

    await tester.pumpWidget(
      wrapForTest(
        TaskBoardView(
          tasks: tasks.where((Task t) => !t.isArchived).toList(),
          onOpenTask: (_) {},
        ),
        container: harness.container,
      ),
    );
    await tester.pump();

    for (final String label in <String>[
      'Backlog',
      'To Do',
      'In Progress',
      'Review',
      'Done',
    ]) {
      expect(find.text(label), findsWidgets, reason: 'column "$label"');
    }
    expect(find.byType(BoardCard), findsWidgets);
  });

  testWidgets('board cards are draggable', (WidgetTester tester) async {
    setSurface(tester, Surfaces.desktop);
    final List<Task> tasks = await workspaceTasks();

    await tester.pumpWidget(
      wrapForTest(
        TaskBoardView(
          tasks: tasks.where((Task t) => !t.isArchived).toList(),
          onOpenTask: (_) {},
        ),
        container: harness.container,
      ),
    );
    await tester.pump();

    // The payload type is private to the board, so match on the base class.
    expect(find.byWidgetPredicate((Widget w) => w is Draggable), findsWidgets);
    expect(find.byWidgetPredicate((Widget w) => w is DragTarget), findsWidgets);
  });

  group('filtering', () {
    test('the query controller narrows the visible task list', () async {
      final TaskQueryController controller = harness.container.read(
        taskQueryProvider.notifier,
      );

      final int unfiltered = harness.container
          .read(filteredTasksProvider)
          .length;
      expect(unfiltered, greaterThan(0));

      controller.toggleStatus(TaskStatus.done);
      final List<Task> onlyDone = harness.container.read(filteredTasksProvider);
      expect(onlyDone, isNotEmpty);
      expect(onlyDone.every((Task t) => t.isDone), isTrue);
      expect(onlyDone.length, lessThan(unfiltered));

      controller.clearFilters();
      expect(harness.container.read(filteredTasksProvider).length, unfiltered);
    });

    test('search narrows the list and ranks the literal match in', () async {
      final TaskQueryController controller = harness.container.read(
        taskQueryProvider.notifier,
      );
      final int unfiltered = harness.container
          .read(filteredTasksProvider)
          .length;

      controller.setSearch('onboarding');
      final List<Task> results = harness.container.read(filteredTasksProvider);

      // Matching is fuzzy by design — a subsequence hit is a valid result — so
      // the contract is "narrows the list and contains the obvious match",
      // not "every row contains the literal substring".
      expect(results, isNotEmpty);
      expect(results.length, lessThan(unfiltered));
      expect(
        results.any((Task t) => t.title == 'Finalize onboarding flow'),
        isTrue,
      );
    });

    test('clearing filters keeps the view configuration', () async {
      final TaskQueryController controller = harness.container.read(
        taskQueryProvider.notifier,
      );
      controller.setGrouping(TaskGrouping.priority);
      controller.toggleStatus(TaskStatus.done);
      controller.clearFilters();

      final TaskQuery query = harness.container.read(taskQueryProvider);
      expect(query.grouping, TaskGrouping.priority);
      expect(query.hasActiveFilters, isFalse);
    });
  });

  group('search repository', () {
    test('finds tasks, projects and people by name', () async {
      final SearchRepository search = harness.container.read(
        searchRepositoryProvider,
      );

      final List<SearchHit> tasks = await search.search(
        harness.workspaceId,
        'onboarding',
      );
      expect(tasks.any((SearchHit h) => h.kind == SearchHitKind.task), isTrue);

      final List<SearchHit> projects = await search.search(
        harness.workspaceId,
        'Product Launch',
      );
      expect(
        projects.any((SearchHit h) => h.kind == SearchHitKind.project),
        isTrue,
      );

      final List<SearchHit> people = await search.search(
        harness.workspaceId,
        'Priya',
      );
      expect(
        people.any((SearchHit h) => h.kind == SearchHitKind.member),
        isTrue,
      );
    });

    test('an empty query returns nothing rather than everything', () async {
      final List<SearchHit> hits = await harness.container
          .read(searchRepositoryProvider)
          .search(harness.workspaceId, '   ');
      expect(hits, isEmpty);
    });

    test('recent queries are remembered and clearable', () async {
      final SearchRepository search = harness.container.read(
        searchRepositoryProvider,
      );
      await search.rememberQuery('pricing');
      expect(await search.recentQueries(), contains('pricing'));

      await search.clearRecentQueries();
      expect(await search.recentQueries(), isEmpty);
    });
  });

  group('design system', () {
    testWidgets('a button shows a spinner and blocks input while loading', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        wrapForTest(
          Center(
            child: AppButton.primary(
              label: 'Save',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
          container: harness.container,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('priority is conveyed by icon as well as colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PriorityPill(priority: TaskPriority.urgent),
                PriorityPill(priority: TaskPriority.low),
              ],
            ),
          ),
          container: harness.container,
        ),
      );
      await tester.pump();

      // Distinct glyphs, so the level survives greyscale.
      final Iterable<Icon> icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.map((Icon i) => i.icon).toSet().length, 2);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });
  });
}
