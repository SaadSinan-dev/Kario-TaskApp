import 'dart:async';

import 'package:kairo/core/env/app_environment.dart';
import 'package:kairo/core/logging/app_logger.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/local/value_stream.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/json_support.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';

/// The local source of truth.
///
/// Everything lives in memory as typed lists and is mirrored to the document
/// store; reads are synchronous and writes are optimistic, which is what makes
/// dragging a card across a board feel instant. Persistence is debounced so a
/// drag gesture produces one write rather than sixty.
///
/// This is deliberately the *only* class that knows data is stored locally. The
/// repositories above it are written as though they were talking to a service.
class KairoDatabase {
  KairoDatabase({
    required DocumentStore documents,
    required SettingsStore settings,
    required AppEnvironment environment,
  }) : _documents = documents,
       _settings = settings,
       _environment = environment;

  final DocumentStore _documents;
  final SettingsStore _settings;
  final AppEnvironment _environment;

  static const AppLogger _log = AppLogger('database');

  final ValueStream<List<User>> users = ValueStream<List<User>>(const <User>[]);
  final ValueStream<List<Workspace>> workspaces = ValueStream<List<Workspace>>(
    const <Workspace>[],
  );
  final ValueStream<List<Label>> labels = ValueStream<List<Label>>(
    const <Label>[],
  );
  final ValueStream<List<Project>> projects = ValueStream<List<Project>>(
    const <Project>[],
  );
  final ValueStream<List<Task>> tasks = ValueStream<List<Task>>(const <Task>[]);
  final ValueStream<List<Comment>> comments = ValueStream<List<Comment>>(
    const <Comment>[],
  );
  final ValueStream<List<Activity>> activities = ValueStream<List<Activity>>(
    const <Activity>[],
  );
  final ValueStream<List<AppNotification>> notifications =
      ValueStream<List<AppNotification>>(const <AppNotification>[]);
  final ValueStream<List<FocusSession>> focusSessions =
      ValueStream<List<FocusSession>>(const <FocusSession>[]);

  final Map<String, Timer> _pendingWrites = <String, Timer>{};
  bool _initialised = false;

  static const Duration _writeDebounce = Duration(milliseconds: 220);

  /// Simulated round-trip so loading and skeleton states are exercised during
  /// development. Zero in tests and in release builds of the demo.
  Future<void> latency([double multiplier = 1]) {
    final Duration base = _environment.mockLatency;
    if (base == Duration.zero) return Future<void>.value();
    return Future<void>.delayed(
      Duration(microseconds: (base.inMicroseconds * multiplier).round()),
    );
  }

  Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;

    final int storedVersion =
        int.tryParse(_settings.getString(SettingsKeys.seedVersion) ?? '') ?? 0;
    final bool needsSeed =
        storedVersion != DemoSeed.version ||
        _documents.read(_Keys.tasks) == null;

