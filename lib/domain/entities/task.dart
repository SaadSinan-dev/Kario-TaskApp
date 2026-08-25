import 'package:flutter/foundation.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';
import 'package:kairo/domain/entities/recurrence.dart';

/// A checklist item inside a task.
@immutable
class Subtask {
  const Subtask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.sortIndex = 0,
  });

  final String id;
  final String title;
  final bool isDone;
  final int sortIndex;

  Subtask copyWith({String? title, bool? isDone, int? sortIndex}) => Subtask(
    id: id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    sortIndex: sortIndex ?? this.sortIndex,
  );

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'isDone': isDone,
    'sortIndex': sortIndex,
  };

  factory Subtask.fromJson(JsonMap json) => Subtask(
    id: readString(json['id']),
    title: readString(json['title']),
    isDone: readBool(json['isDone']),
    sortIndex: readInt(json['sortIndex']),
  );
}

/// Metadata about a file attached to a task.
///
/// Kairo stores the descriptor only — uploading and serving bytes is a backend
/// concern, and modelling it now means the UI is ready the day storage exists.
@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploadedById,
    this.url,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final String mimeType;
  final DateTime uploadedAt;
  final String uploadedById;
  final String? url;

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'mimeType': mimeType,
    'uploadedAt': writeDate(uploadedAt),
    'uploadedById': uploadedById,
    'url': url,
  };

  factory Attachment.fromJson(JsonMap json) => Attachment(
    id: readString(json['id']),
    fileName: readString(json['fileName']),
    sizeBytes: readInt(json['sizeBytes']),
    mimeType: readString(json['mimeType'], 'application/octet-stream'),
    uploadedAt: readDateOr(json['uploadedAt'], DateTime.now()),
    uploadedById: readString(json['uploadedById']),
    url: json['url'] as String?,
  );
}

/// The unit of work.
///
/// Note what is *not* stored here: comments, activity and the reverse side of a
/// dependency all live in their own collections. Keeping the task document lean
/// means editing a title doesn't rewrite a hundred comments.
@immutable
class Task {
  const Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.createdById,
    this.projectId,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.assigneeId,
    this.labelIds = const <String>[],
    this.dueDate,
    this.startDate,
    this.estimateMinutes,
    this.subtasks = const <Subtask>[],
    this.dependsOnIds = const <String>[],
    this.attachments = const <Attachment>[],
    this.recurrence = RecurrenceRule.none,
    this.isArchived = false,
    this.isFavorite = false,
    this.sortIndex = 0,
    this.completedAt,
  });

  final String id;
  final String workspaceId;
  final String? projectId;
  final String title;

  /// Markdown. See `features/tasks/presentation/widgets/rich_text_editor.dart`
  /// for the editor and renderer — storing markdown keeps the document portable
  /// and diffable, and it round-trips to any backend without a custom format.
  final String description;

  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final List<String> labelIds;
  final DateTime? dueDate;
  final DateTime? startDate;
  final int? estimateMinutes;
  final List<Subtask> subtasks;

  /// Ids of tasks that must finish before this one can start.
  final List<String> dependsOnIds;

  final List<Attachment> attachments;
  final RecurrenceRule recurrence;
  final bool isArchived;
  final bool isFavorite;

  /// Position within its Kanban column / manual list order.
  final int sortIndex;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String createdById;

  bool get isDone => status.isDone;

  bool get isOverdue {
    final DateTime? due = dueDate;
    if (due == null || isDone || isArchived) return false;
    final DateTime today = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  bool get hasSubtasks => subtasks.isNotEmpty;
  int get completedSubtaskCount =>
      subtasks.where((Subtask s) => s.isDone).length;

  /// 0…1 across subtasks, or the task's own binary state when it has none.
  double get subtaskProgress => subtasks.isEmpty
      ? (isDone ? 1 : 0)
      : completedSubtaskCount / subtasks.length;

  /// How long the task took, once completed.
  Duration? get timeToComplete => completedAt?.difference(createdAt);

  Task copyWith({
    String? projectId,
    bool clearProject = false,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    bool clearAssignee = false,
    List<String>? labelIds,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? startDate,
    bool clearStartDate = false,
    int? estimateMinutes,
    bool clearEstimate = false,
    List<Subtask>? subtasks,
    List<String>? dependsOnIds,
    List<Attachment>? attachments,
    RecurrenceRule? recurrence,
    bool? isArchived,
    bool? isFavorite,
    int? sortIndex,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      workspaceId: workspaceId,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      labelIds: labelIds ?? this.labelIds,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      estimateMinutes: clearEstimate
          ? null
          : (estimateMinutes ?? this.estimateMinutes),
      subtasks: subtasks ?? this.subtasks,
      dependsOnIds: dependsOnIds ?? this.dependsOnIds,
      attachments: attachments ?? this.attachments,
      recurrence: recurrence ?? this.recurrence,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdById: createdById,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'projectId': projectId,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'assigneeId': assigneeId,
    'labelIds': labelIds,
    'dueDate': writeDate(dueDate),
    'startDate': writeDate(startDate),
    'estimateMinutes': estimateMinutes,
    'subtasks': subtasks.map((Subtask s) => s.toJson()).toList(),
    'dependsOnIds': dependsOnIds,
    'attachments': attachments.map((Attachment a) => a.toJson()).toList(),
    'recurrence': recurrence.toJson(),
    'isArchived': isArchived,
    'isFavorite': isFavorite,
    'sortIndex': sortIndex,
    'createdAt': writeDate(createdAt),
    'updatedAt': writeDate(updatedAt),
    'completedAt': writeDate(completedAt),
    'createdById': createdById,
  };

  factory Task.fromJson(JsonMap json) {
    final DateTime created = readDateOr(json['createdAt'], DateTime.now());
    final Object? recurrenceRaw = json['recurrence'];
    return Task(
      id: readString(json['id']),
      workspaceId: readString(json['workspaceId']),
      projectId: json['projectId'] as String?,
      title: readString(json['title']),
      description: readString(json['description']),
      status: enumFromName(TaskStatus.values, json['status'], TaskStatus.todo),
      priority: enumFromName(
        TaskPriority.values,
        json['priority'],
        TaskPriority.medium,
      ),
      assigneeId: json['assigneeId'] as String?,
      labelIds: readStringList(json['labelIds']),
      dueDate: readDate(json['dueDate']),
      startDate: readDate(json['startDate']),
      estimateMinutes: readIntOrNull(json['estimateMinutes']),
      subtasks: readObjectList(json['subtasks']).map(Subtask.fromJson).toList(),
      dependsOnIds: readStringList(json['dependsOnIds']),
      attachments: readObjectList(
        json['attachments'],
      ).map(Attachment.fromJson).toList(),
      recurrence: recurrenceRaw is Map<dynamic, dynamic>
          ? RecurrenceRule.fromJson(asJsonMap(recurrenceRaw))
          : RecurrenceRule.none,
      isArchived: readBool(json['isArchived']),
      isFavorite: readBool(json['isFavorite']),
      sortIndex: readInt(json['sortIndex']),
      createdAt: created,
      updatedAt: readDateOr(json['updatedAt'], created),
      completedAt: readDate(json['completedAt']),
      createdById: readString(json['createdById']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
