/// Domain enumerations.
///
/// These are pure Dart with no Flutter import — colours, icons and labels for
/// each value are resolved in the presentation layer so the domain never knows
/// what blue looks like.
library;

/// Where a task sits in the workflow. Order matters: it drives Kanban column
/// order, list grouping order and the "advance to next status" action.
enum TaskStatus {
  backlog,
  todo,
  inProgress,
  review,
  done;

  bool get isDone => this == TaskStatus.done;
  bool get isActive =>
      this == TaskStatus.inProgress || this == TaskStatus.review;

  /// The status a task moves to when it is completed and when it is reopened.
  static const TaskStatus completed = TaskStatus.done;
  static const TaskStatus reopened = TaskStatus.todo;
}

/// Four levels, always paired with an icon and a label in the UI so the
/// information is never carried by colour alone.
enum TaskPriority {
  urgent,
  high,
  medium,
  low;

  /// Higher is more important — used for sorting.
  int get weight => TaskPriority.values.length - index;
}

enum ProjectStatus { planning, active, onHold, completed, archived }

enum WorkspaceRole {
  owner,
  admin,
  member,
  guest;

  bool get canManageWorkspace => this == owner || this == admin;
  bool get canEditContent => this != guest;
}

enum RecurrenceFrequency { none, daily, weekly, monthly, custom }

enum NotificationType {
  mention,
  assignment,
  comment,
  deadline,
  projectUpdate,
  taskCompleted,
}

/// Every meaningful mutation produces one of these, which is what powers the
/// task activity feed and the dashboard's recent-activity list.
enum ActivityType {
  taskCreated,
  taskCompleted,
  taskReopened,
  taskArchived,
  taskRestored,
  statusChanged,
  priorityChanged,
  assigneeChanged,
  dueDateChanged,
  labelAdded,
  labelRemoved,
  commentAdded,
  subtaskCompleted,
  dependencyAdded,
  projectCreated,
  projectUpdated,
  memberJoined,
}

enum TaskViewType { list, board, calendar, timeline }

enum TaskGrouping { none, status, priority, project, assignee, dueDate }

enum TaskSortField { manual, dueDate, priority, createdAt, updatedAt, title }

enum SortDirection {
  ascending,
  descending;

  SortDirection get flipped => this == ascending ? descending : ascending;
}

enum FocusPhase {
  focus,
  shortBreak,
  longBreak;

  bool get isBreak => this != FocusPhase.focus;
}

enum ThemePreference { light, dark, system }

enum InterfaceDensity { comfortable, compact }

/// What the user said they wanted to manage during onboarding. Used to pick
/// sensible defaults, not to gate features.
enum ProductivityGoal {
  personalWork,
  teamProjects,
  clientWork,
  studies,
  sideProject,
}

/// Resolves an enum from its persisted `name`, falling back safely so a value
/// added in a future version never crashes an older client.
T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
