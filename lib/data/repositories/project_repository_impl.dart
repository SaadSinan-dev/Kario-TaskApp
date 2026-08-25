import 'dart:async';

import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:kairo/domain/services/project_stats_calculator.dart';

class LocalProjectRepository implements ProjectRepository {
  LocalProjectRepository({
    required KairoDatabase database,
    required String Function() actorId,
  }) : _db = database,
       _actorId = actorId;

  final KairoDatabase _db;
  final String Function() _actorId;

  @override
  Stream<List<Project>> watchProjects(
    String workspaceId, {
    bool includeArchived = false,
  }) async* {
    await for (final List<Project> projects in _db.projects.stream) {
      final List<Project> scoped =
          projects
              .where(
                (Project p) =>
                    p.workspaceId == workspaceId &&
                    (includeArchived || !p.isArchived),
              )
              .toList()
            ..sort((Project a, Project b) {
              final int byFavorite = (b.isFavorite ? 1 : 0).compareTo(
                a.isFavorite ? 1 : 0,
              );
              if (byFavorite != 0) return byFavorite;
              return a.sortIndex.compareTo(b.sortIndex);
            });
      yield scoped;
    }
  }

  @override
  Stream<Project?> watchProject(String projectId) async* {
    await for (final List<Project> projects in _db.projects.stream) {
      yield projects.where((Project p) => p.id == projectId).firstOrNull;
    }
  }

  @override
  Future<Project?> findProject(String projectId) async =>
      _db.projectById(projectId);

  @override
  Future<Project> createProject(Project draft) => Failure.guard(() async {
    await _db.latency();
    if (draft.name.trim().isEmpty) {
      throw const ValidationFailure(<String, String>{
        'name': 'Give the project a name.',
      });
    }
    final int nextIndex = _db.projects.value
        .where((Project p) => p.workspaceId == draft.workspaceId)
        .fold<int>(
          0,
          (int max, Project p) => p.sortIndex > max ? p.sortIndex : max,
        );

    final Project project = Project(
      id: draft.id.isEmpty ? Ids.project() : draft.id,
      workspaceId: draft.workspaceId,
      name: draft.name.trim(),
      description: draft.description,
      iconEmoji: draft.iconEmoji,
      colorValue: draft.colorValue,
      status: draft.status,
      memberIds: draft.memberIds,
      leadId: draft.leadId,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      milestones: draft.milestones,
      sortIndex: nextIndex + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _db.commit<Project>(_db.projects, <Project>[
      ..._db.projects.value,
      project,
    ], Collections.projects);
    _db.recordActivity(
      Activity(
        id: Ids.activity(),
        workspaceId: project.workspaceId,
        type: ActivityType.projectCreated,
        actorId: _actorId(),
        createdAt: DateTime.now(),
        projectId: project.id,
        to: project.name,
      ),
    );
    return project;
  });

  @override
  Future<Project> updateProject(Project project) => Failure.guard(() async {
    await _db.latency(0.5);
    final Project updated = project.copyWith(updatedAt: DateTime.now());
    _write(updated);
    _db.recordActivity(
      Activity(
        id: Ids.activity(),
        workspaceId: updated.workspaceId,
        type: ActivityType.projectUpdated,
        actorId: _actorId(),
        createdAt: DateTime.now(),
        projectId: updated.id,
        to: updated.name,
      ),
    );
    return updated;
  });

  @override
  Future<void> deleteProject(String projectId) => Failure.guard(() async {
    await _db.latency(0.6);
    _db.commit<Project>(
      _db.projects,
      _db.projects.value.where((Project p) => p.id != projectId).toList(),
      Collections.projects,
    );
    // Tasks survive their project and fall back to the workspace inbox —
    // deleting a project should never silently delete somebody's work.
    _db.commit<Task>(
      _db.tasks,
      _db.tasks.value
          .map(
            (Task t) =>
                t.projectId == projectId ? t.copyWith(clearProject: true) : t,
          )
          .toList(),
      Collections.tasks,
    );
  });

  @override
  Future<Project> setArchived(String projectId, {required bool archived}) =>
      Failure.guard(() async {
        await _db.latency(0.5);
        final Project project =
            _db.projectById(projectId) ??
            (throw NotFoundFailure('project', projectId));
        final Project updated = project.copyWith(
          isArchived: archived,
          status: archived ? ProjectStatus.archived : ProjectStatus.active,
          updatedAt: DateTime.now(),
        );
        _write(updated);
        return updated;
      });

  @override
  Future<Project> toggleFavorite(String projectId) => Failure.guard(() async {
    final Project project =
        _db.projectById(projectId) ??
        (throw NotFoundFailure('project', projectId));
    final Project updated = project.copyWith(isFavorite: !project.isFavorite);
    _write(updated);
    return updated;
  });

  @override
  Future<void> reorderProjects(List<String> orderedIds) =>
      Failure.guard(() async {
        final Map<String, int> order = <String, int>{
          for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
        };
        _db.commit<Project>(
          _db.projects,
          _db.projects.value
              .map(
                (Project p) => order.containsKey(p.id)
                    ? p.copyWith(sortIndex: order[p.id])
                    : p,
              )
              .toList(),
          Collections.projects,
        );
      });

  @override
  Future<ProjectStats> statsFor(String projectId) async =>
      ProjectStatsCalculator.forProject(projectId, _db.tasks.value);

  @override
  Future<Milestone> upsertMilestone(String projectId, Milestone milestone) =>
      Failure.guard(() async {
        await _db.latency(0.4);
        final Project project =
            _db.projectById(projectId) ??
            (throw NotFoundFailure('project', projectId));
        final bool exists = project.milestones.any(
          (Milestone m) => m.id == milestone.id,
        );
        final List<Milestone> next = exists
            ? project.milestones
                  .map((Milestone m) => m.id == milestone.id ? milestone : m)
                  .toList()
            : <Milestone>[...project.milestones, milestone];
        next.sort((Milestone a, Milestone b) => a.date.compareTo(b.date));
        _write(project.copyWith(milestones: next, updatedAt: DateTime.now()));
        return milestone;
      });

  @override
  Future<void> deleteMilestone(String projectId, String milestoneId) =>
      Failure.guard(() async {
        final Project project =
            _db.projectById(projectId) ??
            (throw NotFoundFailure('project', projectId));
        _write(
          project.copyWith(
            milestones: project.milestones
                .where((Milestone m) => m.id != milestoneId)
                .toList(),
            updatedAt: DateTime.now(),
          ),
        );
      });

  void _write(Project project) {
    _db.commit<Project>(
      _db.projects,
      _db.projects.value
          .map((Project p) => p.id == project.id ? project : p)
          .toList(),
      Collections.projects,
    );
  }
}
