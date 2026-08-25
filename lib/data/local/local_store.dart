import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/logging/app_logger.dart';
import 'package:kairo/domain/entities/json_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence is split by *shape of data*, not by convenience.
///
/// * [DocumentStore] — the workspace graph (tasks, projects, comments…). Hive,
///   because it is a real embedded database: fast, transactional-enough, and it
///   works identically on mobile, desktop and web (IndexedDB).
/// * [SettingsStore] — small scalar preferences read at startup.
///   `shared_preferences`, because that is exactly what it is for.
/// * [SecretStore] — the session token. Platform keychain via
///   `flutter_secure_storage`.
///
/// Putting the whole workspace in `shared_preferences` would mean re-encoding
/// every task to change one title; putting a theme flag in Hive would mean
/// opening a database before the first frame.
abstract interface class DocumentStore {
  Future<void> init();
  JsonMap? read(String key);
  Future<void> write(String key, JsonMap value);
  Future<void> delete(String key);
  Future<void> clear();
  bool get isReady;
}

/// Hive-backed document store. Values are stored as JSON strings rather than
/// via generated type adapters — the models already own their serialization,
/// and a JSON payload stays readable in an export and tolerant of schema drift.
class HiveDocumentStore implements DocumentStore {
  HiveDocumentStore({this.boxName = 'kairo_documents'});

  final String boxName;
  static const AppLogger _log = AppLogger('storage');

  Box<String>? _box;

  @override
  bool get isReady => _box?.isOpen ?? false;

  @override
  Future<void> init() async {
    if (isReady) return;
    try {
      await Hive.initFlutter('kairo');
      _box = await Hive.openBox<String>(boxName);
    } catch (error, stackTrace) {
      _log.error(
        'Failed to open the document store; continuing in memory',
        error: error,
        stackTrace: stackTrace,
      );
      throw StorageFailure(cause: error, stackTrace: stackTrace);
    }
  }

  @override
  JsonMap? read(String key) {
    final String? raw = _box?.get(key);
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error) {
      _log.warn(
        'Discarding unreadable record',
        data: <String, Object?>{'key': key},
      );
      return null;
    }
  }

  @override
  Future<void> write(String key, JsonMap value) async {
    final Box<String>? box = _box;
    if (box == null) return;
    await Failure.guard(() => box.put(key, jsonEncode(value)));
  }

  @override
  Future<void> delete(String key) async => _box?.delete(key);

  @override
  Future<void> clear() async => _box?.clear();
}

/// In-memory store used by tests and as a fallback when a platform denies
/// storage access (private browsing, missing keyring). The app degrades to a
/// session-only experience rather than failing to start.
class InMemoryDocumentStore implements DocumentStore {
  final Map<String, JsonMap> _data = <String, JsonMap>{};

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  JsonMap? read(String key) => _data[key];

  @override
  Future<void> write(String key, JsonMap value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}

/// Small, frequently read scalars.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? const <String>[];
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}

/// Keys used with [SettingsStore]. Centralised so a typo can't silently create
/// a second preference.
abstract final class SettingsKeys {
  static const String preferences = 'kairo.preferences';
  static const String activeWorkspace = 'kairo.workspace.active';
  static const String recentSearches = 'kairo.search.recent';
  static const String recentlyViewed = 'kairo.recent.viewed';
  static const String seedVersion = 'kairo.seed.version';
  static const String sessionUserId = 'kairo.session.user';
}
