import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/json_support.dart';
import 'package:meta/meta.dart';

/// A membership record: which person, in which workspace, with what rights.
@immutable
class WorkspaceMember {
  const WorkspaceMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final WorkspaceRole role;
  final DateTime joinedAt;

  WorkspaceMember copyWith({WorkspaceRole? role}) => WorkspaceMember(
    userId: userId,
    role: role ?? this.role,
    joinedAt: joinedAt,
  );

  JsonMap toJson() => <String, dynamic>{
    'userId': userId,
    'role': role.name,
    'joinedAt': writeDate(joinedAt),
  };

  factory WorkspaceMember.fromJson(JsonMap json) => WorkspaceMember(
    userId: readString(json['userId']),
    role: enumFromName(
      WorkspaceRole.values,
      json['role'],
      WorkspaceRole.member,
    ),
    joinedAt: readDateOr(json['joinedAt'], DateTime.now()),
  );
}

/// A reusable tag. Labels are workspace-scoped so the same "Blocked" chip means
/// the same thing across every project.
@immutable
class Label {
  const Label({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.colorValue,
  });

  final String id;
  final String workspaceId;
  final String name;
  final int colorValue;

  Label copyWith({String? name, int? colorValue}) => Label(
    id: id,
    workspaceId: workspaceId,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'workspaceId': workspaceId,
    'name': name,
    'colorValue': colorValue,
  };

  factory Label.fromJson(JsonMap json) => Label(
    id: readString(json['id']),
    workspaceId: readString(json['workspaceId']),
    name: readString(json['name']),
    colorValue: readColorValue(json['colorValue'], 0xFF3B6BF5),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Label && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// The top-level container: projects, people and labels all belong to one.
@immutable
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.description = '',
    this.iconEmoji = '🚀',
    this.colorValue = 0xFF3B6BF5,
    this.members = const <WorkspaceMember>[],
    this.plan = 'free',
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String iconEmoji;
  final int colorValue;
  final List<WorkspaceMember> members;
  final DateTime createdAt;

  /// Billing plan identifier. The UI reads it to show plan badges and gate the
  /// upgrade call-to-action; no payment provider is wired up.
  final String plan;

  int get memberCount => members.length;

  WorkspaceRole roleOf(String userId) => members
      .firstWhere(
        (WorkspaceMember m) => m.userId == userId,
        orElse: () => WorkspaceMember(
          userId: userId,
          role: WorkspaceRole.guest,
          joinedAt: createdAt,
        ),
      )
      .role;

  Workspace copyWith({
    String? name,
    String? description,
    String? iconEmoji,
    int? colorValue,
    List<WorkspaceMember>? members,
    String? plan,
  }) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      colorValue: colorValue ?? this.colorValue,
      members: members ?? this.members,
      createdAt: createdAt,
      plan: plan ?? this.plan,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'iconEmoji': iconEmoji,
    'colorValue': colorValue,
    'members': members.map((WorkspaceMember m) => m.toJson()).toList(),
    'createdAt': writeDate(createdAt),
    'plan': plan,
  };

  factory Workspace.fromJson(JsonMap json) => Workspace(
    id: readString(json['id']),
    name: readString(json['name']),
    description: readString(json['description']),
    ownerId: readString(json['ownerId']),
    iconEmoji: readString(json['iconEmoji'], '🚀'),
    colorValue: readColorValue(json['colorValue'], 0xFF3B6BF5),
    members: readObjectList(
      json['members'],
    ).map(WorkspaceMember.fromJson).toList(),
    createdAt: readDateOr(json['createdAt'], DateTime.now()),
    plan: readString(json['plan'], 'free'),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Workspace && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
