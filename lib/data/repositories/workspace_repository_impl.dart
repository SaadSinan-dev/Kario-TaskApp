import 'dart:async';

import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/local/value_stream.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/domain/repositories/repositories.dart';

class LocalWorkspaceRepository implements WorkspaceRepository {
  LocalWorkspaceRepository({
    required KairoDatabase database,
    required SettingsStore settings,
  }) : _db = database,
       _settings = settings {
    _activeId = ValueStream<String?>(
      _settings.getString(SettingsKeys.activeWorkspace),
    );
  }

  final KairoDatabase _db;
  final SettingsStore _settings;
  late final ValueStream<String?> _activeId;

  @override
  Stream<List<Workspace>> watchWorkspaces() => _db.workspaces.stream;

  @override
  Stream<Workspace?> watchActiveWorkspace() async* {
    // Re-emits when either the selection or the workspace list changes, so a
    // rename is reflected without re-selecting.
    await for (final String? _ in _activeId.stream) {
      yield _resolveActive();
    }
  }

  Workspace? _resolveActive() {
    final List<Workspace> all = _db.workspaces.value;
    if (all.isEmpty) return null;
    final String? id = _activeId.value;
    return all.where((Workspace w) => w.id == id).firstOrNull ?? all.first;
  }

  @override
  Future<void> setActiveWorkspace(String workspaceId) async {
    await _settings.setString(SettingsKeys.activeWorkspace, workspaceId);
    _activeId.add(workspaceId);
  }

  @override
  Future<Workspace> createWorkspace({
    required String name,
    required String ownerId,
    String description = '',
    String iconEmoji = '🚀',
  }) => Failure.guard(() async {
    await _db.latency();
    if (name.trim().isEmpty) {
      throw const ValidationFailure(<String, String>{
        'name': 'Give the workspace a name.',
      });
    }
    final Workspace workspace = Workspace(
      id: Ids.workspace(),
      name: name.trim(),
      description: description.trim(),
      ownerId: ownerId,
      iconEmoji: iconEmoji,
      createdAt: DateTime.now(),
      members: <WorkspaceMember>[
        WorkspaceMember(
          userId: ownerId,
          role: WorkspaceRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
    );
    _db.commit<Workspace>(_db.workspaces, <Workspace>[
      ..._db.workspaces.value,
      workspace,
    ], Collections.workspaces);
    await setActiveWorkspace(workspace.id);
    return workspace;
  });

  @override
  Future<Workspace> updateWorkspace(Workspace workspace) =>
      Failure.guard(() async {
        await _db.latency(0.5);
        _db.commit<Workspace>(
          _db.workspaces,
          _db.workspaces.value
              .map((Workspace w) => w.id == workspace.id ? workspace : w)
              .toList(),
          Collections.workspaces,
        );
        _activeId.refresh();
        return workspace;
      });

  @override
  Future<void> inviteMember({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  }) => Failure.guard(() async {
    await _db.latency(1.2);
    final Workspace workspace =
        _db.workspaceById(workspaceId) ??
        (throw NotFoundFailure('workspace', workspaceId));

    final String normalised = email.trim().toLowerCase();
    User? user = _db.users.value
        .where((User u) => u.email.toLowerCase() == normalised)
        .firstOrNull;

    // An invitation to an address with no account creates a pending member —
    // the same shape a real invite endpoint would return.
    user ??= User(
      id: Ids.user(),
      name: _nameFromEmail(normalised),
      email: normalised,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );

    if (workspace.members.any((WorkspaceMember m) => m.userId == user!.id)) {
      throw const ConflictFailure('That person is already a member.');
    }

    if (_db.userById(user.id) == null) {
      _db.commit<User>(_db.users, <User>[
        ..._db.users.value,
        user,
      ], Collections.users);
    }

    await updateWorkspace(
      workspace.copyWith(
        members: <WorkspaceMember>[
          ...workspace.members,
          WorkspaceMember(
            userId: user.id,
            role: role,
            joinedAt: DateTime.now(),
          ),
        ],
      ),
    );
  });

  @override
  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  }) => Failure.guard(() async {
    await _db.latency(0.6);
    final Workspace workspace =
        _db.workspaceById(workspaceId) ??
        (throw NotFoundFailure('workspace', workspaceId));
    if (workspace.ownerId == userId) {
      throw const ConflictFailure(
        'The workspace owner can’t be removed. Transfer ownership first.',
      );
    }
    await updateWorkspace(
      workspace.copyWith(
        members: workspace.members
            .where((WorkspaceMember m) => m.userId != userId)
            .toList(),
      ),
    );
  });

