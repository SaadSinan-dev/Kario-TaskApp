import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/env/app_environment.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/logging/app_logger.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';

/// Critical startup only — the work the very first frame cannot render without.
///
/// This is deliberately the *short* half of startup. Opening the stores is
/// required before any provider can be read, so it blocks; loading the
/// workspace and restoring the session is comparatively expensive and is
/// deferred to `startupProvider`, which runs behind the splash. The split is
/// what keeps the window from sitting blank while the workspace is read.
///
/// Failures degrade rather than crash — if the embedded database cannot be
/// opened (private browsing, a locked profile) the app falls back to in-memory
/// storage and runs as a session-only experience.
Future<ProviderContainer> bootstrap({
  AppEnvironment? environment,
  DocumentStore? documentStore,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  const AppLogger log = AppLogger('bootstrap');
  final AppEnvironment env = environment ?? AppEnvironment.resolve();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  DocumentStore documents = documentStore ?? HiveDocumentStore();
  try {
    await documents.init();
  } on Failure catch (error) {
    log.warn('Falling back to in-memory storage', error: error);
    documents = InMemoryDocumentStore();
    await documents.init();
  }

  final SettingsStore settings = await SettingsStore.open();

  final ProviderContainer container = ProviderContainer(
    // The three leaves of the provider graph. Everything else is derived, so
    // these are the only overrides the app (or a test) ever needs.
    overrides: [
      environmentProvider.overrideWithValue(env),
      documentStoreProvider.overrideWithValue(documents),
      settingsStoreProvider.overrideWithValue(settings),
    ],
  );

  // Preferences come from the settings store that is already open, so reading
  // them here costs nothing and lets the very first frame paint in the user's
  // chosen theme instead of flashing the default one.
  container.read(preferencesProvider);

  log.info(
    'Critical startup complete',
    data: <String, Object?>{'flavor': env.flavor.name, 'mock': env.useMockData},
  );

  return container;
}

/// Installs global error handling. Framework errors are logged and, in release,
/// swallowed rather than shown as a red screen.
void installErrorHandling() {
  const AppLogger log = AppLogger('flutter');

  FlutterError.onError = (FlutterErrorDetails details) {
    log.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    log.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };
}

/// Flushes pending writes when the app is backgrounded, so nothing debounced is
/// lost if the process is killed.
class PersistenceLifecycleObserver with WidgetsBindingObserver {
  PersistenceLifecycleObserver(this._database);

  final KairoDatabase _database;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_database.flush());
    }
  }
}
