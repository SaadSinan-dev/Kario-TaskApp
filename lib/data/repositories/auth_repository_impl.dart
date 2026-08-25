import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/logging/app_logger.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/local/value_stream.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Stores the session token in the platform keychain, degrading to memory when
/// a platform denies access (Linux without a keyring, private browsing).
///
/// Degrading rather than crashing is deliberate: losing a session on restart is
/// a far better outcome than an app that will not start.
class SecretStore {
  SecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const AppLogger _log = AppLogger('secrets');
  static const String _sessionKey = 'kairo.session.token';

  final FlutterSecureStorage _storage;
  final Map<String, String> _fallback = <String, String>{};
  bool _useFallback = false;

  Future<String?> readSession() async {
    if (_useFallback) return _fallback[_sessionKey];
    try {
      return await _storage.read(key: _sessionKey);
    } catch (error) {
      _log.warn('Secure storage unavailable; using in-memory session');
      _useFallback = true;
      return _fallback[_sessionKey];
    }
  }

  Future<void> writeSession(String token) async {
    if (_useFallback) {
      _fallback[_sessionKey] = token;
      return;
    }
    try {
      await _storage.write(key: _sessionKey, value: token);
    } catch (error) {
      _useFallback = true;
      _fallback[_sessionKey] = token;
    }
  }

  Future<void> clearSession() async {
    _fallback.remove(_sessionKey);
    if (_useFallback) return;
    try {
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      _useFallback = true;
    }
  }
}

