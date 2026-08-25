import 'package:flutter/widgets.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/kairo_colors.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Presentation for domain enums — the one place a [TaskStatus] becomes a
/// colour, an icon and a word.
///
/// The domain deliberately knows none of this. Everything here goes through the
/// theme extension, so statuses and priorities restyle with the rest of the
/// product when the theme changes.

extension TaskStatusPresentation on TaskStatus {
  String label(AppL10n l10n) => switch (this) {
    TaskStatus.backlog => l10n.statusBacklog,
    TaskStatus.todo => l10n.statusTodo,
    TaskStatus.inProgress => l10n.statusInProgress,
    TaskStatus.review => l10n.statusReview,
    TaskStatus.done => l10n.statusDone,
  };

  IconData get icon => switch (this) {
    TaskStatus.backlog => AppIcons.statusBacklog,
    TaskStatus.todo => AppIcons.statusTodo,
    TaskStatus.inProgress => AppIcons.statusInProgress,
    TaskStatus.review => AppIcons.statusReview,
    TaskStatus.done => AppIcons.statusDone,
  };

  Color color(KairoColors colors) => switch (this) {
    TaskStatus.backlog => colors.statusBacklog,
    TaskStatus.todo => colors.statusTodo,
    TaskStatus.inProgress => colors.statusInProgress,
    TaskStatus.review => colors.statusReview,
    TaskStatus.done => colors.statusDone,
  };
}

extension TaskPriorityPresentation on TaskPriority {
  String label(AppL10n l10n) => switch (this) {
    TaskPriority.urgent => l10n.priorityUrgent,
    TaskPriority.high => l10n.priorityHigh,
    TaskPriority.medium => l10n.priorityMedium,
    TaskPriority.low => l10n.priorityLow,
  };

  /// A distinct glyph per level so priority is never carried by colour alone.
  IconData get icon => switch (this) {
    TaskPriority.urgent => AppIcons.priorityUrgent,
    TaskPriority.high => AppIcons.priorityHigh,
    TaskPriority.medium => AppIcons.priorityMedium,
    TaskPriority.low => AppIcons.priorityLow,
  };

  Color color(KairoColors colors) => switch (this) {
    TaskPriority.urgent => colors.priorityUrgent,
    TaskPriority.high => colors.priorityHigh,
    TaskPriority.medium => colors.priorityMedium,
    TaskPriority.low => colors.priorityLow,
  };

  /// Spoken by screen readers in place of the icon.
  String semanticLabel(AppL10n l10n) => '${l10n.fieldPriority}: ${label(l10n)}';
}

extension ProjectStatusPresentation on ProjectStatus {
  String label(AppL10n l10n) => switch (this) {
    ProjectStatus.planning => l10n.projectsStatusPlanning,
    ProjectStatus.active => l10n.projectsStatusActive,
    ProjectStatus.onHold => l10n.projectsStatusOnHold,
    ProjectStatus.completed => l10n.projectsStatusCompleted,
    ProjectStatus.archived => l10n.projectsStatusArchived,
  };

  Color color(KairoColors colors) => switch (this) {
    ProjectStatus.planning => colors.inkMuted,
    ProjectStatus.active => colors.brand,
    ProjectStatus.onHold => colors.warning,
    ProjectStatus.completed => colors.success,
    ProjectStatus.archived => colors.inkFaint,
  };
}

extension WorkspaceRolePresentation on WorkspaceRole {
  String label(AppL10n l10n) => switch (this) {
    WorkspaceRole.owner => l10n.workspaceRoleOwner,
    WorkspaceRole.admin => l10n.workspaceRoleAdmin,
    WorkspaceRole.member => l10n.workspaceRoleMember,
    WorkspaceRole.guest => l10n.workspaceRoleGuest,
  };
}

extension TaskViewPresentation on TaskViewType {
  String label(AppL10n l10n) => switch (this) {
    TaskViewType.list => l10n.tasksViewList,
    TaskViewType.board => l10n.tasksViewBoard,
    TaskViewType.calendar => l10n.tasksViewCalendar,
    TaskViewType.timeline => l10n.tasksViewTimeline,
  };

  IconData get icon => switch (this) {
    TaskViewType.list => AppIcons.viewList,
    TaskViewType.board => AppIcons.viewBoard,
    TaskViewType.calendar => AppIcons.viewCalendar,
    TaskViewType.timeline => AppIcons.viewTimeline,
  };
}

extension TaskGroupingPresentation on TaskGrouping {
  String label(AppL10n l10n) => switch (this) {
    TaskGrouping.none => l10n.tasksGroupNone,
    TaskGrouping.status => l10n.tasksGroupStatus,
    TaskGrouping.priority => l10n.tasksGroupPriority,
    TaskGrouping.project => l10n.tasksGroupProject,
    TaskGrouping.assignee => l10n.tasksGroupAssignee,
    TaskGrouping.dueDate => l10n.tasksGroupDueDate,
  };
}

