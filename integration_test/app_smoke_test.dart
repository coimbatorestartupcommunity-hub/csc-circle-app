import 'package:csc_circle_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:csc_circle_app/core/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the home screen and navigates to Discover', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await app.main();
    await tester.pumpAndSettle();

    expect(find.text('Meet your startup community.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Great ideas grow\nin the right circle.'), findsOneWidget);
    expect(find.text('Explore CSC Circle'), findsOneWidget);
    expect(preferences.getBool('csc_onboarding_complete'), isTrue);

    await tester.tap(find.text('Discover').first);
    await tester.pumpAndSettle();

    expect(find.text('Discover founders'), findsOneWidget);
    expect(find.text('Explore the directory'), findsOneWidget);

    if (AppConfig.hasBackend) {
      await _openAndVerifyPublicContent(
        tester,
        destination: 'Events',
        pageTitle: 'CSC Circle events',
        emptyMessage:
            'There are no published CSC Circle events to show right now.',
      );
      await _openAndVerifyPublicContent(
        tester,
        destination: 'Updates',
        pageTitle: 'Community updates',
        emptyMessage:
            'There are no published Community updates to show right now.',
      );

      await tester.tap(find.text('Home').first);
      await tester.pumpAndSettle();
      final resourcesAction = find.text('Resources').first;
      await tester.ensureVisible(resourcesAction);
      await tester.tap(resourcesAction);
      await tester.pumpAndSettle();
      await _expectPublicFailure(
        tester,
        pageTitle: 'Community resources',
        message: 'This content is not available right now.',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      final opportunitiesAction = find.text('Opportunities').first;
      await tester.ensureVisible(opportunitiesAction);
      await tester.tap(opportunitiesAction);
      await tester.pumpAndSettle();
      await _expectPublicResponse(
        tester,
        pageTitle: 'Current opportunities',
        emptyMessage:
            'There are no published Current opportunities to show right now.',
      );
    }

    await preferences.reload();
    expect(preferences.getBool('csc_onboarding_complete'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Great ideas grow\nin the right circle.'), findsOneWidget);
  });
}

Future<void> _openAndVerifyPublicContent(
  WidgetTester tester, {
  required String destination,
  required String pageTitle,
  required String emptyMessage,
}) async {
  await tester.tap(find.text(destination).first);
  await tester.pumpAndSettle();
  await _expectPublicResponse(
    tester,
    pageTitle: pageTitle,
    emptyMessage: emptyMessage,
  );
}

Future<void> _expectPublicResponse(
  WidgetTester tester, {
  required String pageTitle,
  required String emptyMessage,
}) async {
  expect(find.text(pageTitle), findsOneWidget);
  await tester.pumpAndSettle();
  expect(find.text('Try again'), findsNothing);
  expect(find.text(emptyMessage), findsOneWidget);
}

Future<void> _expectPublicFailure(
  WidgetTester tester, {
  required String pageTitle,
  required String message,
}) async {
  expect(find.text(pageTitle), findsOneWidget);
  await tester.pumpAndSettle();
  expect(find.text(message), findsOneWidget);
  expect(find.text('Try again'), findsOneWidget);
}