/// Local authentication adapter.
///
/// **Security note.** Credential verification in a real deployment happens on a
/// server; a client can only ever *claim* an identity. What this class does is
/// give the offline demo honest behaviour — a wrong password is rejected, a
/// session survives a restart, and the interface is exactly what an HTTP
/// implementation would satisfy. Passwords are salted and hashed before they
/// touch storage so a plaintext credential is never written to the device, but
/// that is a hygiene measure for a demo, not a substitute for a real identity
/// provider. Swapping this for `HttpAuthRepository` is a one-line provider
/// override — no UI changes.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required KairoDatabase database,
    required SettingsStore settings,
    required SecretStore secrets,
  }) : _db = database,
       _settings = settings,
       _secrets = secrets;

  final KairoDatabase _db;
  final SettingsStore _settings;
  final SecretStore _secrets;

  static const AppLogger _log = AppLogger('auth');
  static const String _credentialsKey = 'kairo.credentials';

  final ValueStream<User?> _currentUser = ValueStream<User?>(null);

  @override
  User? get currentUser => _currentUser.value;

  @override
  Stream<User?> watchCurrentUser() => _currentUser.stream;

  /// Restores a session saved on a previous launch.
  Future<void> restoreSession() async {
    final String? token = await _secrets.readSession();
    if (token == null) return;
    final String? userId = _settings.getString(SettingsKeys.sessionUserId);
    if (userId == null) return;
    final User? user = _db.userById(userId);
    if (user == null) {
      await _secrets.clearSession();
      return;
    }
    _currentUser.add(user);
    _log.info('Session restored');
  }

  @override
  Future<User> signIn({required String email, required String password}) =>
      Failure.guard(() async {
        await _db.latency();
        final String normalised = email.trim().toLowerCase();

        final User? user = _db.users.value
            .where((User u) => u.email.toLowerCase() == normalised)
            .firstOrNull;

        if (user == null) {
          throw const AuthFailure(AuthFailureReason.unknownAccount);
        }

        if (!_verify(normalised, password)) {
          throw const AuthFailure(AuthFailureReason.invalidCredentials);
        }

        await _startSession(user);
        return user;
      });

  @override
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) => Failure.guard(() async {
    await _db.latency(1.4);
    final String normalised = email.trim().toLowerCase();

    final bool exists = _db.users.value.any(
      (User u) => u.email.toLowerCase() == normalised,
    );
    if (exists) {
      throw const AuthFailure(AuthFailureReason.emailAlreadyInUse);
    }
    if (password.length < 8) {
      throw const AuthFailure(AuthFailureReason.weakPassword);
    }

    final User user = User(
      id: Ids.user(),
      name: name.trim(),
      email: normalised,
      jobTitle: '',
      accentColorValue: _accentFor(normalised),
      createdAt: DateTime.now(),
      isEmailVerified: false,
    );

    _db.commit<User>(_db.users, <User>[
      ..._db.users.value,
      user,
    ], Collections.users);

    // A new account starts with its own workspace, otherwise the first screen
    // after signup would be empty and there would be nowhere to put a task.
    final Workspace workspace = Workspace(
      id: Ids.workspace(),
      name: '${user.firstName}’s workspace',
      ownerId: user.id,
      createdAt: DateTime.now(),
      members: <WorkspaceMember>[
        WorkspaceMember(
          userId: user.id,
          role: WorkspaceRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
    );
    _db.commit<Workspace>(_db.workspaces, <Workspace>[
      ..._db.workspaces.value,
      workspace,
    ], Collections.workspaces);
    await _settings.setString(SettingsKeys.activeWorkspace, workspace.id);

    await _storeCredential(normalised, password);
    await _startSession(user);
    return user;
  });

  @override
  Future<User> signInAsDemo() => Failure.guard(() async {
    await _db.latency(0.6);
    final User user =
        _db.userById(DemoSeed.demoUserId) ??
        (throw const NotFoundFailure('user', DemoSeed.demoUserId));
    await _settings.setString(
      SettingsKeys.activeWorkspace,
      DemoSeed.workspaceId,
    );
    await _startSession(user);
    return user;
  });

  @override
  Future<void> signOut() async {
    await _secrets.clearSession();
    await _settings.remove(SettingsKeys.sessionUserId);
    _currentUser.add(null);
  }

  @override
  Future<void> requestPasswordReset(String email) => Failure.guard(() async {
    await _db.latency(1.2);
    // Deliberately does not reveal whether the address exists — the same
    // response for every input is what a real endpoint should do.
    _log.info('Password reset requested');
  });

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => Failure.guard(() async {
    await _db.latency(1.2);
    if (password.length < 8) {
      throw const AuthFailure(AuthFailureReason.weakPassword);
    }
    final User? user = currentUser;
    if (user != null) await _storeCredential(user.email, password);
  });

  @override
  Future<void> verifyEmail(String code) => Failure.guard(() async {
    await _db.latency();
    if (code.trim().length != 6) {
      throw const ValidationFailure(<String, String>{
        'code': 'Enter the six-digit code.',
      });
    }
    final User? user = currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureReason.sessionExpired);
    }
    final User verified = user.copyWith(isEmailVerified: true);
    _replaceUser(verified);
    _currentUser.add(verified);
  });

  @override
  Future<void> resendVerificationCode() => Failure.guard(() async {
    await _db.latency();
    _log.info('Verification code resent');
  });

  @override
  Future<User> updateProfile(User user) => Failure.guard(() async {
    await _db.latency(0.8);
    _replaceUser(user);
    if (currentUser?.id == user.id) _currentUser.add(user);
    return user;
  });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => Failure.guard(() async {
    await _db.latency(1.2);
    final User? user = currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureReason.sessionExpired);
    }
    if (!_verify(user.email.toLowerCase(), currentPassword)) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    if (newPassword.length < 8) {
      throw const AuthFailure(AuthFailureReason.weakPassword);
    }
    await _storeCredential(user.email.toLowerCase(), newPassword);
  });

  // --- Internals ------------------------------------------------------------

  Future<void> _startSession(User user) async {
    await _secrets.writeSession(_newToken());
    await _settings.setString(SettingsKeys.sessionUserId, user.id);
    _currentUser.add(user);
  }

  void _replaceUser(User user) {
    _db.commit<User>(
      _db.users,
      _db.users.value.map((User u) => u.id == user.id ? user : u).toList(),
      Collections.users,
    );
  }

  /// `email -> salt:hash`, kept in the settings store rather than the document
  /// store so a workspace export never contains credential material.
  Future<void> _storeCredential(String email, String password) async {
    final List<String> entries = _settings
        .getStringList(_credentialsKey)
        .where((String entry) => !entry.startsWith('$email|'))
        .toList();
    final String salt = _newToken();
    entries.add('$email|$salt|${_hash(password, salt)}');
    await _settings.setStringList(_credentialsKey, entries);
  }

  bool _verify(String email, String password) {
    // The seeded demo account has a published password so the demo is usable
    // from the sign-in screen as well as the one-tap button.
    if (email == DemoSeed.demoEmail) {
      return password == DemoSeed.demoPassword;
    }

    final String? entry = _settings
        .getStringList(_credentialsKey)
        .where((String e) => e.startsWith('$email|'))
        .firstOrNull;

    // Seeded teammates have no stored credential. Any well-formed password
    // signs them in so the demo can be explored from another person's seat.
    if (entry == null) return password.length >= 8;

    final List<String> parts = entry.split('|');
    if (parts.length != 3) return false;
    return _hash(password, parts[1]) == parts[2];
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  static final Random _random = Random.secure();

  String _newToken() {
    final List<int> bytes = List<int>.generate(
      24,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64Url.encode(bytes);
  }

  int _accentFor(String seed) {
    const List<int> palette = <int>[
      0xFF3B6BF5,
      0xFF7C3AED,
      0xFF0D9488,
      0xFFEA580C,
      0xFF22C55E,
      0xFF0EA5E9,
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }
}
