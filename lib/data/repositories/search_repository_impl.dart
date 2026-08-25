import 'dart:async';

import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/utils/fuzzy_match.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Global search across everything in a workspace.
///
/// Runs entirely in memory over the local cache: with a workspace of this size
/// that is a sub-millisecond scan, and it means search keeps working offline.
/// The debounce lives in the controller, not here — the repository stays a pure
/// function of (workspace, query).
class LocalSearchRepository implements SearchRepository {
  LocalSearchRepository({
    required KairoDatabase database,
    required SettingsStore settings,
  }) : _db = database,
       _settings = settings;

  final KairoDatabase _db;
  final SettingsStore _settings;

  static const int _maxRecent = 8;
  static const int _maxResults = 40;

  @override
  Future<List<SearchHit>> search(String workspaceId, String query) =>
      Failure.guard(() async {
        final String needle = query.trim();
        if (needle.isEmpty) return const <SearchHit>[];
        await _db.latency(0.3);

        final List<SearchHit> hits = <SearchHit>[];

        for (final Task task in _db.tasks.value) {
          if (task.workspaceId != workspaceId) continue;
          final FuzzyMatch title = Fuzzy.match(task.title, needle);
          final FuzzyMatch body = Fuzzy.match(task.description, needle);
          final bool matched = title.isMatch || body.isMatch;
          if (!matched) continue;
          final Project? project = task.projectId == null
              ? null
              : _db.projectById(task.projectId!);
          hits.add(
            SearchHit(
              id: task.id,
              kind: SearchHitKind.task,
              title: task.title,
              subtitle: project?.name ?? 'No project',
              score: title.isMatch ? title.score : body.score - 20,
              matchedPositions: title.positions,
              accentColorValue: project?.colorValue,
              taskId: task.id,
              projectId: task.projectId,
            ),
          );
        }

        for (final Project project in _db.projects.value) {
          if (project.workspaceId != workspaceId) continue;
          final FuzzyMatch match = Fuzzy.matchAny(<String>[
            project.name,
            project.description,
          ], needle);
          if (!match.isMatch) continue;
          hits.add(
            SearchHit(
              id: project.id,
              kind: SearchHitKind.project,
              title: project.name,
              subtitle: '${project.iconEmoji}  ${project.status.name}',
              score: match.score + 10,
              matchedPositions: Fuzzy.match(project.name, needle).positions,
              accentColorValue: project.colorValue,
              projectId: project.id,
            ),
          );
        }

        final Workspace? workspace = _db.workspaceById(workspaceId);
        final Set<String> memberIds =
            workspace?.members.map((WorkspaceMember m) => m.userId).toSet() ??
            <String>{};
        for (final User user in _db.users.value) {
          if (!memberIds.contains(user.id)) continue;
          final FuzzyMatch match = Fuzzy.matchAny(<String>[
            user.name,
            user.email,
            user.jobTitle,
          ], needle);
          if (!match.isMatch) continue;
          hits.add(
            SearchHit(
              id: user.id,
              kind: SearchHitKind.member,
              title: user.name,
              subtitle: user.jobTitle.isEmpty ? user.email : user.jobTitle,
              score: match.score,
              matchedPositions: Fuzzy.match(user.name, needle).positions,
              accentColorValue: user.accentColorValue,
            ),
          );
        }

        for (final Label label in _db.labels.value) {
          if (label.workspaceId != workspaceId) continue;
          final FuzzyMatch match = Fuzzy.match(label.name, needle);
          if (!match.isMatch) continue;
          hits.add(
            SearchHit(
              id: label.id,
              kind: SearchHitKind.label,
              title: label.name,
              subtitle: 'Label',
              score: match.score,
              matchedPositions: match.positions,
              accentColorValue: label.colorValue,
            ),
          );
        }

        final Set<String> workspaceTaskIds = _db.tasks.value
            .where((Task t) => t.workspaceId == workspaceId)
            .map((Task t) => t.id)
            .toSet();
        for (final Comment comment in _db.comments.value) {
          if (!workspaceTaskIds.contains(comment.taskId)) continue;
          final FuzzyMatch match = Fuzzy.match(comment.body, needle);
          if (!match.isMatch) continue;
          final Task? task = _db.taskById(comment.taskId);
          hits.add(
            SearchHit(
              id: comment.id,
              kind: SearchHitKind.comment,
              title: _excerpt(comment.body),
              subtitle: task?.title ?? '',
              score: match.score - 30,
              matchedPositions: const <int>[],
              taskId: comment.taskId,
            ),
          );
        }

        hits.sort((SearchHit a, SearchHit b) => b.score.compareTo(a.score));
        return hits.take(_maxResults).toList(growable: false);
      });

  @override
  Future<List<String>> recentQueries() async =>
      _settings.getStringList(SettingsKeys.recentSearches);

  @override
  Future<void> rememberQuery(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return;
    final List<String> recent = <String>[
      trimmed,
      ..._settings
          .getStringList(SettingsKeys.recentSearches)
          .where((String q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxRecent).toList();
    await _settings.setStringList(SettingsKeys.recentSearches, recent);
  }

  @override
  Future<void> clearRecentQueries() =>
      _settings.setStringList(SettingsKeys.recentSearches, const <String>[]);

  @override
  Future<List<SearchHit>> recentlyViewed(String workspaceId) async {
    final List<String> entries = _settings.getStringList(
      SettingsKeys.recentlyViewed,
    );
    final List<SearchHit> hits = <SearchHit>[];
    for (final String entry in entries) {
      final List<String> parts = entry.split('|');
      if (parts.length != 3 || parts[0] != workspaceId) continue;
      final SearchHitKind kind = parts[1] == 'project'
          ? SearchHitKind.project
          : SearchHitKind.task;
      if (kind == SearchHitKind.project) {
        final Project? project = _db.projectById(parts[2]);
        if (project == null) continue;
        hits.add(
          SearchHit(
            id: project.id,
            kind: SearchHitKind.project,
            title: project.name,
            subtitle: project.iconEmoji,
            score: 0,
            matchedPositions: const <int>[],
            accentColorValue: project.colorValue,
            projectId: project.id,
          ),
        );
      } else {
        final Task? task = _db.taskById(parts[2]);
        if (task == null) continue;
        final Project? project = task.projectId == null
            ? null
            : _db.projectById(task.projectId!);
        hits.add(
          SearchHit(
            id: task.id,
            kind: SearchHitKind.task,
            title: task.title,
            subtitle: project?.name ?? '',
            score: 0,
            matchedPositions: const <int>[],
            accentColorValue: project?.colorValue,
            taskId: task.id,
            projectId: task.projectId,
          ),
        );
      }
    }
    return hits;
  }

  @override
  Future<void> rememberViewed({
    required String workspaceId,
    required String id,
    required SearchHitKind kind,
  }) async {
    final String entry = '$workspaceId|${kind.name}|$id';
    final List<String> next = <String>[
      entry,
      ..._settings
          .getStringList(SettingsKeys.recentlyViewed)
          .where((String e) => e != entry),
    ].take(12).toList();
    await _settings.setStringList(SettingsKeys.recentlyViewed, next);
  }

  String _excerpt(String body) {
    final String flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 80 ? flat : '${flat.substring(0, 80)}…';
  }
}
