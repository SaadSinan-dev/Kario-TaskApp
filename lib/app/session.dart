import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Application state that more than one feature needs.
///
/// Everything here is derived from a repository stream, so a write anywhere in
/// the app propagates to every screen without manual invalidation. Feature
/// specific state lives with its feature.

final StreamProvider<User?> currentUserProvider = StreamProvider<User?>(
  (Ref ref) => ref.watch(authRepositoryProvider).watchCurrentUser(),
);

/// Synchronous access for code paths that cannot await (route guards, the
/// actor id passed to repositories).
final Provider<User?> currentUserValueProvider = Provider<User?>(
  (Ref ref) => ref.watch(currentUserProvider).value,
);

final Provider<bool> isSignedInProvider = Provider<bool>(
  (Ref ref) => ref.watch(currentUserValueProvider) != null,
);

final StreamProvider<List<Workspace>> workspacesProvider =
    StreamProvider<List<Workspace>>(
      (Ref ref) => ref.watch(workspaceRepositoryProvider).watchWorkspaces(),
    );

final StreamProvider<Workspace?> activeWorkspaceProvider =
    StreamProvider<Workspace?>(
      (Ref ref) =>
          ref.watch(workspaceRepositoryProvider).watchActiveWorkspace(),
    );

/// The id every scoped provider below keys off. Falls back to the first
/// workspace so the app is never in a state with no workspace selected.
final Provider<String?> activeWorkspaceIdProvider = Provider<String?>((
  Ref ref,
) {
  final Workspace? active = ref.watch(activeWorkspaceProvider).value;
  if (active != null) return active.id;
  return ref.watch(workspacesProvider).value?.firstOrNull?.id;
});

final StreamProvider<List<User>> membersProvider = StreamProvider<List<User>>((
  Ref ref,
) {
  final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) return Stream<List<User>>.value(const <User>[]);
  return ref.watch(workspaceRepositoryProvider).watchMembers(workspaceId);
});

/// Fast lookup used by avatars, assignee pickers and mention rendering.
final Provider<Map<String, User>> membersByIdProvider =
    Provider<Map<String, User>>(
      (Ref ref) => <String, User>{
        for (final User user
            in ref.watch(membersProvider).value ?? const <User>[])
          user.id: user,
      },
    );

final StreamProvider<List<Label>> labelsProvider = StreamProvider<List<Label>>((
  Ref ref,
) {
  final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) return Stream<List<Label>>.value(const <Label>[]);
  return ref.watch(workspaceRepositoryProvider).watchLabels(workspaceId);
});

final Provider<Map<String, Label>> labelsByIdProvider =
    Provider<Map<String, Label>>(
      (Ref ref) => <String, Label>{
        for (final Label label
            in ref.watch(labelsProvider).value ?? const <Label>[])
          label.id: label,
      },
    );

final StreamProvider<List<Project>> projectsProvider =
    StreamProvider<List<Project>>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<List<Project>>.value(const <Project>[]);
      }
      return ref.watch(projectRepositoryProvider).watchProjects(workspaceId);
    });

final StreamProvider<List<Project>> allProjectsProvider =
    StreamProvider<List<Project>>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<List<Project>>.value(const <Project>[]);
      }
      return ref
          .watch(projectRepositoryProvider)
          .watchProjects(workspaceId, includeArchived: true);
    });

final Provider<Map<String, Project>> projectsByIdProvider =
    Provider<Map<String, Project>>(
      (Ref ref) => <String, Project>{
        for (final Project project
            in ref.watch(allProjectsProvider).value ?? const <Project>[])
          project.id: project,
      },
    );

/// Every non-archived task in the active workspace. Views filter this locally
/// through `TaskQueryEngine` rather than re-querying.
final StreamProvider<List<Task>> tasksProvider = StreamProvider<List<Task>>((
  Ref ref,
) {
  final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) return Stream<List<Task>>.value(const <Task>[]);
  return ref.watch(taskRepositoryProvider).watchTasks(workspaceId);
});

final taskByIdProvider = StreamProvider.family<Task?, String>(
  (Ref ref, String taskId) =>
      ref.watch(taskRepositoryProvider).watchTask(taskId),
);

final projectByIdProvider = StreamProvider.family<Project?, String>(
  (Ref ref, String projectId) =>
      ref.watch(projectRepositoryProvider).watchProject(projectId),
);

final commentsProvider = StreamProvider.family<List<Comment>, String>(
  (Ref ref, String taskId) =>
      ref.watch(commentRepositoryProvider).watchComments(taskId),
);

final taskActivityProvider = StreamProvider.family<List<Activity>, String>(
  (Ref ref, String taskId) =>
      ref.watch(activityRepositoryProvider).watchTaskActivity(taskId),
);

final StreamProvider<List<Activity>> workspaceActivityProvider =
    StreamProvider<List<Activity>>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<List<Activity>>.value(const <Activity>[]);
      }
      return ref
          .watch(activityRepositoryProvider)
          .watchWorkspaceActivity(workspaceId);
    });

final StreamProvider<List<AppNotification>> notificationsProvider =
    StreamProvider<List<AppNotification>>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<List<AppNotification>>.value(const <AppNotification>[]);
      }
      return ref
          .watch(notificationRepositoryProvider)
          .watchNotifications(workspaceId);
    });

final Provider<int> unreadNotificationCountProvider = Provider<int>(
  (Ref ref) =>
      (ref.watch(notificationsProvider).value ?? const <AppNotification>[])
          .where((AppNotification n) => !n.isRead)
          .length,
);

final StreamProvider<ProductivitySnapshot> snapshotProvider =
    StreamProvider<ProductivitySnapshot>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<ProductivitySnapshot>.value(ProductivitySnapshot.empty);
      }
      return ref.watch(analyticsRepositoryProvider).watchSnapshot(workspaceId);
    });

/// Preferences are exposed as a [Notifier] because every settings control
/// mutates them; the underlying repository persists on each change.
class PreferencesController extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    final PreferencesRepository repository = ref.watch(
      preferencesRepositoryProvider,
    );
    final subscription = repository.watchPreferences().listen((
      UserPreferences next,
    ) {
      state = next;
    });
    ref.onDispose(subscription.cancel);
    return repository.current;
  }

  Future<void> update(
    UserPreferences Function(UserPreferences current) transform,
  ) async {
    final UserPreferences next = transform(state);
    state = next;
    await ref.read(preferencesRepositoryProvider).save(next);
  }
}

final NotifierProvider<PreferencesController, UserPreferences>
preferencesProvider = NotifierProvider<PreferencesController, UserPreferences>(
  PreferencesController.new,
);
