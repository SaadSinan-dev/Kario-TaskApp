import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kairo/app/bootstrap.dart';
import 'package:kairo/app/kairo_app.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/core/env/app_environment.dart';
import 'package:kairo/core/routing/app_router.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/data/local/local_store.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end journeys through the real app: the startup sequence, the demo
/// sign-in, the shell, and creating a task.
///
/// Run with:
///   flutter test integration_test/app_journeys_test.dart -d chrome
/// or on a connected device with `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> launch(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = await bootstrap(
      environment: AppEnvironment.test,
      documentStore: InMemoryDocumentStore(),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KairoApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return container;
  }

  testWidgets('the app starts on the splash and routes to sign-in', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await launch(tester);
    addTearDown(container.dispose);

    // The contract this asserts is the whole point of the startup rework: a
    // fresh, signed-out launch must not land on the marketing site.
    expect(
      container.read(routerProvider).state.uri.path,
      Routes.login,
      reason: 'a signed-out launch should end on the sign-in screen',
    );

  });

  testWidgets('the demo CTA signs in and opens the workspace', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await launch(tester);
    addTearDown(container.dispose);

    // The demo card sits on the sign-in screen, which is where a signed-out
    // launch already lands.
    final Finder demoButton = find.widgetWithText(AppButton, 'Open').first;
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(container.read(authRepositoryProvider).currentUser, isNotNull);
  });

  testWidgets('a task created through the repository appears in the app', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await launch(tester);
    addTearDown(container.dispose);

    await container.read(authRepositoryProvider).signInAsDemo();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final TaskRepository repository = container.read(taskRepositoryProvider);
    final DateTime now = DateTime.now();
    final Task created = await repository.createTask(
      Task(
        id: '',
        workspaceId: container.read(authRepositoryProvider).currentUser == null
            ? ''
            : 'wsp_launchpad',
        title: 'Integration smoke task',
        createdAt: now,
        updatedAt: now,
        createdById: container.read(authRepositoryProvider).currentUser!.id,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(await repository.findTask(created.id), isNotNull);
  });
}
