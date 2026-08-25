import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/data/repositories/analytics_repository_impl.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/domain/repositories/repositories.dart';

import '../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authentication', () {
    late TestHarness harness;

    setUp(() async {
      harness = await TestHarness.create(signIn: false);
    });

    tearDown(() => harness.dispose());

    test('the demo account signs in with the published credentials', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      final User user = await auth.signIn(
        email: DemoSeed.demoEmail,
        password: DemoSeed.demoPassword,
      );

      expect(user.id, DemoSeed.demoUserId);
      expect(auth.currentUser, isNotNull);
    });

    test('a wrong password on the demo account is rejected', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      expect(
        () => auth.signIn(email: DemoSeed.demoEmail, password: 'wrong-one'),
        throwsA(
          isA<AuthFailure>().having(
            (AuthFailure f) => f.reason,
            'reason',
            AuthFailureReason.invalidCredentials,
          ),
        ),
      );
    });

    test('an unknown email reports an unknown account', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      expect(
        () => auth.signIn(email: 'nobody@kairo.app', password: 'demo1234'),
        throwsA(
          isA<AuthFailure>().having(
            (AuthFailure f) => f.reason,
            'reason',
            AuthFailureReason.unknownAccount,
          ),
        ),
      );
    });

    test('sign up creates a user and their own workspace', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      final User created = await auth.signUp(
        name: 'Riley Chen',
        email: 'riley@example.com',
        password: 'correct horse 9',
      );

      expect(created.name, 'Riley Chen');
      expect(created.isEmailVerified, isFalse);

      final List<Workspace> workspaces = await harness.container
          .read(workspaceRepositoryProvider)
          .watchWorkspaces()
          .first;
      expect(workspaces.any((Workspace w) => w.ownerId == created.id), isTrue);
    });

    test('signing up twice with the same email is refused', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      await auth.signUp(
        name: 'Riley Chen',
        email: 'riley@example.com',
        password: 'correct horse 9',
      );

      expect(
        () => auth.signUp(
          name: 'Riley Again',
          email: 'riley@example.com',
          password: 'another one 1',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (AuthFailure f) => f.reason,
            'reason',
            AuthFailureReason.emailAlreadyInUse,
          ),
        ),
      );
    });

    test('a password created at sign up works at sign in', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      await auth.signUp(
        name: 'Riley Chen',
        email: 'riley@example.com',
        password: 'correct horse 9',
      );
      await auth.signOut();
      expect(auth.currentUser, isNull);

      final User back = await auth.signIn(
        email: 'riley@example.com',
        password: 'correct horse 9',
      );
      expect(back.email, 'riley@example.com');

      expect(
        () => auth.signIn(
          email: 'riley@example.com',
          password: 'not the password',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('a short password is refused at sign up', () async {
      final AuthRepository auth = harness.container.read(
        authRepositoryProvider,
      );
      expect(
        () => auth.signUp(
          name: 'Short',
          email: 'short@example.com',
          password: 'abc',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (AuthFailure f) => f.reason,
            'reason',
            AuthFailureReason.weakPassword,
          ),
        ),
      );
    });
  });

  group('analytics', () {
    final DateTime today = DateTime(2026, 6, 15);

    Task task({
      required String id,
      TaskStatus status = TaskStatus.todo,
      TaskPriority priority = TaskPriority.medium,
      DateTime? due,
      DateTime? completed,
      String? projectId,
      int createdDaysAgo = 5,
    }) {
      return Task(
        id: id,
        workspaceId: 'wsp',
        title: id,
        status: status,
        priority: priority,
        projectId: projectId,
        dueDate: due,
        completedAt: completed,
        createdAt: today.subtract(Duration(days: createdDaysAgo)),
        updatedAt: today,
        createdById: 'usr',
      );
    }

    test('counts completed, remaining and overdue correctly', () {
      final ProductivitySnapshot snapshot = LocalAnalyticsRepository.compute(
        tasks: <Task>[
          task(id: 'done', status: TaskStatus.done, completed: today),
          task(id: 'open'),
          task(
            id: 'overdue',
            due: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ],
        sessions: const <FocusSession>[],
        projects: const <Project>[],
      );

      expect(snapshot.totalTasks, 3);
      expect(snapshot.completedTasks, 1);
      expect(snapshot.remainingTasks, 2);
      expect(snapshot.overdueTasks, 1);
    });

    test('an empty workspace scores zero rather than dividing by zero', () {
      final ProductivitySnapshot snapshot = LocalAnalyticsRepository.compute(
        tasks: const <Task>[],
        sessions: const <FocusSession>[],
        projects: const <Project>[],
      );

      expect(snapshot.completionRate, 0);
      expect(snapshot.overdueRate, 0);
      expect(snapshot.productivityScore, 0);
      expect(snapshot.daily, isNotEmpty);
    });

    test('the score rewards completion and punishes overdue work', () {
      final ProductivitySnapshot healthy = LocalAnalyticsRepository.compute(
        tasks: <Task>[
          for (int i = 0; i < 8; i++)
            task(
              id: 'done$i',
              status: TaskStatus.done,
              completed: DateTime.now(),
            ),
          task(id: 'open'),
        ],
        sessions: const <FocusSession>[],
        projects: const <Project>[],
      );

      final ProductivitySnapshot struggling = LocalAnalyticsRepository.compute(
        tasks: <Task>[
          task(id: 'done', status: TaskStatus.done, completed: DateTime.now()),
          for (int i = 0; i < 8; i++)
            task(
              id: 'late$i',
              due: DateTime.now().subtract(const Duration(days: 4)),
            ),
        ],
        sessions: const <FocusSession>[],
        projects: const <Project>[],
      );

      expect(
        healthy.productivityScore,
        greaterThan(struggling.productivityScore),
      );
      expect(healthy.productivityScore, inInclusiveRange(0, 100));
      expect(struggling.productivityScore, inInclusiveRange(0, 100));
    });

    test('focus minutes only count focus phases in range', () {
      final ProductivitySnapshot snapshot = LocalAnalyticsRepository.compute(
        tasks: <Task>[task(id: 'a')],
        sessions: <FocusSession>[
          FocusSession(
            id: 's1',
            workspaceId: 'wsp',
            phase: FocusPhase.focus,
            startedAt: DateTime.now(),
            plannedMinutes: 25,
            actualMinutes: 25,
          ),
          FocusSession(
            id: 's2',
            workspaceId: 'wsp',
            phase: FocusPhase.shortBreak,
            startedAt: DateTime.now(),
            plannedMinutes: 5,
            actualMinutes: 5,
          ),
        ],
        projects: const <Project>[],
      );

      expect(snapshot.focusMinutes, 25);
    });

    test('insights are derived, never empty for a live workspace', () {
      final ProductivitySnapshot snapshot = LocalAnalyticsRepository.compute(
        tasks: <Task>[
          task(id: 'done', status: TaskStatus.done, completed: DateTime.now()),
          task(
            id: 'urgent-soon',
            priority: TaskPriority.urgent,
            due: DateTime.now().add(const Duration(days: 1)),
          ),
        ],
        sessions: const <FocusSession>[],
        projects: const <Project>[],
      );

      expect(snapshot.insights, isNotEmpty);
      expect(
        snapshot.insights.any((Insight i) => i.message.contains('urgent')),
        isTrue,
      );
    });
  });
}
