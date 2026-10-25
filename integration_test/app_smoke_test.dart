import 'package:csc_circle_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

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
