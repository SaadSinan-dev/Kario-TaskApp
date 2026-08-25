import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/startup.dart';
import 'package:kairo/core/routing/app_router.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/domain/entities/preferences.dart';

import '../support/test_harness.dart';

/// Locks the startup contract.
///
/// The rule this protects is easy to break by accident and expensive to notice:
/// the product must open on its own splash and route from there, never on the
/// marketing site. A one-line change to `initialLocation` would undo it
/// silently, so the guarantee is asserted rather than assumed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object> preferences({String landingRoute = Routes.dashboard}) {
    return <String, Object>{
      SettingsKeys.preferences: jsonEncode(
        UserPreferences(landingRoute: landingRoute).toJson(),
      ),
    };
  }

  group('route table', () {
    test('the application owns the root path', () {
      expect(Routes.splash, '/');
    });

    test('the splash is reachable without a session', () {
      expect(Routes.isPublic(Routes.splash), isTrue);
    });

    // The defect this guards against was live: `/onboarding` was declared and
    // navigated to after a first sign-in, but no `GoRoute` matched it, so new
    // users landed on the 404 screen. Declaring a path is not the same as
    // registering it, and only the router knows the difference.
    test('every declared route resolves to a screen', () async {
      final TestHarness harness = await TestHarness.create(
        preferences: preferences(),
      );
      addTearDown(harness.dispose);

      final GoRouter router = harness.container.read(routerProvider);
      final List<String> unresolved = <String>[];

      for (final String route in Routes.allRegistered) {
        // Path parameters are placeholders, not navigable locations; give them
        // a concrete value so the match is a fair one.
        final String location = route
            .replaceAll(':projectId', 'prj_demo')
            .replaceAll(':section', 'profile');

        final RouteMatchList match = router.configuration.findMatch(
          Uri.parse(location),
        );
        if (match.isError) unresolved.add(route);
      }

      expect(
        unresolved,
        isEmpty,
        reason: 'declared but not registered: ${unresolved.join(', ')}',
      );
    });
  });

  group('startup decides where to go', () {
    test('a signed-out launch goes to sign-in', () async {
      final TestHarness harness = await TestHarness.create(signIn: false);
      addTearDown(harness.dispose);

      final StartupResult result = await harness.container.read(
        startupProvider.future,
      );

      expect(result.destination, StartupDestination.signIn);
      expect(result.route, Routes.login);
    });

    test('a returning user goes to their landing route', () async {
      final TestHarness harness = await TestHarness.create(
        preferences: preferences(landingRoute: Routes.tasks),
      );
      addTearDown(harness.dispose);

      final StartupResult result = await harness.container.read(
        startupProvider.future,
      );

      expect(result.destination, StartupDestination.workspace);
      expect(result.route, Routes.tasks);
    });

    test('startup restores the session it finds', () async {
      final TestHarness harness = await TestHarness.create(
        preferences: preferences(),
      );
      addTearDown(harness.dispose);

      await harness.container.read(startupProvider.future);

      expect(
        harness.container.read(authRepositoryProvider).currentUser,
        isNotNull,
      );
    });
  });
}
