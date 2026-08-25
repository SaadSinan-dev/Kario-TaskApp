import 'package:flutter/foundation.dart';

enum Flavor { development, staging, production }

/// Compile-time configuration.
///
/// Values arrive through `--dart-define`, never through a checked-in file, so
/// no secret is ever committed. See `.env.example` for the full list and
/// `scripts/` in the README for the run commands.
///
/// Only *publishable* values belong here. Anything secret (payment secret keys,
/// database URLs, mail tokens) stays on a server.
@immutable
class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.apiBaseUrl,
    required this.useMockData,
    required this.mockLatency,
    required this.enableAnalytics,
    required this.stripePublishableKey,
  });

  final Flavor flavor;
  final String apiBaseUrl;

  /// When true the app runs entirely against the local repository stack. This
  /// is what powers the public demo and every test run.
  final bool useMockData;

  /// Artificial latency for the local data source. Keeps loading and skeleton
  /// states honest during development instead of never being seen.
  final Duration mockLatency;

  final bool enableAnalytics;
  final String stripePublishableKey;

  bool get isProduction => flavor == Flavor.production;
  bool get isDevelopment => flavor == Flavor.development;

  static const String _flavorName = String.fromEnvironment(
    'KAIRO_FLAVOR',
    defaultValue: 'development',
  );

  /// Resolved once at startup and injected through Riverpod, so tests can
  /// override it with a zero-latency configuration.
  static AppEnvironment resolve() {
    final Flavor flavor = switch (_flavorName) {
      'production' => Flavor.production,
      'staging' => Flavor.staging,
      _ => Flavor.development,
    };

    const int latencyMs = int.fromEnvironment(
      'KAIRO_MOCK_LATENCY_MS',
      defaultValue: 260,
    );

    return AppEnvironment(
      flavor: flavor,
      apiBaseUrl: const String.fromEnvironment(
        'KAIRO_API_BASE_URL',
        defaultValue: 'https://api.kairo.app/v1',
      ),
      useMockData: const bool.fromEnvironment(
        'KAIRO_USE_MOCK_DATA',
        defaultValue: true,
      ),
      mockLatency: const Duration(milliseconds: latencyMs),
      enableAnalytics:
          flavor == Flavor.production &&
          const bool.fromEnvironment('KAIRO_ENABLE_ANALYTICS'),
      stripePublishableKey: const String.fromEnvironment(
        'KAIRO_STRIPE_PUBLISHABLE_KEY',
      ),
    );
  }

  /// Deterministic configuration for widget and unit tests.
  static const AppEnvironment test = AppEnvironment(
    flavor: Flavor.development,
    apiBaseUrl: 'http://localhost/v1',
    useMockData: true,
    mockLatency: Duration.zero,
    enableAnalytics: false,
    stripePublishableKey: '',
  );
}
