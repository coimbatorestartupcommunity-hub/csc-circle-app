import 'package:csc_circle_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the home screen and navigates to Discover', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Great ideas grow\nin the right circle.'), findsOneWidget);
    expect(find.text('Explore CSC Circle'), findsOneWidget);

    await tester.tap(find.text('Discover').first);
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Discover founders'), findsOneWidget);
    expect(find.text('Explore the directory'), findsOneWidget);
  });
}
