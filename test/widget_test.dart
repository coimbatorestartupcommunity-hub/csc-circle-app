import 'package:csc_circle_app/app/csc_circle_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows CSC Circle home with phone navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CscCircleApp());

    expect(find.text('Great ideas grow\nin the right circle.'), findsOneWidget);
    expect(find.text('Explore CSC Circle'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switches to the founder directory from desktop navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1365, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CscCircleApp());
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Discover founders'), findsOneWidget);
    expect(find.text('Explore the directory'), findsOneWidget);
  });
}
