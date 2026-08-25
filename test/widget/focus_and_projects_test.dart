import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/focus/application/focus_controller.dart';

import '../support/test_harness.dart';

/// Focus Mode's timer state machine, and project lifecycle rules.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create();
  });

  tearDown(() => harness.dispose());

  group('focus timer', () {
    test('starts idle at the configured focus length', () {
      final FocusState state = harness.container.read(focusControllerProvider);
      expect(state.status, FocusStatus.idle);
      expect(state.phase, FocusPhase.focus);
      expect(state.remaining, const Duration(minutes: 25));
      expect(state.progress, 0);
      expect(state.round, 1);
    });

    test('counts down while running and pauses in place', () {
      fakeAsync((FakeAsync async) {
        final FocusController controller = harness.container.read(
          focusControllerProvider.notifier,
        );

        controller.start();
        expect(
          harness.container.read(focusControllerProvider).isRunning,
          isTrue,
        );

        async.elapse(const Duration(seconds: 10));
        final Duration afterTen = harness.container
            .read(focusControllerProvider)
            .remaining;
        expect(afterTen, const Duration(minutes: 24, seconds: 50));

        controller.pause();
        async.elapse(const Duration(seconds: 30));
        expect(
          harness.container.read(focusControllerProvider).remaining,
          afterTen,
          reason: 'a paused timer must not tick',
        );
      });
    });

    test('rolls into a break when the focus phase completes', () {
      fakeAsync((FakeAsync async) {
        final FocusController controller = harness.container.read(
          focusControllerProvider.notifier,
        );

        controller.start();
        async.elapse(const Duration(minutes: 25, seconds: 1));

        final FocusState state = harness.container.read(
          focusControllerProvider,
        );
        expect(state.phase.isBreak, isTrue);
        expect(state.phase, FocusPhase.shortBreak);
      });
    });

    test(
      'a long break arrives after the configured number of rounds',
      () async {
        await harness.container
            .read(preferencesProvider.notifier)
            .update(
              (UserPreferences p) =>
                  p.copyWith(focus: p.focus.copyWith(roundsBeforeLongBreak: 2)),
            );

        final FocusController controller = harness.container.read(
          focusControllerProvider.notifier,
        );

        // Round 1 → short break → round 2 → long break.
        controller.skip();
        expect(
          harness.container.read(focusControllerProvider).phase,
          FocusPhase.shortBreak,
        );
        controller.skip();
        expect(
          harness.container.read(focusControllerProvider).phase,
          FocusPhase.focus,
        );
        expect(harness.container.read(focusControllerProvider).round, 2);
        controller.skip();
        expect(
          harness.container.read(focusControllerProvider).phase,
          FocusPhase.longBreak,
        );
      },
    );

    test('ending a session early records the elapsed minutes', () {
      fakeAsync((FakeAsync async) {
        final FocusController controller = harness.container.read(
          focusControllerProvider.notifier,
        );

        controller.selectTask('tsk_onboarding');
        controller.start();
        async.elapse(const Duration(minutes: 7));
        controller.stop();
        async.flushMicrotasks();

        final List<FocusSession> sessions = harness.database.focusSessions.value
            .where((FocusSession s) => s.taskId == 'tsk_onboarding')
            .toList();

        final FocusSession recorded = sessions.last;
        expect(recorded.actualMinutes, 7);
        expect(recorded.wasCompleted, isFalse);
        expect(
          harness.container.read(focusControllerProvider).status,
          FocusStatus.idle,
        );
      });
    });

    test('switching phase resets the countdown to that phase length', () {
      final FocusController controller = harness.container.read(
        focusControllerProvider.notifier,
      );

      controller.switchPhase(FocusPhase.longBreak);
      final FocusState state = harness.container.read(focusControllerProvider);
      expect(state.phase, FocusPhase.longBreak);
      expect(state.remaining, const Duration(minutes: 15));
      expect(state.status, FocusStatus.idle);
    });

    test('progress reaches 1 as the countdown empties', () {
      fakeAsync((FakeAsync async) {
        final FocusController controller = harness.container.read(
          focusControllerProvider.notifier,
        );
        controller.start();
        async.elapse(const Duration(minutes: 12, seconds: 30));
        expect(
          harness.container.read(focusControllerProvider).progress,
          closeTo(0.5, 0.02),
        );
        controller.stop();
      });
    });
  });

  group('projects', () {
    test('creating a project records it and an activity entry', () async {
      final DateTime now = DateTime.now();
      final Project created = await harness.container
          .read(projectRepositoryProvider)
          .createProject(
            Project(
              id: '',
              workspaceId: harness.workspaceId,
              name: 'Website Revamp v2',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(created.id, isNotEmpty);
      expect(created.name, 'Website Revamp v2');

      final List<Project> projects = await harness.container
          .read(projectRepositoryProvider)
          .watchProjects(harness.workspaceId)
          .first;
      expect(projects.any((Project p) => p.id == created.id), isTrue);
    });

    test('an unnamed project is refused', () async {
      final DateTime now = DateTime.now();
      expect(
        () => harness.container
            .read(projectRepositoryProvider)
            .createProject(
              Project(
                id: '',
                workspaceId: harness.workspaceId,
                name: '  ',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('deleting a project keeps its tasks', () async {
      final List<Task> before = await harness.container
          .read(taskRepositoryProvider)
          .watchTasks(harness.workspaceId)
          .first;
      final int launchTasks = before
          .where((Task t) => t.projectId == 'prj_launch')
          .length;
      expect(launchTasks, greaterThan(0));

      await harness.container
          .read(projectRepositoryProvider)
          .deleteProject('prj_launch');

      final List<Task> after = await harness.container
          .read(taskRepositoryProvider)
          .watchTasks(harness.workspaceId)
          .first;

      expect(after.length, before.length, reason: 'no task was deleted');
      expect(
        after.where((Task t) => t.projectId == 'prj_launch'),
        isEmpty,
        reason: 'tasks were detached from the project',
      );
    });

    test('archiving hides a project from the default list', () async {
      await harness.container
          .read(projectRepositoryProvider)
          .setArchived('prj_growth', archived: true);

      final List<Project> visible = await harness.container
          .read(projectRepositoryProvider)
          .watchProjects(harness.workspaceId)
          .first;
      expect(visible.any((Project p) => p.id == 'prj_growth'), isFalse);

      final List<Project> all = await harness.container
          .read(projectRepositoryProvider)
          .watchProjects(harness.workspaceId, includeArchived: true)
          .first;
      expect(all.any((Project p) => p.id == 'prj_growth'), isTrue);
    });

    test('project stats are derived from the task set', () async {
      final ProjectStats stats = await harness.container
          .read(projectRepositoryProvider)
          .statsFor('prj_launch');

      expect(stats.total, greaterThan(0));
      expect(stats.completed + stats.remaining, stats.total);
      expect(stats.progress, inInclusiveRange(0, 1));
    });
  });

  group('labels', () {
    test('deleting a label detaches it from every task', () async {
      final List<Task> before = await harness.container
          .read(taskRepositoryProvider)
          .watchTasks(harness.workspaceId)
          .first;
      expect(
        before.where((Task t) => t.labelIds.contains('lbl_eng')),
        isNotEmpty,
      );

      await harness.container
          .read(workspaceRepositoryProvider)
          .deleteLabel('lbl_eng');

      final List<Task> after = await harness.container
          .read(taskRepositoryProvider)
          .watchTasks(harness.workspaceId)
          .first;
      expect(after.where((Task t) => t.labelIds.contains('lbl_eng')), isEmpty);
    });

    test('a duplicate label name is refused', () async {
      expect(
        () => harness.container
            .read(workspaceRepositoryProvider)
            .createLabel(
              workspaceId: harness.workspaceId,
              name: 'design',
              colorValue: 0xFF3B6BF5,
            ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('notifications', () {
    test('mark all read clears the unread count', () async {
      final int before = harness.database.notifications.value
          .where((n) => !n.isRead && n.workspaceId == harness.workspaceId)
          .length;
      expect(before, greaterThan(0));

      await harness.container
          .read(notificationRepositoryProvider)
          .markAllRead(harness.workspaceId);

      final int after = harness.database.notifications.value
          .where((n) => !n.isRead && n.workspaceId == harness.workspaceId)
          .length;
      expect(after, 0);
    });
  });
}
