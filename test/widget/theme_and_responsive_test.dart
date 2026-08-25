import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_theme.dart';
import 'package:kairo/core/theme/kairo_colors.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';

import '../support/test_harness.dart';

/// Theming, breakpoints and the reduce-motion contract.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create();
  });

  tearDown(() => harness.dispose());

  group('theme', () {
    test('light and dark are distinct palettes, not an inversion', () {
      final KairoColors light = KairoColors.light();
      final KairoColors dark = KairoColors.dark();

      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);

      // Dark surfaces are navy, not pure grey: blue channel above red.
      expect(dark.canvas.b, greaterThan(dark.canvas.r));
      expect(dark.surface.b, greaterThan(dark.surface.r));

      // The brand stays recognisably the same hue in both themes.
      expect((light.brand.b - dark.brand.b).abs(), lessThan(0.2));
    });

    test('both themes carry the KairoColors extension', () {
      expect(AppTheme.light().extension<KairoColors>(), isNotNull);
      expect(AppTheme.dark().extension<KairoColors>(), isNotNull);
      expect(AppTheme.light().extension<KairoColors>()!.isDark, isFalse);
      expect(AppTheme.dark().extension<KairoColors>()!.isDark, isTrue);
    });

    test('lerp produces a valid intermediate palette', () {
      final KairoColors mid = KairoColors.light().lerp(KairoColors.dark(), 0.5);
      expect(mid.chartSeries.length, KairoColors.light().chartSeries.length);
    });

    test('switching the preference updates the app theme mode', () async {
      final PreferencesController controller = harness.container.read(
        preferencesProvider.notifier,
      );

      expect(
        harness.container.read(preferencesProvider).theme,
        ThemePreference.system,
      );

      await controller.update(
        (UserPreferences p) => p.copyWith(theme: ThemePreference.dark),
      );
      expect(
        harness.container.read(preferencesProvider).theme,
        ThemePreference.dark,
      );

      await controller.update(
        (UserPreferences p) => p.copyWith(theme: ThemePreference.light),
      );
      expect(
        harness.container.read(preferencesProvider).theme,
        ThemePreference.light,
      );
    });

    test('preferences survive a reload from storage', () async {
      await harness.container
          .read(preferencesProvider.notifier)
          .update(
            (UserPreferences p) => p.copyWith(
              theme: ThemePreference.dark,
              reduceMotion: true,
              weekStartsOn: DateTime.sunday,
            ),
          );

      final UserPreferences saved = harness.container.read(preferencesProvider);
      final UserPreferences restored = UserPreferences.fromJson(saved.toJson());

      expect(restored.theme, ThemePreference.dark);
      expect(restored.reduceMotion, isTrue);
      expect(restored.weekStartsOn, DateTime.sunday);
    });
  });

  group('breakpoints', () {
    test('map widths to the intended layout', () {
      expect(Breakpoints.of(390), ScreenSize.compact);
      expect(Breakpoints.of(760), ScreenSize.medium);
      expect(Breakpoints.of(1100), ScreenSize.expanded);
      expect(Breakpoints.of(1600), ScreenSize.large);
    });

    test('capability getters follow the layout, not the device', () {
      expect(ScreenSize.compact.hasSidebar, isFalse);
      expect(ScreenSize.compact.isTouchFirst, isTrue);
      expect(ScreenSize.medium.hasSidebar, isFalse);
      expect(ScreenSize.expanded.hasSidebar, isTrue);
      expect(ScreenSize.expanded.hasDetailPanel, isFalse);
      expect(ScreenSize.large.hasDetailPanel, isTrue);
    });

    test('responsiveValue falls back to the nearest smaller value', () {
      expect(responsiveValue<String>(ScreenSize.large, compact: 'c'), 'c');
      expect(
        responsiveValue<String>(ScreenSize.large, compact: 'c', expanded: 'e'),
        'e',
      );
    });

    testWidgets('ResponsiveBuilder reports the bucket for its constraints', (
      WidgetTester tester,
    ) async {
      final List<ScreenSize> observed = <ScreenSize>[];

      await tester.pumpWidget(
        wrapForTest(
          Row(
            children: <Widget>[
              SizedBox(
                width: 400,
                child: ResponsiveBuilder(
                  builder: (BuildContext context, ScreenSize size) {
                    observed.add(size);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              SizedBox(
                width: 1400,
                child: ResponsiveBuilder(
                  builder: (BuildContext context, ScreenSize size) {
                    observed.add(size);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          container: harness.container,
        ),
      );
      await tester.pump();

      expect(observed, contains(ScreenSize.compact));
      expect(observed, contains(ScreenSize.large));
    });
  });

  group('reduced motion', () {
    testWidgets('collapses durations to zero when the scope asks for it', (
      WidgetTester tester,
    ) async {
      late Duration reduced;
      late Duration normal;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              MotionScope(
                reduceMotion: true,
                child: Builder(
                  builder: (BuildContext context) {
                    reduced = context.motion(const Duration(seconds: 1));
                    return const SizedBox.shrink();
                  },
                ),
              ),
              MotionScope(
                reduceMotion: false,
                child: Builder(
                  builder: (BuildContext context) {
                    normal = context.motion(const Duration(seconds: 1));
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(reduced, Duration.zero);
      expect(normal, const Duration(seconds: 1));
    });

    testWidgets('the platform setting alone is enough to reduce motion', (
      WidgetTester tester,
    ) async {
      late bool reduced;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MotionScope(
              reduceMotion: false,
              child: Builder(
                builder: (BuildContext context) {
                  reduced = context.reducedMotion;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(reduced, isTrue);
    });
  });
}
