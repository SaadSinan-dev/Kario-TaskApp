import 'dart:async';

import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';

class LocalCommentRepository implements CommentRepository {
  LocalCommentRepository({required KairoDatabase database}) : _db = database;

  final KairoDatabase _db;

  @override
  Stream<List<Comment>> watchComments(String taskId) async* {
    await for (final List<Comment> comments in _db.comments.stream) {
      yield comments.where((Comment c) => c.taskId == taskId).toList()
        ..sort((Comment a, Comment b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  @override
  Future<Comment> addComment({
    required String taskId,
    required String authorId,
    required String body,
    String? replyToId,
    List<String> mentionedUserIds = const <String>[],
  }) => Failure.guard(() async {
    await _db.latency(0.5);
    if (body.trim().isEmpty) {
      throw const ValidationFailure(<String, String>{
        'body': 'Write something first.',
      });
    }
    final Task task =
        _db.taskById(taskId) ?? (throw NotFoundFailure('task', taskId));

    final Comment comment = Comment(
      id: Ids.comment(),
      taskId: taskId,
      authorId: authorId,
      body: body.trim(),
      createdAt: DateTime.now(),
      replyToId: replyToId,
      mentionedUserIds: mentionedUserIds,
    );

    _db.commit<Comment>(_db.comments, <Comment>[
      ..._db.comments.value,
      comment,
    ], Collections.comments);
    _db.recordActivity(
      Activity(
        id: Ids.activity(),
        workspaceId: task.workspaceId,
        type: ActivityType.commentAdded,
        actorId: authorId,
        createdAt: DateTime.now(),
        taskId: taskId,
        projectId: task.projectId,
      ),
    );

    // Mentions notify; a plain comment notifies the assignee only.
    final Set<String> recipients = <String>{
      ...mentionedUserIds,
      if (task.assigneeId != null) task.assigneeId!,
    }..remove(authorId);

    for (final String recipient in recipients) {
      _db.pushNotification(
        AppNotification(
          id: Ids.notification(),
          workspaceId: task.workspaceId,
          type: mentionedUserIds.contains(recipient)
              ? NotificationType.mention
              : NotificationType.comment,
          title: mentionedUserIds.contains(recipient)
              ? '${_db.userById(authorId)?.name ?? 'Someone'} mentioned you'
              : '${_db.userById(authorId)?.name ?? 'Someone'} commented',
          body: 'in ${task.title}',
          createdAt: DateTime.now(),
          actorId: authorId,
          taskId: taskId,
          projectId: task.projectId,
        ),
      );
    }
    return comment;
  });

  @override
  Future<Comment> editComment(String commentId, String body) =>
      Failure.guard(() async {
        await _db.latency(0.4);
        final Comment comment =
            _db.comments.value
                .where((Comment c) => c.id == commentId)
                .firstOrNull ??
            (throw NotFoundFailure('comment', commentId));
        if (body.trim().isEmpty) {
          throw const ValidationFailure(<String, String>{
            'body': 'A comment can’t be empty.',
          });
        }
        final Comment updated = comment.copyWith(
          body: body.trim(),
          updatedAt: DateTime.now(),
        );
        _write(updated);
        return updated;
      });

  @override
  Future<void> deleteComment(String commentId) => Failure.guard(() async {
    await _db.latency(0.4);
    _db.commit<Comment>(
      _db.comments,
      _db.comments.value.where((Comment c) => c.id != commentId).toList(),
      Collections.comments,
    );
  });

  @override
  Future<Comment> toggleReaction({
    required String commentId,
    required String emoji,
    required String userId,
  }) => Failure.guard(() async {
    final Comment comment =
        _db.comments.value
            .where((Comment c) => c.id == commentId)
            .firstOrNull ??
        (throw NotFoundFailure('comment', commentId));

    final List<Reaction> reactions = <Reaction>[...comment.reactions];
    final int index = reactions.indexWhere((Reaction r) => r.emoji == emoji);
    if (index < 0) {
      reactions.add(Reaction(emoji: emoji, userIds: <String>[userId]));
    } else {
      final Reaction toggled = reactions[index].toggled(userId);
      if (toggled.count == 0) {
        reactions.removeAt(index);
      } else {
        reactions[index] = toggled;
      }
    }

    final Comment updated = comment.copyWith(reactions: reactions);
    _write(updated);
    return updated;
  });

  void _write(Comment comment) {
    _db.commit<Comment>(
      _db.comments,
      _db.comments.value
          .map((Comment c) => c.id == comment.id ? comment : c)
          .toList(),
      Collections.comments,
    );
  }
}

class LocalActivityRepository implements ActivityRepository {
  LocalActivityRepository({required KairoDatabase database}) : _db = database;

  final KairoDatabase _db;

  @override
  Stream<List<Activity>> watchWorkspaceActivity(
    String workspaceId, {
    int limit = 40,
  }) async* {
    await for (final List<Activity> activities in _db.activities.stream) {
      yield activities
          .where((Activity a) => a.workspaceId == workspaceId)
          .take(limit)
          .toList(growable: false);
    }
  }

  @override
  Stream<List<Activity>> watchTaskActivity(String taskId) async* {
    await for (final List<Activity> activities in _db.activities.stream) {
      yield activities
          .where((Activity a) => a.taskId == taskId)
          .toList(growable: false);
    }
  }

  @override
  Stream<List<Activity>> watchProjectActivity(
    String projectId, {
    int limit = 30,
  }) async* {
    await for (final List<Activity> activities in _db.activities.stream) {
      yield activities
          .where((Activity a) => a.projectId == projectId)
          .take(limit)
          .toList(growable: false);
    }
  }
}

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository({required KairoDatabase database})
    : _db = database;

  final KairoDatabase _db;

  @override
  Stream<List<AppNotification>> watchNotifications(String workspaceId) async* {
    await for (final List<AppNotification> items in _db.notifications.stream) {
      yield items
          .where((AppNotification n) => n.workspaceId == workspaceId)
          .toList()
        ..sort(
          (AppNotification a, AppNotification b) =>
              b.createdAt.compareTo(a.createdAt),
        );
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    _db.commit<AppNotification>(
      _db.notifications,
      _db.notifications.value
          .map(
            (AppNotification n) =>
                n.id == notificationId ? n.copyWith(isRead: true) : n,
          )
          .toList(),
      Collections.notifications,
    );
  }

  @override
  Future<void> markAllRead(String workspaceId) async {
    _db.commit<AppNotification>(
      _db.notifications,
      _db.notifications.value
          .map(
            (AppNotification n) =>
                n.workspaceId == workspaceId ? n.copyWith(isRead: true) : n,
          )
          .toList(),
      Collections.notifications,
    );
  }

  @override
  Future<void> clearAll(String workspaceId) async {
    _db.commit<AppNotification>(
      _db.notifications,
      _db.notifications.value
          .where((AppNotification n) => n.workspaceId != workspaceId)
          .toList(),
      Collections.notifications,
    );
  }
}
