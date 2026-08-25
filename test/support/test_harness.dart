import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/env/app_environment.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_theme.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/data/repositories/auth_repository_impl.dart';
import 'package:kairo/data/seed/demo_seed.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared setup for every test.
///
/// Builds the same provider graph the app uses, with three substitutions: an
/// in-memory document store, zero simulated latency, and a `SharedPreferences`
/// mock. Nothing else is faked — tests exercise the real repositories, the real
/// query engine and the real widgets.
class TestHarness {
  TestHarness._(this.container, this.database);

  final ProviderContainer container;
  final KairoDatabase database;

  static Future<TestHarness> create({
    Map<String, Object> preferences = const <String, Object>{},
    bool signIn = true,
  }) async {
    SharedPreferences.setMockInitialValues(preferences);

    final DocumentStore documents = InMemoryDocumentStore();
    await documents.init();
    final SettingsStore settings = await SettingsStore.open();

    final ProviderContainer container = ProviderContainer(
      overrides: [
        environmentProvider.overrideWithValue(AppEnvironment.test),
        documentStoreProvider.overrideWithValue(documents),
        settingsStoreProvider.overrideWithValue(settings),
        // The platform keychain is unavailable in tests; the in-memory
        // fallback inside SecretStore handles it, but overriding here keeps
        // the test output free of platform-channel warnings.
        secretStoreProvider.overrideWithValue(SecretStore()),
      ],
    );

    final KairoDatabase database = container.read(databaseProvider);
    await database.initialize();

    if (signIn) {
      await container.read(authRepositoryProvider).signInAsDemo();
      // Keep the session and workspace providers alive and let their streams
      // deliver a first value, so synchronous reads in tests see real data.
      container.listen<AsyncValue<User?>>(
        currentUserProvider,
        (_, _) {},
        fireImmediately: true,
      );
      container.listen(
        activeWorkspaceProvider,
        (_, _) {},
        fireImmediately: true,
      );
      // Warm the collection streams too: the app rebuilds when they emit, but
      // a test that reads synchronously needs them settled first.
      container.listen(tasksProvider, (_, _) {}, fireImmediately: true);
      container.listen(projectsProvider, (_, _) {}, fireImmediately: true);
      container.listen(allProjectsProvider, (_, _) {}, fireImmediately: true);
      container.listen(labelsProvider, (_, _) {}, fireImmediately: true);
      container.listen(membersProvider, (_, _) {}, fireImmediately: true);
      container.listen(notificationsProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    return TestHarness._(container, database);
  }

  void dispose() => container.dispose();

  /// Read straight from the repository: it is the synchronous source of truth,
  /// whereas `currentUserProvider` is a stream that settles a microtask later.
  User get demoUser => container.read(authRepositoryProvider).currentUser!;

  String get workspaceId =>
      container.read(activeWorkspaceIdProvider) ?? DemoSeed.workspaceId;

  /// Waits for the stream providers to deliver their first values.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }
}

/// Wraps a widget in the app's real theme, localisations and provider scope.
///
/// Deliberately does *not* override `MediaQuery.size`: a widget that is told it
/// has 1400px while laying out inside an 800px surface will overflow, and the
/// test would be lying about the environment. Size the real surface with
/// [setSurface] instead.
///
/// Motion is switched off through the same `MotionScope` the accessibility
/// preference uses, so tests exercise a real code path rather than a
/// test-only branch — and do not have to pump animation frames.
Widget wrapForTest(Widget child, {required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MotionScope(reduceMotion: true, child: Scaffold(body: child)),
    ),
  );
}

/// Sets the real test surface so breakpoint-dependent widgets lay out exactly
/// as they would on a device of that size.
void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Common phone and desktop surfaces used by the responsive tests.
abstract final class Surfaces {
  static const Size phone = Size(390, 844);
  static const Size tablet = Size(900, 1200);
  static const Size desktop = Size(1512, 950);
}
