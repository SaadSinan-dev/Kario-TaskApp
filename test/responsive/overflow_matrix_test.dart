import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/kairo_app.dart';
import 'package:kairo/core/routing/app_router.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';

import '../support/test_harness.dart';

/// Renders the whole product at every device size the design supports and
/// fails on any layout exception.
///
/// This is the regression net for the responsive pass. Overflow is reported by
/// `RenderFlex`/`RenderBox` during paint, so rendering every route at every
/// size is the only honest way to support the claim "no screen overflows" —
/// the assertions are on real framework errors, never on a screenshot or a
/// manual read of the code.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The sizes named in the responsive brief, smallest first. 320x568 is the
  /// floor: it is the smallest screen the product claims to support, and it is
  /// where fixed-width layouts break first.
  const Map<String, Size> devices = <String, Size>{
    'compact 320x568': Size(320, 568),
    'phone 360x800': Size(360, 800),
    'phone 375x812': Size(375, 812),
    'phone 390x844': Size(390, 844),
    'phone 412x915': Size(412, 915),
    'tablet 768x1024': Size(768, 1024),
    'tablet-land 1024x768': Size(1024, 768),
    'desktop 1280x800': Size(1280, 800),
    'desktop 1440x900': Size(1440, 900),
  };

  /// Every route that renders inside the application shell.
  const Map<String, String> appRoutes = <String, String>{
    'dashboard': Routes.dashboard,
    'tasks': Routes.tasks,
    'inbox': Routes.inbox,
    'projects': Routes.projects,
    'calendar': Routes.calendar,
    'timeline': Routes.timeline,
    'focus': Routes.focus,
    'analytics': Routes.analytics,
    'notifications': Routes.notifications,
    'search': Routes.search,
    'favorites': Routes.favorites,
    'archive': Routes.archive,
    'settings': Routes.settings,
  };

  /// Routes rendered outside the shell.
  const Map<String, String> publicRoutes = <String, String>{
    'splash': Routes.splash,
    'login': Routes.login,
    'signup': Routes.signup,
    'forgot-password': Routes.forgotPassword,
    'landing': Routes.landing,
    'pricing': Routes.pricing,
    'about': Routes.about,
  };

  /// Seeds preferences through the real serialiser, before the container is
  /// built.
  ///
  /// Preferences cannot be written from inside a `testWidgets` body: it runs
  /// against a faked clock, so awaiting the repository's save never returns.
  /// Seeding `SharedPreferences` sidesteps the clock and still exercises the
  /// production `fromJson` path.
  Map<String, Object> seededPreferences({
    bool onboarded = true,
    ThemePreference theme = ThemePreference.light,
    TaskViewType view = TaskViewType.list,
  }) {
    return <String, Object>{
      SettingsKeys.preferences: jsonEncode(
        UserPreferences(
          theme: theme,
          hasCompletedOnboarding: onboarded,
          defaultTaskView: view,
        ).toJson(),
      ),
    };
  }

  /// Collects every framework error raised while [body] runs instead of letting
  /// the first one abort the run, so one pass reports every broken screen
  /// rather than one per invocation.
  Future<List<String>> collectErrors(Future<void> Function() body) async {
    final List<String> found = <String>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // The message alone ("overflowed by 69 pixels") is not actionable, so
      // the widget Flutter blames is pulled out of the full diagnostics and
      // carried along with it.
      final String full = details.toString();
      final RegExpMatch? blame = RegExp(
        r'The relevant error-causing widget was:\s*\n?\s*(\S+)',
      ).firstMatch(full);
      final RegExpMatch? source = RegExp(
        r'(lib[\\/][\w\\/.]+\.dart:\d+:\d+)',
      ).firstMatch(full);
      final String where = <String?>[
        blame?.group(1),
        source?.group(1),
      ].whereType<String>().join(' — ');
      found.add(
        where.isEmpty
            ? details.exceptionAsString()
            : '${details.exceptionAsString()}  [$where]',
      );
    };
    try {
      await body();
    } finally {
      FlutterError.onError = previous;
    }
    return found;
  }

  /// Layout exceptions only. An unrelated error should still fail loudly
  /// through the normal channel rather than be mistaken for an overflow.
  bool isLayoutError(String message) {
    return message.contains('overflowed') ||
        message.contains('RenderFlex') ||
        message.contains('RenderBox was not laid out') ||
        message.contains('unbounded') ||
        message.contains('infinite size');
  }

  /// Pumps the real app — real router, real shell, real screens — at [size].
  Future<List<String>> renderRoute(
    WidgetTester tester,
    TestHarness harness,
    String location,
    Size size,
  ) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return collectErrors(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: const KairoApp(),
        ),
      );
      harness.container.read(routerProvider).go(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Settle the entrance so the resting layout is measured as well as the
      // animated one — a screen can fit while animating and overflow at rest.
      await tester.pump(const Duration(seconds: 1));
    });
  }

  /// Renders [routes] at [size] and returns a readable failure per overflow.
  Future<List<String>> sweep(
    WidgetTester tester,
    TestHarness harness,
    Map<String, String> routes,
    Size size,
  ) async {
    final List<String> failures = <String>[];
    for (final MapEntry<String, String> route in routes.entries) {
      final List<String> errors = await renderRoute(
        tester,
        harness,
        route.value,
        size,
      );
      for (final String error in errors.where(isLayoutError)) {
        failures.add(
          '${route.key} @ ${size.width.toInt()}: '
          '${error.split('\n').first}',
        );
      }
    }
    return failures;
  }

  group('app routes at every supported size', () {
    late TestHarness harness;

    // Built here rather than inside the test body: `TestHarness.create` awaits
    // real futures, which never resolve against the widget tester's clock.
    setUp(() async {
      harness = await TestHarness.create(preferences: seededPreferences());
    });
    tearDown(() => harness.dispose());

    for (final MapEntry<String, Size> device in devices.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        final List<String> failures = await sweep(
          tester,
          harness,
          appRoutes,
          device.value,
        );
        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  });

  // The task screen defaults to the list, so board, calendar and timeline
  // layouts are never reached by the sweep above. They are the views most
  // likely to break on a phone — a Kanban board and a Gantt chart are desktop
  // shapes — so each one gets its own pass with that view made the default.
  for (final MapEntry<String, TaskViewType> view in <String, TaskViewType>{
    'board': TaskViewType.board,
    'calendar': TaskViewType.calendar,
    'timeline': TaskViewType.timeline,
  }.entries) {
    group('tasks screen in ${view.key} view', () {
      late TestHarness harness;

      setUp(() async {
        harness = await TestHarness.create(
          preferences: seededPreferences(view: view.value),
        );
      });
      tearDown(() => harness.dispose());

      for (final MapEntry<String, Size> device in devices.entries) {
        testWidgets(device.key, (WidgetTester tester) async {
          final List<String> failures = await sweep(
            tester,
            harness,
            <String, String>{'tasks-${view.key}': Routes.tasks},
            device.value,
          );
          expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
        });
      }
    });
  }

  group('app routes in dark mode', () {
    late TestHarness harness;

    setUp(() async {
      harness = await TestHarness.create(
        preferences: seededPreferences(theme: ThemePreference.dark),
      );
    });
    tearDown(() => harness.dispose());

    // Dark mode changes colour, not constraints, so a representative span of
    // sizes is enough to catch a layout that only exists in one theme.
    const Map<String, Size> darkSizes = <String, Size>{
      'compact 320x568': Size(320, 568),
      'phone 390x844': Size(390, 844),
      'tablet 768x1024': Size(768, 1024),
      'desktop 1440x900': Size(1440, 900),
    };

    for (final MapEntry<String, Size> device in darkSizes.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        final List<String> failures = await sweep(
          tester,
          harness,
          appRoutes,
          device.value,
        );
        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  });

  group('splash, auth and marketing at every supported size', () {
    late TestHarness harness;

    setUp(() async {
      harness = await TestHarness.create(signIn: false);
    });
    tearDown(() => harness.dispose());

    for (final MapEntry<String, Size> device in devices.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        final List<String> failures = await sweep(
          tester,
          harness,
          publicRoutes,
          device.value,
        );
        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  });

  group('onboarding at every supported size', () {
    late TestHarness harness;

    setUp(() async {
      harness = await TestHarness.create(
        preferences: seededPreferences(onboarded: false),
      );
    });
    tearDown(() => harness.dispose());

    for (final MapEntry<String, Size> device in devices.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        final List<String> failures = await sweep(
          tester,
          harness,
          const <String, String>{'onboarding': Routes.onboarding},
          device.value,
        );
        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  });
}
