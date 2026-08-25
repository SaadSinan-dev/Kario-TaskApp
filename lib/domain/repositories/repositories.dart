import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/productivity.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';

/// The contracts between the application layer and whatever is storing data.
///
/// Everything above these interfaces (controllers, widgets) is written against
/// the abstraction; everything below (`data/`) is an implementation detail. The
/// shipped implementation is local-first — swapping in an HTTP-backed one is a
/// change to `data/` and one provider override, with no UI edits.
///
/// Read APIs expose `Stream`s so the UI reacts to writes from anywhere in the
/// app (a drag on the board, a keyboard shortcut, an undo) without manual
/// invalidation.

abstract interface class AuthRepository {
  /// Emits the signed-in user, or null when signed out. Replays the current
  /// value to new listeners.
  Stream<User?> watchCurrentUser();

  User? get currentUser;

  Future<User> signIn({required String email, required String password});

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Signs into the read-only demo workspace without creating an account.
  Future<User> signInAsDemo();

  Future<void> signOut();

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({required String token, required String password});

  Future<void> verifyEmail(String code);

  Future<void> resendVerificationCode();

  Future<User> updateProfile(User user);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

abstract interface class WorkspaceRepository {
  Stream<List<Workspace>> watchWorkspaces();

  Stream<Workspace?> watchActiveWorkspace();

  Future<void> setActiveWorkspace(String workspaceId);

  Future<Workspace> createWorkspace({
    required String name,
    required String ownerId,
    String description,
    String iconEmoji,
  });

  Future<Workspace> updateWorkspace(Workspace workspace);

  Future<void> inviteMember({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  });

  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  });

  Future<void> changeMemberRole({
    required String workspaceId,
    required String userId,
    required WorkspaceRole role,
  });

  Stream<List<User>> watchMembers(String workspaceId);

  Stream<List<Label>> watchLabels(String workspaceId);

  Future<Label> createLabel({
    required String workspaceId,
    required String name,
    required int colorValue,
  });

  Future<Label> updateLabel(Label label);

  Future<void> deleteLabel(String labelId);

  /// Restores the demo workspace to its seeded state.
  Future<void> resetDemoData();

  /// Full workspace export as JSON — used by Settings → Data.
  Future<Map<String, dynamic>> exportWorkspace(String workspaceId);
}

abstract interface class ProjectRepository {
  Stream<List<Project>> watchProjects(
    String workspaceId, {
    bool includeArchived,
  });

  Stream<Project?> watchProject(String projectId);

  Future<Project?> findProject(String projectId);

  Future<Project> createProject(Project draft);

  Future<Project> updateProject(Project project);

  Future<void> deleteProject(String projectId);

  Future<Project> setArchived(String projectId, {required bool archived});

  Future<Project> toggleFavorite(String projectId);

  Future<void> reorderProjects(List<String> orderedIds);

  Future<ProjectStats> statsFor(String projectId);

  Future<Milestone> upsertMilestone(String projectId, Milestone milestone);

  Future<void> deleteMilestone(String projectId, String milestoneId);
}

abstract interface class TaskRepository {
  /// All non-archived tasks in the workspace. Views apply [TaskQuery] on top
  /// via `TaskQueryEngine` so filtering never round-trips through storage.
  Stream<List<Task>> watchTasks(String workspaceId);

  Stream<Task?> watchTask(String taskId);

  Future<Task?> findTask(String taskId);

  Future<Task> createTask(Task draft);

  Future<Task> updateTask(Task task);

  Future<void> deleteTask(String taskId);

  /// Completes or reopens. Completing a recurring task also schedules its next
  /// occurrence — the rule lives in the repository so every entry point
  /// (checkbox, keyboard shortcut, board drag) behaves identically.
  Future<Task> setCompleted(String taskId, {required bool completed});

  Future<Task> setStatus(String taskId, TaskStatus status);

  Future<Task> setArchived(String taskId, {required bool archived});

  Future<Task> toggleFavorite(String taskId);

  Future<Task> duplicateTask(String taskId);

  /// Moves a task into [status] at [targetIndex] within that column,
  /// renumbering siblings. Used by Kanban drag-and-drop.
  Future<void> moveTask({
    required String taskId,
    required TaskStatus status,
    required int targetIndex,
  });

  Future<void> reorderWithin(TaskStatus status, List<String> orderedIds);

  /// Throws [ConflictFailure] when the edge would create a cycle.
  Future<Task> addDependency({
    required String taskId,
    required String dependsOnId,
  });

  Future<Task> removeDependency({
    required String taskId,
    required String dependsOnId,
  });

  Future<Task> upsertSubtask(String taskId, Subtask subtask);

  Future<Task> deleteSubtask(String taskId, String subtaskId);

  Future<Task> reorderSubtasks(String taskId, List<String> orderedIds);

  /// Bulk operations from the list view's multi-select toolbar.
  Future<void> bulkUpdate({
    required List<String> taskIds,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? projectId,
    DateTime? dueDate,
    bool? archived,
  });

  Future<void> bulkDelete(List<String> taskIds);
}

abstract interface class CommentRepository {
  Stream<List<Comment>> watchComments(String taskId);

  Future<Comment> addComment({
    required String taskId,
    required String authorId,
    required String body,
    String? replyToId,
    List<String> mentionedUserIds,
  });

  Future<Comment> editComment(String commentId, String body);

  Future<void> deleteComment(String commentId);

  Future<Comment> toggleReaction({
    required String commentId,
    required String emoji,
    required String userId,
  });
}

abstract interface class ActivityRepository {
  Stream<List<Activity>> watchWorkspaceActivity(
    String workspaceId, {
    int limit,
  });

  Stream<List<Activity>> watchTaskActivity(String taskId);

  Stream<List<Activity>> watchProjectActivity(String projectId, {int limit});
}

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String workspaceId);

  Future<void> markRead(String notificationId);

  Future<void> markAllRead(String workspaceId);

  Future<void> clearAll(String workspaceId);
}

/// A single result row from global search, already scored and highlighted.
class SearchHit {
  const SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    required this.score,
    required this.matchedPositions,
    this.subtitle = '',
    this.accentColorValue,
    this.taskId,
    this.projectId,
  });

  final String id;
  final SearchHitKind kind;
  final String title;
  final String subtitle;
  final int score;

  /// Indices into [title] that matched the query, for inline highlighting.
  final List<int> matchedPositions;

  final int? accentColorValue;
  final String? taskId;
  final String? projectId;
}

enum SearchHitKind { task, project, member, label, comment }

abstract interface class SearchRepository {
  Future<List<SearchHit>> search(String workspaceId, String query);

  Future<List<String>> recentQueries();

  Future<void> rememberQuery(String query);

  Future<void> clearRecentQueries();

  /// Recently opened tasks and projects, most recent first.
  Future<List<SearchHit>> recentlyViewed(String workspaceId);

  Future<void> rememberViewed({
    required String workspaceId,
    required String id,
    required SearchHitKind kind,
  });
}

abstract interface class AnalyticsRepository {
  /// One computation feeding both the dashboard and the analytics screen.
  Stream<ProductivitySnapshot> watchSnapshot(String workspaceId, {int days});
}

abstract interface class FocusRepository {
  Stream<List<FocusSession>> watchSessions(String workspaceId);

  Future<void> recordSession(FocusSession session);

  Future<int> minutesToday(String workspaceId);
}

abstract interface class PreferencesRepository {
  Stream<UserPreferences> watchPreferences();

  UserPreferences get current;

  Future<void> save(UserPreferences preferences);
}