    if (needsSeed) {
      _log.info(
        'Seeding demo workspace',
        data: <String, Object?>{'from': storedVersion, 'to': DemoSeed.version},
      );
      await _seed();
    } else {
      _restore();
    }
  }

  /// Replaces all local content with a fresh copy of the demo workspace.
  Future<void> resetToSeed() async {
    await _documents.clear();
    await _seed();
  }

  Future<void> _seed() async {
    final SeedData seed = DemoSeed.build();
    users.add(seed.users);
    workspaces.add(seed.workspaces);
    labels.add(seed.labels);
    projects.add(seed.projects);
    tasks.add(seed.tasks);
    comments.add(seed.comments);
    activities.add(seed.activities);
    notifications.add(seed.notifications);
    focusSessions.add(seed.focusSessions);

    await Future.wait<void>(<Future<void>>[
      _writeNow(_Keys.users),
      _writeNow(_Keys.workspaces),
      _writeNow(_Keys.labels),
      _writeNow(_Keys.projects),
      _writeNow(_Keys.tasks),
      _writeNow(_Keys.comments),
      _writeNow(_Keys.activities),
      _writeNow(_Keys.notifications),
      _writeNow(_Keys.focusSessions),
    ]);
    await _settings.setString(
      SettingsKeys.seedVersion,
      DemoSeed.version.toString(),
    );
  }

  void _restore() {
    users.add(_readList(_Keys.users, User.fromJson));
    workspaces.add(_readList(_Keys.workspaces, Workspace.fromJson));
    labels.add(_readList(_Keys.labels, Label.fromJson));
    projects.add(_readList(_Keys.projects, Project.fromJson));
    tasks.add(_readList(_Keys.tasks, Task.fromJson));
    comments.add(_readList(_Keys.comments, Comment.fromJson));
    activities.add(_readList(_Keys.activities, Activity.fromJson));
    notifications.add(_readList(_Keys.notifications, AppNotification.fromJson));
    focusSessions.add(_readList(_Keys.focusSessions, FocusSession.fromJson));
  }

  List<T> _readList<T>(String key, T Function(JsonMap) decode) {
    final JsonMap? document = _documents.read(key);
    if (document == null) return <T>[];
    return readObjectList(document['items']).map(decode).toList();
  }

  /// Publishes [next] on [stream] and schedules a debounced write.
  void commit<T>(ValueStream<List<T>> stream, List<T> next, String key) {
    stream.add(List<T>.unmodifiable(next));
    _scheduleWrite(key);
  }

  void _scheduleWrite(String key) {
    _pendingWrites[key]?.cancel();
    _pendingWrites[key] = Timer(_writeDebounce, () {
      unawaited(_writeNow(key));
    });
  }

  Future<void> _writeNow(String key) async {
    _pendingWrites.remove(key)?.cancel();
    final List<JsonMap> items = switch (key) {
      _Keys.users => users.value.map((User e) => e.toJson()).toList(),
      _Keys.workspaces =>
        workspaces.value.map((Workspace e) => e.toJson()).toList(),
      _Keys.labels => labels.value.map((Label e) => e.toJson()).toList(),
      _Keys.projects => projects.value.map((Project e) => e.toJson()).toList(),
      _Keys.tasks => tasks.value.map((Task e) => e.toJson()).toList(),
      _Keys.comments => comments.value.map((Comment e) => e.toJson()).toList(),
      _Keys.activities =>
        activities.value.map((Activity e) => e.toJson()).toList(),
      _Keys.notifications =>
        notifications.value.map((AppNotification e) => e.toJson()).toList(),
      _Keys.focusSessions =>
        focusSessions.value.map((FocusSession e) => e.toJson()).toList(),
      _ => const <JsonMap>[],
    };
    await _documents.write(key, <String, dynamic>{'items': items});
  }

  /// Flushes anything still debounced. Called when the app is backgrounded.
  Future<void> flush() async {
    final List<String> keys = _pendingWrites.keys.toList();
    await Future.wait<void>(keys.map(_writeNow));
  }

  Future<void> dispose() async {
    for (final Timer timer in _pendingWrites.values) {
      timer.cancel();
    }
    _pendingWrites.clear();
    await Future.wait<void>(<Future<void>>[
      users.close(),
      workspaces.close(),
      labels.close(),
      projects.close(),
      tasks.close(),
      comments.close(),
      activities.close(),
      notifications.close(),
      focusSessions.close(),
    ]);
  }

  // --- Convenience accessors used by the repositories ----------------------

  Task? taskById(String id) =>
      tasks.value.where((Task t) => t.id == id).firstOrNull;

  Project? projectById(String id) =>
      projects.value.where((Project p) => p.id == id).firstOrNull;

  User? userById(String id) =>
      users.value.where((User u) => u.id == id).firstOrNull;

  Workspace? workspaceById(String id) =>
      workspaces.value.where((Workspace w) => w.id == id).firstOrNull;

  /// Appends an activity record. Every mutating repository call routes through
  /// here, which is what keeps the feed complete without scattering writes.
  void recordActivity(Activity activity) {
    commit<Activity>(activities, <Activity>[
      activity,
      ...activities.value,
    ], _Keys.activities);
  }

  void pushNotification(AppNotification notification) {
    commit<AppNotification>(notifications, <AppNotification>[
      notification,
      ...notifications.value,
    ], _Keys.notifications);
  }
}

/// Document keys. One record per collection: the whole workspace is well under
/// a megabyte, and rewriting a collection is cheaper than maintaining an index.
abstract final class _Keys {
  static const String users = 'users';
  static const String workspaces = 'workspaces';
  static const String labels = 'labels';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String comments = 'comments';
  static const String activities = 'activities';
  static const String notifications = 'notifications';
  static const String focusSessions = 'focus_sessions';
}

/// Exposed so repositories can name the collection they are committing without
/// reaching into a private class.
abstract final class Collections {
  static const String users = _Keys.users;
  static const String workspaces = _Keys.workspaces;
  static const String labels = _Keys.labels;
  static const String projects = _Keys.projects;
  static const String tasks = _Keys.tasks;
  static const String comments = _Keys.comments;
  static const String activities = _Keys.activities;
  static const String notifications = _Keys.notifications;
  static const String focusSessions = _Keys.focusSessions;
}
