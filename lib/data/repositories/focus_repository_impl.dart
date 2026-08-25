import 'dart:async';
import 'dart:convert';

import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/local/value_stream.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/repositories/repositories.dart';

class LocalFocusRepository implements FocusRepository {
  LocalFocusRepository({required KairoDatabase database}) : _db = database;

  final KairoDatabase _db;

  @override
  Stream<List<FocusSession>> watchSessions(String workspaceId) async* {
    await for (final List<FocusSession> sessions in _db.focusSessions.stream) {
      yield sessions
          .where((FocusSession s) => s.workspaceId == workspaceId)
          .toList()
        ..sort(
          (FocusSession a, FocusSession b) =>
              b.startedAt.compareTo(a.startedAt),
        );
    }
  }

  @override
  Future<void> recordSession(FocusSession session) async {
    _db.commit<FocusSession>(_db.focusSessions, <FocusSession>[
      ..._db.focusSessions.value,
      session,
    ], Collections.focusSessions);
  }

  @override
  Future<int> minutesToday(String workspaceId) async {
    final DateTime today = Dates.today();
    return _db.focusSessions.value
        .where(
          (FocusSession s) =>
              s.workspaceId == workspaceId &&
              s.phase == FocusPhase.focus &&
              Dates.isSameDay(s.startedAt, today),
        )
        .fold<int>(0, (int sum, FocusSession s) => sum + s.actualMinutes);
  }
}

/// Preferences are read on the very first frame (to pick a theme before paint),
/// so they live in `shared_preferences` and are cached in memory.
class LocalPreferencesRepository implements PreferencesRepository {
  LocalPreferencesRepository({required SettingsStore settings})
    : _settings = settings {
    _stream = ValueStream<UserPreferences>(_load());
  }

  final SettingsStore _settings;
  late final ValueStream<UserPreferences> _stream;

  @override
  UserPreferences get current => _stream.value;

  @override
  Stream<UserPreferences> watchPreferences() => _stream.stream;

  @override
  Future<void> save(UserPreferences preferences) async {
    _stream.add(preferences);
    await _settings.setString(
      SettingsKeys.preferences,
      jsonEncode(preferences.toJson()),
    );
  }

  UserPreferences _load() {
    final String? raw = _settings.getString(SettingsKeys.preferences);
    if (raw == null || raw.isEmpty) return const UserPreferences();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserPreferences.fromJson(decoded);
      }
    } catch (_) {
      // A malformed record is not worth failing startup over.
    }
    return const UserPreferences();
  }
}
