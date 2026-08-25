import 'package:flutter/foundation.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';

/// An emoji reaction and who left it.
@immutable
class Reaction {
  const Reaction({required this.emoji, required this.userIds});

  final String emoji;
  final List<String> userIds;

  int get count => userIds.length;
  bool reactedBy(String userId) => userIds.contains(userId);

  Reaction toggled(String userId) => Reaction(
    emoji: emoji,
    userIds: userIds.contains(userId)
        ? (<String>[...userIds]..remove(userId))
        : <String>[...userIds, userId],
  );

  JsonMap toJson() => <String, dynamic>{'emoji': emoji, 'userIds': userIds};

  factory Reaction.fromJson(JsonMap json) => Reaction(
    emoji: readString(json['emoji']),
    userIds: readStringList(json['userIds']),
  );
}

/// A comment on a task. Replies are flat with a `replyToId` rather than a tree:
/// one level of threading is what task conversations actually use, and it keeps
/// rendering and pagination simple.
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    this.replyToId,
    this.mentionedUserIds = const <String>[],
    this.reactions = const <Reaction>[],
    this.isDeleted = false,
  });

  final String id;
  final String taskId;
  final String authorId;

  /// Markdown, same as task descriptions. `@name` mentions are resolved from
  /// [mentionedUserIds] rather than by parsing the text at render time.
  final String body;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? replyToId;
  final List<String> mentionedUserIds;
  final List<Reaction> reactions;
  final bool isDeleted;

  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  Comment copyWith({
    String? body,
    DateTime? updatedAt,
    List<String>? mentionedUserIds,
    List<Reaction>? reactions,
    bool? isDeleted,
  }) {
    return Comment(
      id: id,
      taskId: taskId,
      authorId: authorId,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyToId: replyToId,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'taskId': taskId,
    'authorId': authorId,
    'body': body,
    'createdAt': writeDate(createdAt),
    'updatedAt': writeDate(updatedAt),
    'replyToId': replyToId,
    'mentionedUserIds': mentionedUserIds,
    'reactions': reactions.map((Reaction r) => r.toJson()).toList(),
    'isDeleted': isDeleted,
  };

  factory Comment.fromJson(JsonMap json) => Comment(
    id: readString(json['id']),
    taskId: readString(json['taskId']),
    authorId: readString(json['authorId']),
    body: readString(json['body']),
    createdAt: readDateOr(json['createdAt'], DateTime.now()),
    updatedAt: readDate(json['updatedAt']),
    replyToId: json['replyToId'] as String?,
    mentionedUserIds: readStringList(json['mentionedUserIds']),
    reactions: readObjectList(
      json['reactions'],
    ).map(Reaction.fromJson).toList(),
    isDeleted: readBool(json['isDeleted']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Comment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// An immutable record of something that happened.
///
/// [from] and [to] hold the human-readable before/after for changes, so the
/// feed can render "Priority: Medium → Urgent" without re-deriving history.
@immutable
class Activity {
  const Activity({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.actorId,
    required this.createdAt,
    this.taskId,
    this.projectId,
    this.from,
    this.to,
    this.detail,
  });

  final String id;
  final String workspaceId;
  final ActivityType type;
  final String actorId;
  final DateTime createdAt;
  final String? taskId;
  final String? projectId;
  final String? from;
  final String? to;
  final String? detail;

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'type': type.name,
    'actorId': actorId,
    'createdAt': writeDate(createdAt),
    'taskId': taskId,
    'projectId': projectId,
    'from': from,
    'to': to,
    'detail': detail,
  };

  factory Activity.fromJson(JsonMap json) => Activity(
    id: readString(json['id']),
    workspaceId: readString(json['workspaceId']),
    type: enumFromName(
      ActivityType.values,
      json['type'],
      ActivityType.taskCreated,
    ),
    actorId: readString(json['actorId']),
    createdAt: readDateOr(json['createdAt'], DateTime.now()),
    taskId: json['taskId'] as String?,
    projectId: json['projectId'] as String?,
    from: json['from'] as String?,
    to: json['to'] as String?,
    detail: json['detail'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Activity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// An item in the notification centre.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actorId,
    this.taskId,
    this.projectId,
    this.isRead = false,
  });

  final String id;
  final String workspaceId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? actorId;
  final String? taskId;
  final String? projectId;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    workspaceId: workspaceId,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    actorId: actorId,
    taskId: taskId,
    projectId: projectId,
    isRead: isRead ?? this.isRead,
  );

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': writeDate(createdAt),
    'actorId': actorId,
    'taskId': taskId,
    'projectId': projectId,
    'isRead': isRead,
  };

  factory AppNotification.fromJson(JsonMap json) => AppNotification(
    id: readString(json['id']),
    workspaceId: readString(json['workspaceId']),
    type: enumFromName(
      NotificationType.values,
      json['type'],
      NotificationType.taskCompleted,
    ),
    title: readString(json['title']),
    body: readString(json['body']),
    createdAt: readDateOr(json['createdAt'], DateTime.now()),
    actorId: json['actorId'] as String?,
    taskId: json['taskId'] as String?,
    projectId: json['projectId'] as String?,
    isRead: readBool(json['isRead']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
