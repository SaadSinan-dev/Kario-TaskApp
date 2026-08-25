import 'package:kairo/domain/entities/enums.dart';
import 'package:meta/meta.dart';

/// A declarative description of "which tasks, in what order".
///
/// Filtering, grouping and sorting all travel together as one value object so
/// the list, board, calendar and timeline views can share a single query
/// pipeline — and so a saved view is one object to persist.
@immutable
class TaskQuery {
  const TaskQuery({
    this.projectId,
    this.statuses = const <TaskStatus>{},
    this.priorities = const <TaskPriority>{},
    this.assigneeIds = const <String>{},
    this.labelIds = const <String>{},
    this.searchText = '',
    this.dueFrom,
    this.dueTo,
    this.includeArchived = false,
    this.onlyFavorites = false,
    this.onlyOverdue = false,
    this.onlyUnassigned = false,
    this.grouping = TaskGrouping.status,
    this.sortField = TaskSortField.manual,
    this.sortDirection = SortDirection.ascending,
  });

  final String? projectId;
  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final Set<String> assigneeIds;
  final Set<String> labelIds;
  final String searchText;
  final DateTime? dueFrom;
  final DateTime? dueTo;
  final bool includeArchived;
  final bool onlyFavorites;
  final bool onlyOverdue;
  final bool onlyUnassigned;

  final TaskGrouping grouping;
  final TaskSortField sortField;
  final SortDirection sortDirection;

  /// True when anything narrows the result set — drives the "clear filters"
  /// affordance and the filter-count badge.
  bool get hasActiveFilters =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      assigneeIds.isNotEmpty ||
      labelIds.isNotEmpty ||
      searchText.isNotEmpty ||
      dueFrom != null ||
      dueTo != null ||
      onlyFavorites ||
      onlyOverdue ||
      onlyUnassigned;

  int get activeFilterCount =>
      (statuses.isEmpty ? 0 : 1) +
      (priorities.isEmpty ? 0 : 1) +
      (assigneeIds.isEmpty ? 0 : 1) +
      (labelIds.isEmpty ? 0 : 1) +
      (dueFrom == null && dueTo == null ? 0 : 1) +
      (onlyFavorites ? 1 : 0) +
      (onlyOverdue ? 1 : 0) +
      (onlyUnassigned ? 1 : 0);

  TaskQuery copyWith({
    String? projectId,
    bool clearProject = false,
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<String>? assigneeIds,
    Set<String>? labelIds,
    String? searchText,
    DateTime? dueFrom,
    bool clearDueFrom = false,
    DateTime? dueTo,
    bool clearDueTo = false,
    bool? includeArchived,
    bool? onlyFavorites,
    bool? onlyOverdue,
    bool? onlyUnassigned,
    TaskGrouping? grouping,
    TaskSortField? sortField,
    SortDirection? sortDirection,
  }) {
    return TaskQuery(
      projectId: clearProject ? null : (projectId ?? this.projectId),
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      labelIds: labelIds ?? this.labelIds,
      searchText: searchText ?? this.searchText,
      dueFrom: clearDueFrom ? null : (dueFrom ?? this.dueFrom),
      dueTo: clearDueTo ? null : (dueTo ?? this.dueTo),
      includeArchived: includeArchived ?? this.includeArchived,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyOverdue: onlyOverdue ?? this.onlyOverdue,
      onlyUnassigned: onlyUnassigned ?? this.onlyUnassigned,
      grouping: grouping ?? this.grouping,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  /// Clears every filter but keeps the view configuration (grouping, sorting,
  /// project scope), which is what "Clear filters" should actually do.
  TaskQuery cleared() => TaskQuery(
    projectId: projectId,
    includeArchived: includeArchived,
    grouping: grouping,
    sortField: sortField,
    sortDirection: sortDirection,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskQuery &&
      other.projectId == projectId &&
      _sameSet(other.statuses, statuses) &&
      _sameSet(other.priorities, priorities) &&
      _sameSet(other.assigneeIds, assigneeIds) &&
      _sameSet(other.labelIds, labelIds) &&
      other.searchText == searchText &&
      other.dueFrom == dueFrom &&
      other.dueTo == dueTo &&
      other.includeArchived == includeArchived &&
      other.onlyFavorites == onlyFavorites &&
      other.onlyOverdue == onlyOverdue &&
      other.onlyUnassigned == onlyUnassigned &&
      other.grouping == grouping &&
      other.sortField == sortField &&
      other.sortDirection == sortDirection;

  @override
  int get hashCode => Object.hash(
    projectId,
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(priorities),
    Object.hashAllUnordered(assigneeIds),
    Object.hashAllUnordered(labelIds),
    searchText,
    dueFrom,
    dueTo,
    includeArchived,
    onlyFavorites,
    onlyOverdue,
    onlyUnassigned,
    grouping,
    sortField,
    sortDirection,
  );
}

/// A named bucket of tasks produced by grouping. Carries its own sort key so
/// groups render in a stable, meaningful order (statuses in workflow order,
/// priorities most-urgent first, dates chronologically).
@immutable
class TaskGroup<T> {
  const TaskGroup({
    required this.key,
    required this.label,
    required this.items,
    this.accentColorValue,
  });

  final String key;
  final String label;
  final List<T> items;
  final int? accentColorValue;

  int get count => items.length;
}

/// Set equality without a Flutter dependency.
///
/// `foundation.setEquals` would do the same job, but importing Flutter into the
/// domain layer to compare two sets is the kind of small concession that makes
/// a layer boundary decorative. Sets have no ordering, so equal length plus
/// containment is exact.
bool _sameSet<T>(Set<T> a, Set<T> b) =>
    identical(a, b) || (a.length == b.length && a.containsAll(b));
