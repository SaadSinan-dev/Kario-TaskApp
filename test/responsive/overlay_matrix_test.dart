import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/kairo_app.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/routing/app_router.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_row.dart';

import '../support/test_harness.dart';

/// Overlays — sheets, dialogs, the composer — at phone sizes, **with the
/// keyboard up**.
///
/// The route matrix renders screens, and screens alone were clean. The bug this
/// file exists for lived one layer further in: opening the task composer on a
/// phone autofocuses its title field, the keyboard takes roughly a third of the
/// screen, and everything below it had nowhere to go. A test that never raises
/// the keyboard never sees it.
///
/// `viewInsets.bottom` is exactly what a real keyboard sets, so setting it here
/// reproduces the device condition rather than approximating it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Phone sizes, with a keyboard height typical of each.
  const Map<String, ({Size size, double keyboard})> phones =
      <String, ({Size size, double keyboard})>{
        'compact 320x568': (size: Size(320, 568), keyboard: 216),
        'phone 360x800': (size: Size(360, 800), keyboard: 300),
        'phone 375x812': (size: Size(375, 812), keyboard: 336),
        'phone 390x844': (size: Size(390, 844), keyboard: 346),
        'phone 412x915': (size: Size(412, 915), keyboard: 360),
      };

  Map<String, Object> seeded() {
    return <String, Object>{
      SettingsKeys.preferences: jsonEncode(
        const UserPreferences(hasCompletedOnboarding: true).toJson(),
      ),
    };
  }

  bool isLayoutError(String message) {
    return message.contains('overflowed') ||
        message.contains('RenderFlex') ||
        message.contains('RenderBox was not laid out') ||
        message.contains('unbounded') ||
        message.contains('infinite size');
  }

  Future<List<String>> collectErrors(Future<void> Function() body) async {
    final List<String> found = <String>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String full = details.toString();
      final RegExpMatch? source = RegExp(
        r'(lib[\\/][\w\\/.]+\.dart:\d+:\d+)',
      ).firstMatch(full);
      found.add(
        '${details.exceptionAsString()}'
        '${source == null ? '' : '  [${source.group(1)}]'}',
      );
    };
    try {
      await body();
    } finally {
      FlutterError.onError = previous;
    }
    return found;
  }

  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create(preferences: seeded());
  });
  tearDown(() => harness.dispose());

  /// Pumps the app at [size], opens the composer, then raises the keyboard.
  Future<List<String>> openComposer(
    WidgetTester tester,
    ({Size size, double keyboard}) device,
  ) async {
    tester.view.physicalSize = device.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return collectErrors(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: const KairoApp(),
        ),
      );
      harness.container.read(routerProvider).go(Routes.tasks);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The floating action button is how a phone user creates a task.
      final Finder fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget, reason: 'phones need a create affordance');
      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Autofocus on the title field raises the keyboard on a real device.
      // `viewInsets` is the same signal the framework delivers.
      tester.view.viewInsets = FakeViewPadding(
        bottom: device.keyboard * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  }

  group('task composer with the keyboard up', () {
    for (final MapEntry<String, ({Size size, double keyboard})> device
        in phones.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        final List<String> errors = await openComposer(tester, device.value);
        final List<String> failures = errors.where(isLayoutError).toList();

        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  });

  group('creating a task end to end on a phone', () {
    for (final MapEntry<String, ({Size size, double keyboard})> device
        in phones.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        List<Task> currentTasks() =>
            harness.container.read(tasksProvider).value ?? const <Task>[];

        final int before = currentTasks().length;

        final List<String> errors = await collectErrors(() async {
          await openComposer(tester, device.value);

          // Scoped to the composer: the task screen's own filter field is
          // still in the tree behind the sheet, and an unscoped finder types
          // into that instead — which silently leaves the title empty.
          await tester.enterText(
            find
                .descendant(
                  of: find.byType(TaskComposer),
                  matching: find.byType(TextField),
                )
                .first,
            'Ship the phone build',
          );
          await tester.pump();

          final Finder create = find.descendant(
            of: find.byType(TaskComposer),
            matching: find.widgetWithText(AppButton, 'New task'),
          );
          expect(create, findsOneWidget);
          await tester.tap(create);
          await tester.pump();
          // Past the persistence debounce, so the write actually lands.
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump(const Duration(milliseconds: 600));
        });

        expect(
          errors.where(isLayoutError),
          isEmpty,
          reason: '\n${errors.where(isLayoutError).join('\n')}',
        );

        final List<Task> after = currentTasks();
        expect(
          after.length,
          before + 1,
          reason: 'tapping "New task" should create exactly one task',
        );
        expect(
          after.any((Task t) => t.title == 'Ship the phone build'),
          isTrue,
        );

        // The undo toast owns a timer that would still be pending at teardown.
        harness.container.read(toastProvider.notifier).clear();
        await tester.pump();
      });
    }
  });

  /// Every other overlay a phone user can reach, opened through the UI rather
  /// than by calling into the code that shows it — a sheet that only works when
  /// summoned directly is not actually working.
  ///
  /// The composer's bug was a missing `Overlay` ancestor and an ignored
  /// keyboard; both are shared infrastructure, so every sheet is worth the
  /// same check.
  group('other overlays on a phone', () {
    /// Opens the app at [route], runs [open], then raises the keyboard.
    Future<List<String>> reach(
      WidgetTester tester,
      ({Size size, double keyboard}) device,
      String route,
      Future<void> Function(WidgetTester tester) open,
    ) {
      tester.view.physicalSize = device.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      return collectErrors(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: harness.container,
            child: const KairoApp(),
          ),
        );
        harness.container.read(routerProvider).go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await open(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        tester.view.viewInsets = FakeViewPadding(bottom: device.keyboard);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      });
    }

    Future<void> tapFirst(WidgetTester tester, Finder finder) async {
      expect(finder, findsWidgets);
      await tester.tap(finder.first, warnIfMissed: false);
    }

    final Map<String, (String, Future<void> Function(WidgetTester))> cases =
        <String, (String, Future<void> Function(WidgetTester))>{
          'command palette': (
            Routes.tasks,
            (WidgetTester tester) => tapFirst(tester, find.byTooltip('Search')),
          ),
          'task detail': (
            Routes.tasks,
            (WidgetTester tester) => tapFirst(tester, find.byType(TaskRow)),
          ),
          'filter sheet': (
            Routes.tasks,
            (WidgetTester tester) =>
                tapFirst(tester, find.widgetWithText(AppButton, 'Filter')),
          ),
          'project editor': (
            Routes.projects,
            (WidgetTester tester) =>
                tapFirst(tester, find.byTooltip('New project')),
          ),
          'more navigation sheet': (
            Routes.dashboard,
            (WidgetTester tester) => tapFirst(tester, find.byTooltip('More')),
          ),
        };

    for (final MapEntry<String, (String, Future<void> Function(WidgetTester))>
        overlay
        in cases.entries) {
      for (final MapEntry<String, ({Size size, double keyboard})> device
          in phones.entries) {
        testWidgets('${overlay.key} — ${device.key}', (
          WidgetTester tester,
        ) async {
          final List<String> errors = await reach(
            tester,
            device.value,
            overlay.value.$1,
            overlay.value.$2,
          );
          final List<String> failures = errors.where(isLayoutError).toList();

          expect(failures, isEmpty, reason: '\n${failures.join('\n')}');

          harness.container.read(toastProvider.notifier).clear();
          await tester.pump();
        });
      }
    }
  });

  group('the composer stays usable with the keyboard up', () {
    for (final MapEntry<String, ({Size size, double keyboard})> device
        in phones.entries) {
      testWidgets(device.key, (WidgetTester tester) async {
        await openComposer(tester, device.value);

        // The whole point of the sheet is the button at the bottom of it. If
        // the keyboard pushes it off-screen the form cannot be submitted, which
        // is a broken screen even when nothing reports an overflow.
        final Finder create = find.widgetWithText(AppButton, 'New task');
        expect(create, findsOneWidget);

        final Rect button = tester.getRect(create);
        final double visibleBottom =
            tester.view.physicalSize.height / tester.view.devicePixelRatio -
            device.value.keyboard;

        expect(
          button.bottom,
          lessThanOrEqualTo(visibleBottom + 0.5),
          reason:
              'the create button sits below the keyboard at ${device.key} '
              '(bottom ${button.bottom}, visible to $visibleBottom)',
        );
      });
    }
  });
}
