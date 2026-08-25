import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/bootstrap.dart';
import 'package:kairo/app/kairo_app.dart';
import 'package:kairo/app/providers.dart';

/// Entry point.
///
/// Startup work lives in `bootstrap()` so tests can build the same container
/// with different overrides and skip nothing.
Future<void> main() async {
  installErrorHandling();

  final ProviderContainer container = await bootstrap();

  WidgetsBinding.instance.addObserver(
    PersistenceLifecycleObserver(container.read(databaseProvider)),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const KairoApp()),
  );
}
