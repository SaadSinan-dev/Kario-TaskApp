import 'package:flutter/foundation.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';

/// A dated checkpoint on a project's timeline.
@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.date,
    this.isReached = false,
  });

  final String id;
  final String projectId;
  final String title;
  final DateTime date;
  final bool isReached;

  Milestone copyWith({String? title, DateTime? date, bool? isReached}) =>
      Milestone(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        date: date ?? this.date,
        isReached: isReached ?? this.isReached,
      );

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'projectId': projectId,
    'title': title,
    'date': writeDate(date),
    'isReached': isReached,
  };

  factory Milestone.fromJson(JsonMap json) => Milestone(
    id: readString(json['id']),
    projectId: readString(json['projectId']),
    title: readString(json['title']),
    date: readDateOr(json['date'], DateTime.now()),
    isReached: readBool(json['isReached']),
  );
}

/// A body of related work. Projects give tasks a home, a colour and a shape on
/// the timeline.
@immutable
class Project {
  const Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.iconEmoji = '📦',
    this.colorValue = 0xFF3B6BF5,
    this.status = ProjectStatus.active,
    this.memberIds = const <String>[],
    this.leadId,
    this.startDate,
    this.dueDate,
    this.milestones = const <Milestone>[],
    this.isFavorite = false,
    this.isArchived = false,
    this.sortIndex = 0,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final String iconEmoji;
  final int colorValue;
  final ProjectStatus status;
  final List<String> memberIds;
  final String? leadId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final List<Milestone> milestones;
  final bool isFavorite;
  final bool isArchived;

  /// Manual ordering in the sidebar and project list.
  final int sortIndex;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == ProjectStatus.active && !isArchived;

  Project copyWith({
    String? name,
    String? description,
    String? iconEmoji,
    int? colorValue,
    ProjectStatus? status,
    List<String>? memberIds,
    String? leadId,
    bool clearLead = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<Milestone>? milestones,
    bool? isFavorite,
    bool? isArchived,
    int? sortIndex,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      workspaceId: workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      colorValue: colorValue ?? this.colorValue,
      status: status ?? this.status,
      memberIds: memberIds ?? this.memberIds,
      leadId: clearLead ? null : (leadId ?? this.leadId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      milestones: milestones ?? this.milestones,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'name': name,
    'description': description,
    'iconEmoji': iconEmoji,
    'colorValue': colorValue,
    'status': status.name,
    'memberIds': memberIds,
    'leadId': leadId,
    'startDate': writeDate(startDate),
    'dueDate': writeDate(dueDate),
    'milestones': milestones.map((Milestone m) => m.toJson()).toList(),
    'isFavorite': isFavorite,
    'isArchived': isArchived,
    'sortIndex': sortIndex,
    'createdAt': writeDate(createdAt),
    'updatedAt': writeDate(updatedAt),
  };

  factory Project.fromJson(JsonMap json) {
    final DateTime created = readDateOr(json['createdAt'], DateTime.now());
    return Project(
      id: readString(json['id']),
      workspaceId: readString(json['workspaceId']),
      name: readString(json['name']),
      description: readString(json['description']),
      iconEmoji: readString(json['iconEmoji'], '📦'),
      colorValue: readColorValue(json['colorValue'], 0xFF3B6BF5),
      status: enumFromName(
        ProjectStatus.values,
        json['status'],
        ProjectStatus.active,
      ),
      memberIds: readStringList(json['memberIds']),
      leadId: json['leadId'] as String?,
      startDate: readDate(json['startDate']),
      dueDate: readDate(json['dueDate']),
      milestones: readObjectList(
        json['milestones'],
      ).map(Milestone.fromJson).toList(),
      isFavorite: readBool(json['isFavorite']),
      isArchived: readBool(json['isArchived']),
      sortIndex: readInt(json['sortIndex']),
      createdAt: created,
      updatedAt: readDateOr(json['updatedAt'], created),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Project && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Derived counts for a project. Computed by the repository from the task set
/// rather than stored, so it can never drift out of sync.
@immutable
class ProjectStats {
  const ProjectStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.overdue,
    required this.dueThisWeek,
  });

  static const ProjectStats empty = ProjectStats(
    total: 0,
    completed: 0,
    inProgress: 0,
    overdue: 0,
    dueThisWeek: 0,
  );

  final int total;
  final int completed;
  final int inProgress;
  final int overdue;
  final int dueThisWeek;

  int get remaining => total - completed;

  /// 0…1. An empty project reports zero rather than "complete", which reads
  /// better on a progress ring.
  double get progress => total == 0 ? 0 : completed / total;
}
