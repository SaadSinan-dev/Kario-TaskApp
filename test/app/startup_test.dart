import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/startup.dart';
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

  Map<String, Object> preferences({
    bool onboarded = true,
    String landingRoute = Routes.dashboard,
  }) {
    return <String, Object>{
      SettingsKeys.preferences: jsonEncode(
        UserPreferences(
          hasCompletedOnboarding: onboarded,
          landingRoute: landingRoute,
        ).toJson(),
      ),
    };
  }

  group('route table', () {
    test('the root belongs to the application, not to marketing', () {
      expect(Routes.splash, '/');
      expect(Routes.landing, isNot('/'));
      expect(Routes.marketingRoutes, isNot(contains(Routes.splash)));
    });

    test('the splash is reachable without a session', () {
      expect(Routes.isPublic(Routes.splash), isTrue);
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

    test('a first sign-in goes to onboarding', () async {
      final TestHarness harness = await TestHarness.create(
        preferences: preferences(onboarded: false),
      );
      addTearDown(harness.dispose);

      final StartupResult result = await harness.container.read(
        startupProvider.future,
      );

      expect(result.destination, StartupDestination.onboarding);
      expect(result.route, Routes.onboarding);
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