extension TaskSortPresentation on TaskSortField {
  String label(AppL10n l10n) => switch (this) {
    TaskSortField.manual => l10n.tasksSortManual,
    TaskSortField.dueDate => l10n.tasksSortDueDate,
    TaskSortField.priority => l10n.tasksSortPriority,
    TaskSortField.createdAt => l10n.tasksSortCreated,
    TaskSortField.updatedAt => l10n.tasksSortUpdated,
    TaskSortField.title => l10n.tasksSortTitle,
  };
}

extension NotificationTypePresentation on NotificationType {
  IconData get icon => switch (this) {
    NotificationType.mention => AppIcons.comment,
    NotificationType.assignment => AppIcons.assignee,
    NotificationType.comment => AppIcons.comment,
    NotificationType.deadline => AppIcons.dueDate,
    NotificationType.projectUpdate => AppIcons.projects,
    NotificationType.taskCompleted => AppIcons.complete,
  };

  Color color(KairoColors colors) => switch (this) {
    NotificationType.mention => colors.violet,
    NotificationType.assignment => colors.brand,
    NotificationType.comment => colors.teal,
    NotificationType.deadline => colors.warning,
    NotificationType.projectUpdate => colors.inkMuted,
    NotificationType.taskCompleted => colors.success,
  };
}

extension ActivityTypePresentation on ActivityType {
  IconData get icon => switch (this) {
    ActivityType.taskCreated => AppIcons.add,
    ActivityType.taskCompleted => AppIcons.complete,
    ActivityType.taskReopened => AppIcons.retry,
    ActivityType.taskArchived => AppIcons.archive,
    ActivityType.taskRestored => AppIcons.retry,
    ActivityType.statusChanged => AppIcons.viewBoard,
    ActivityType.priorityChanged => AppIcons.priorityMedium,
    ActivityType.assigneeChanged => AppIcons.assignee,
    ActivityType.dueDateChanged => AppIcons.dueDate,
    ActivityType.labelAdded => AppIcons.label,
    ActivityType.labelRemoved => AppIcons.label,
    ActivityType.commentAdded => AppIcons.comment,
    ActivityType.subtaskCompleted => AppIcons.subtasks,
    ActivityType.dependencyAdded => AppIcons.dependency,
    ActivityType.projectCreated => AppIcons.projects,
    ActivityType.projectUpdated => AppIcons.projects,
    ActivityType.memberJoined => AppIcons.invite,
  };

  Color color(KairoColors colors) => switch (this) {
    ActivityType.taskCompleted ||
    ActivityType.subtaskCompleted => colors.success,
    ActivityType.taskArchived => colors.inkFaint,
    ActivityType.priorityChanged => colors.warning,
    ActivityType.dependencyAdded => colors.violet,
    ActivityType.commentAdded => colors.teal,
    _ => colors.brand,
  };
}

extension RecurrencePresentation on RecurrenceFrequency {
  String label(AppL10n l10n) => switch (this) {
    RecurrenceFrequency.none => l10n.recurrenceNone,
    RecurrenceFrequency.daily => l10n.recurrenceDaily,
    RecurrenceFrequency.weekly => l10n.recurrenceWeekly,
    RecurrenceFrequency.monthly => l10n.recurrenceMonthly,
    RecurrenceFrequency.custom => l10n.recurrenceCustom,
  };
}

extension ProductivityGoalPresentation on ProductivityGoal {
  String get label => switch (this) {
    ProductivityGoal.personalWork => 'My own work',
    ProductivityGoal.teamProjects => 'Team projects',
    ProductivityGoal.clientWork => 'Client work',
    ProductivityGoal.studies => 'Studies',
    ProductivityGoal.sideProject => 'A side project',
  };

  String get description => switch (this) {
    ProductivityGoal.personalWork =>
      'A private workspace, list view by default.',
    ProductivityGoal.teamProjects =>
      'Projects, assignees and a board by default.',
    ProductivityGoal.clientWork => 'One project per client, timeline first.',
    ProductivityGoal.studies => 'Deadlines and recurring work, calendar first.',
    ProductivityGoal.sideProject => 'Lightweight setup, focus mode ready.',
  };

  IconData get icon => switch (this) {
    ProductivityGoal.personalWork => AppIcons.assignee,
    ProductivityGoal.teamProjects => AppIcons.members,
    ProductivityGoal.clientWork => AppIcons.projects,
    ProductivityGoal.studies => AppIcons.docs,
    ProductivityGoal.sideProject => AppIcons.launch,
  };

  /// The view this goal implies. Used to pick a sensible default rather than
  /// to lock anything down.
  TaskViewType get defaultView => switch (this) {
    ProductivityGoal.personalWork => TaskViewType.list,
    ProductivityGoal.teamProjects => TaskViewType.board,
    ProductivityGoal.clientWork => TaskViewType.timeline,
    ProductivityGoal.studies => TaskViewType.calendar,
    ProductivityGoal.sideProject => TaskViewType.list,
  };
}

/// Resolves a colour stored as an ARGB int, falling back to the brand blue.
Color colorFromValue(int? value, BuildContext context) =>
    value == null ? context.colors.brand : Color(value);
