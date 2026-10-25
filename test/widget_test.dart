import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show SemanticsAction;

import 'package:csc_circle_app/app/csc_circle_app.dart';
import 'package:csc_circle_app/core/preferences/app_preferences.dart';
import 'package:csc_circle_app/features/onboarding/onboarding_page.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows CSC Circle home with phone navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());

    expect(find.text('Great ideas grow\nin the right circle.'), findsOneWidget);
    expect(find.text('Explore CSC Circle'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'first-run onboarding matches the phone golden',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const CscCircleApp(
          initialPreferences: AppPreferencesSnapshot(
            onboardingComplete: false,
            reduceMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/phase2_onboarding_phone.png'),
      );
    },
    // Golden pixels depend on host font rasterization; verify on macOS/Linux,
    // while Windows CI still runs the behavioral onboarding coverage below.
    skip: Platform.isWindows,
  );

  testWidgets(
    'desktop public home matches the wide golden',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_homeApp());
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/brand/csc-icon.png'),
          tester.element(find.byType(MaterialApp)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/phase2_desktop_home.png'),
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
    skip: Platform.isWindows,
  );

  testWidgets('iOS navigation uses a translucent Cupertino tab bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    final tabBar = tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    expect((tabBar.backgroundColor!.a * 255).round(), lessThan(255));
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('Android keeps the Material 3 navigation bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
  }, variant: TargetPlatformVariant({TargetPlatform.android}));

  testWidgets('macOS desktop navigation gets a restrained material blur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));

  testWidgets('iOS appearance uses a Cupertino action sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      CscCircleApp(
        preferencesStore: _MemoryPreferencesStore(),
        initialPreferences: const AppPreferencesSnapshot(
          onboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Appearance and motion settings'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);

    await tester.tap(find.text('Dark appearance'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('switches to the founder directory from desktop navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1365, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
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

    await tester.pumpWidget(_homeApp());

    const destinations = <(String, String, int)>[
      ('Events', 'Browse events', 1),
      ('Discover', 'Explore the directory', 2),
      ('Updates', 'Read updates', 3),
      ('Profile', 'CSC Circle public preview', 4),
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

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Explore CSC Circle'));
    await tester.pumpAndSettle();
    expect(find.text('Explore CSC Circle').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first launch explains CSC Circle and Skip persists completion', (
    tester,
  ) async {
    final preferences = _MemoryPreferencesStore();
    await tester.pumpWidget(
      CscCircleApp(
        preferencesStore: preferences,
        initialPreferences: const AppPreferencesSnapshot(
          onboardingComplete: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meet your startup community.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.text(
        'Public preview · Member sign-in and live content are being connected.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Welcome page 1 of 3. Meet your startup community.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Explore CSC Circle'), findsOneWidget);
    expect(preferences.snapshot.onboardingComplete, isTrue);
  });

  testWidgets('a stalled preferences read falls through to onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      CscCircleApp(preferencesStore: _StalledPreferencesStore()),
    );

    expect(find.text('Meet your startup community.'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Meet your startup community.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('first-run actions expose labels and tap semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const CscCircleApp(
        initialPreferences: AppPreferencesSnapshot(onboardingComplete: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.text('Skip'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.text('Next'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      find.bySemanticsLabel(
        'Welcome page 1 of 3. Meet your startup community.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('onboarding progresses and finishes on the last page', (
    tester,
  ) async {
    final preferences = _MemoryPreferencesStore();
    await tester.pumpWidget(
      CscCircleApp(
        preferencesStore: preferences,
        initialPreferences: const AppPreferencesSnapshot(
          onboardingComplete: false,
          reduceMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Find people and ideas to move forward.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('There’s room to grow together.'), findsOneWidget);
    expect(find.text('Explore CSC Circle'), findsOneWidget);

    await tester.tap(find.text('Explore CSC Circle').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore CSC Circle'), findsOneWidget);
    expect(preferences.snapshot.onboardingComplete, isTrue);
  });

  testWidgets('onboarding is scrollable at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      CscCircleApp(
        initialPreferences: const AppPreferencesSnapshot(
          onboardingComplete: false,
          reduceMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meet your startup community.'), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Next').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system reduced-motion setting disables the brand reveal', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      const CscCircleApp(
        initialPreferences: AppPreferencesSnapshot(onboardingComplete: false),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<ScaleTransition>(
            find
                .descendant(
                  of: find.byType(OnboardingPage),
                  matching: find.byType(ScaleTransition),
                )
                .first,
          )
          .scale
          .value,
      1,
    );
  });

  testWidgets('appearance menu switches to dark mode and reduced motion', (
    tester,
  ) async {
    final preferences = _MemoryPreferencesStore();
    await tester.pumpWidget(
      CscCircleApp(
        preferencesStore: preferences,
        initialPreferences: const AppPreferencesSnapshot(
          onboardingComplete: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Appearance and motion settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark appearance'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(preferences.snapshot.themeMode, ThemeMode.dark);

    await tester.tap(find.byTooltip('Appearance and motion settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(preferences.snapshot.reduceMotion, isTrue);
  });

  testWidgets('layout breakpoints remain free of rendering errors', (
    tester,
  ) async {
    final app = _homeApp();
    for (final width in <double>[
      320,
      360,
      375,
      390,
      430,
      600,
      768,
      820,
      840,
      1024,
      1280,
      1440,
      1920,
    ]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('desktop shortcuts change destinations and controls can focus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
    expect(find.text('Explore the directory').hitTestable(), findsOneWidget);
    expect(tester.binding.focusManager.primaryFocus, isNotNull);
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));
}

CscCircleApp _homeApp() => const CscCircleApp(
  initialPreferences: AppPreferencesSnapshot(onboardingComplete: true),
);

class _MemoryPreferencesStore implements AppPreferencesStore {
  AppPreferencesSnapshot snapshot = const AppPreferencesSnapshot(
    onboardingComplete: false,
  );

  @override
  Future<AppPreferencesSnapshot> load() async => snapshot;

  @override
  Future<void> save(AppPreferencesSnapshot next) async {
    snapshot = next;
  }
}

class _StalledPreferencesStore implements AppPreferencesStore {
  @override
  Future<AppPreferencesSnapshot> load() =>
      Completer<AppPreferencesSnapshot>().future;

  @override
  Future<void> save(AppPreferencesSnapshot snapshot) async {}
}