  @override
  Future<void> changeMemberRole({
    required String workspaceId,
    required String userId,
    required WorkspaceRole role,
  }) => Failure.guard(() async {
    await _db.latency(0.5);
    final Workspace workspace =
        _db.workspaceById(workspaceId) ??
        (throw NotFoundFailure('workspace', workspaceId));
    if (workspace.ownerId == userId && role != WorkspaceRole.owner) {
      throw const ConflictFailure('The owner’s role can’t be downgraded.');
    }
    await updateWorkspace(
      workspace.copyWith(
        members: workspace.members
            .map(
              (WorkspaceMember m) =>
                  m.userId == userId ? m.copyWith(role: role) : m,
            )
            .toList(),
      ),
    );
  });

  @override
  Stream<List<User>> watchMembers(String workspaceId) async* {
    await for (final List<User> users in _db.users.stream) {
      final Workspace? workspace = _db.workspaceById(workspaceId);
      if (workspace == null) {
        yield const <User>[];
        continue;
      }
      final Set<String> ids = workspace.members
          .map((WorkspaceMember m) => m.userId)
          .toSet();
      yield users.where((User u) => ids.contains(u.id)).toList(growable: false);
    }
  }

  @override
  Stream<List<Label>> watchLabels(String workspaceId) async* {
    await for (final List<Label> labels in _db.labels.stream) {
      yield labels
          .where((Label l) => l.workspaceId == workspaceId)
          .toList(growable: false);
    }
  }

  @override
  Future<Label> createLabel({
    required String workspaceId,
    required String name,
    required int colorValue,
  }) => Failure.guard(() async {
    await _db.latency(0.4);
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure(<String, String>{
        'name': 'Give the label a name.',
      });
    }
    final bool duplicate = _db.labels.value.any(
      (Label l) =>
          l.workspaceId == workspaceId &&
          l.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw const ConflictFailure('A label with that name already exists.');
    }
    final Label label = Label(
      id: Ids.label(),
      workspaceId: workspaceId,
      name: trimmed,
      colorValue: colorValue,
    );
    _db.commit<Label>(_db.labels, <Label>[
      ..._db.labels.value,
      label,
    ], Collections.labels);
    return label;
  });

  @override
  Future<Label> updateLabel(Label label) => Failure.guard(() async {
    await _db.latency(0.4);
    _db.commit<Label>(
      _db.labels,
      _db.labels.value.map((Label l) => l.id == label.id ? label : l).toList(),
      Collections.labels,
    );
    return label;
  });

  @override
  Future<void> deleteLabel(String labelId) => Failure.guard(() async {
    await _db.latency(0.4);
    _db.commit<Label>(
      _db.labels,
      _db.labels.value.where((Label l) => l.id != labelId).toList(),
      Collections.labels,
    );
    // Detach the label from every task rather than leaving a dangling id.
    _db.commit(
      _db.tasks,
      _db.tasks.value
          .map(
            (task) => task.labelIds.contains(labelId)
                ? task.copyWith(
                    labelIds: task.labelIds
                        .where((String id) => id != labelId)
                        .toList(),
                  )
                : task,
          )
          .toList(),
      Collections.tasks,
    );
  });

  @override
  Future<void> resetDemoData() => Failure.guard(() async {
    await _db.resetToSeed();
    await setActiveWorkspace(DemoSeed.workspaceId);
  });

  @override
  Future<Map<String, dynamic>> exportWorkspace(String workspaceId) =>
      Failure.guard(() async {
        await _db.latency(1.5);
        final Workspace workspace =
            _db.workspaceById(workspaceId) ??
            (throw NotFoundFailure('workspace', workspaceId));
        final Set<String> projectIds = _db.projects.value
            .where((p) => p.workspaceId == workspaceId)
            .map((p) => p.id)
            .toSet();
        final List<String> taskIds = _db.tasks.value
            .where((t) => t.workspaceId == workspaceId)
            .map((t) => t.id)
            .toList();

        return <String, dynamic>{
          'exportedAt': DateTime.now().toIso8601String(),
          'schemaVersion': DemoSeed.version,
          'workspace': workspace.toJson(),
          'labels': _db.labels.value
              .where((l) => l.workspaceId == workspaceId)
              .map((l) => l.toJson())
              .toList(),
          'projects': _db.projects.value
              .where((p) => projectIds.contains(p.id))
              .map((p) => p.toJson())
              .toList(),
          'tasks': _db.tasks.value
              .where((t) => t.workspaceId == workspaceId)
              .map((t) => t.toJson())
              .toList(),
          'comments': _db.comments.value
              .where((c) => taskIds.contains(c.taskId))
              .map((c) => c.toJson())
              .toList(),
          'activity': _db.activities.value
              .where((a) => a.workspaceId == workspaceId)
              .map((a) => a.toJson())
              .toList(),
        };
      });

  String _nameFromEmail(String email) {
    final String local = email
        .split('@')
        .first
        .replaceAll(RegExp('[._-]+'), ' ');
    return local
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map((String part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
