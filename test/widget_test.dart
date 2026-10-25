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

    expect(find.text('Discover founders').hitTestable(), findsOneWidget);
    expect(find.text('Explore the directory').hitTestable(), findsOneWidget);
  });

  testWidgets('all five phone destinations show their matching page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CscCircleApp());

    const destinations = <(String, String, int)>[
      ('Events', 'Browse events', 1),
      ('Discover', 'Explore the directory', 2),
      ('Updates', 'Read updates', 3),
      ('Profile', 'Continue to sign in', 4),
      ('Home', 'Explore CSC Circle', 0),
    ];

    for (final (label, pageAction, selectedIndex) in destinations) {
      await tester.tap(find.text(label).hitTestable().last);
      await tester.pumpAndSettle();

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, selectedIndex, reason: label);
      await tester.ensureVisible(find.text(pageAction).last);
      await tester.pumpAndSettle();
      expect(
        find.text(pageAction).hitTestable(),
        findsOneWidget,
        reason: '$label destination should expose its page action',
      );
    }
  });

  testWidgets('compact 320px layout remains usable at 2x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const CscCircleApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Explore CSC Circle'));
    await tester.pumpAndSettle();
    expect(find.text('Explore CSC Circle').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
