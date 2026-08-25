import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/env/app_environment.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/repositories/analytics_repository_impl.dart';
import 'package:kairo/data/repositories/auth_repository_impl.dart';
import 'package:kairo/data/repositories/collaboration_repository_impl.dart';
import 'package:kairo/data/repositories/focus_repository_impl.dart';
import 'package:kairo/data/repositories/project_repository_impl.dart';
import 'package:kairo/data/repositories/search_repository_impl.dart';
import 'package:kairo/data/repositories/task_repository_impl.dart';
import 'package:kairo/data/repositories/workspace_repository_impl.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// The composition root.
///
/// Only the four leaf providers below are ever overridden (in `bootstrap.dart`
/// for the app, in `test/support` for tests). Everything else is wired from
/// them, so swapping the local stack for an HTTP one is a change to this file
/// and nothing above it.

final Provider<AppEnvironment> environmentProvider = Provider<AppEnvironment>(
  (Ref ref) =>
      throw UnimplementedError('environmentProvider must be overridden'),
);

final Provider<DocumentStore> documentStoreProvider = Provider<DocumentStore>(
  (Ref ref) =>
      throw UnimplementedError('documentStoreProvider must be overridden'),
);

final Provider<SettingsStore> settingsStoreProvider = Provider<SettingsStore>(
  (Ref ref) =>
      throw UnimplementedError('settingsStoreProvider must be overridden'),
);

final Provider<SecretStore> secretStoreProvider = Provider<SecretStore>(
  (Ref ref) => SecretStore(),
);

final Provider<KairoDatabase> databaseProvider = Provider<KairoDatabase>((
  Ref ref,
) {
  final KairoDatabase database = KairoDatabase(
    documents: ref.watch(documentStoreProvider),
    settings: ref.watch(settingsStoreProvider),
    environment: ref.watch(environmentProvider),
  );
  ref.onDispose(database.dispose);
  return database;
});

// --- Repositories -----------------------------------------------------------

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => LocalAuthRepository(
        database: ref.watch(databaseProvider),
        settings: ref.watch(settingsStoreProvider),
        secrets: ref.watch(secretStoreProvider),
      ),
    );

/// Who is performing a mutation. Repositories take this as a callback rather
/// than a value so they never hold a stale user after a sign-in.
String _actorId(Ref ref) =>
    ref.read(authRepositoryProvider).currentUser?.id ?? DemoSeed.demoUserId;

final Provider<WorkspaceRepository> workspaceRepositoryProvider =
    Provider<WorkspaceRepository>(
      (Ref ref) => LocalWorkspaceRepository(
        database: ref.watch(databaseProvider),
        settings: ref.watch(settingsStoreProvider),
      ),
    );

final Provider<ProjectRepository> projectRepositoryProvider =
    Provider<ProjectRepository>(
      (Ref ref) => LocalProjectRepository(
        database: ref.watch(databaseProvider),
        actorId: () => _actorId(ref),
      ),
    );

final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>(
      (Ref ref) => LocalTaskRepository(
        database: ref.watch(databaseProvider),
        actorId: () => _actorId(ref),
      ),
    );

final Provider<CommentRepository> commentRepositoryProvider =
    Provider<CommentRepository>(
      (Ref ref) =>
          LocalCommentRepository(database: ref.watch(databaseProvider)),
    );

final Provider<ActivityRepository> activityRepositoryProvider =
    Provider<ActivityRepository>(
      (Ref ref) =>
          LocalActivityRepository(database: ref.watch(databaseProvider)),
    );

final Provider<NotificationRepository> notificationRepositoryProvider =
    Provider<NotificationRepository>(
      (Ref ref) =>
          LocalNotificationRepository(database: ref.watch(databaseProvider)),
    );

final Provider<SearchRepository> searchRepositoryProvider =
    Provider<SearchRepository>(
      (Ref ref) => LocalSearchRepository(
        database: ref.watch(databaseProvider),
        settings: ref.watch(settingsStoreProvider),
      ),
    );

final Provider<AnalyticsRepository> analyticsRepositoryProvider =
    Provider<AnalyticsRepository>(
      (Ref ref) =>
          LocalAnalyticsRepository(database: ref.watch(databaseProvider)),
    );

final Provider<FocusRepository> focusRepositoryProvider =
    Provider<FocusRepository>(
      (Ref ref) => LocalFocusRepository(database: ref.watch(databaseProvider)),
    );

final Provider<PreferencesRepository> preferencesRepositoryProvider =
    Provider<PreferencesRepository>(
      (Ref ref) => LocalPreferencesRepository(
        settings: ref.watch(settingsStoreProvider),
      ),
    );
