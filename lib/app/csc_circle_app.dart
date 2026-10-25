import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/preferences/app_preferences.dart';
import '../core/design/app_theme.dart';
import '../core/backend/public_content.dart';
import '../features/auth/auth_repository.dart';
import 'app_shell.dart';

class CscCircleApp extends StatefulWidget {
  const CscCircleApp({
    super.key,
    this.backendConfigured = false,
    this.authRepository,
    this.publicContentRepository,
    this.preferencesStore = const SharedPreferencesAppPreferencesStore(),
    this.initialPreferences,
  });

  final bool backendConfigured;
  final AuthRepository? authRepository;
  final PublicContentRepository? publicContentRepository;
  final AppPreferencesStore preferencesStore;
  final AppPreferencesSnapshot? initialPreferences;

  @override
  State<CscCircleApp> createState() => _CscCircleAppState();
}

class _CscCircleAppState extends State<CscCircleApp> {
  static const _preferenceLoadTimeout = Duration(seconds: 3);

  AppPreferencesSnapshot? _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
    if (_preferences == null) _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await widget.preferencesStore.load().timeout(
        _preferenceLoadTimeout,
        onTimeout: () =>
            const AppPreferencesSnapshot(onboardingComplete: false),
      );
      if (mounted) setState(() => _preferences = preferences);
    } on Object {
      // A storage plugin error should not strand the user on the launch view.
      if (mounted) {
        setState(
          () => _preferences = const AppPreferencesSnapshot(
            onboardingComplete: false,
          ),
        );
      }
    }
  }

  Future<void> _updatePreferences(AppPreferencesSnapshot next) async {
    if (!mounted) return;
    setState(() => _preferences = next);
    try {
      await widget.preferencesStore.save(next);
    } on Object {
      // Keep the in-memory setting for this session if local storage is absent.
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    return MaterialApp(
      title: 'CSC Circle',
      debugShowCheckedModeBanner: false,
      theme: buildCscTheme(),
      darkTheme: buildCscTheme(brightness: Brightness.dark),
      themeMode: preferences?.themeMode ?? ThemeMode.system,
      home: preferences == null
          ? const _AppStartingPage()
          : CscAppShell(
              backendConfigured: widget.backendConfigured,
              authRepository: widget.authRepository,
              publicContentRepository: widget.publicContentRepository,
              showOnboarding: !preferences.onboardingComplete,
              themeMode: preferences.themeMode,
              reduceMotion: preferences.reduceMotion,
              onOnboardingComplete: () => _updatePreferences(
                preferences.copyWith(onboardingComplete: true),
              ),
              onThemeModeChanged: (themeMode) => _updatePreferences(
                preferences.copyWith(themeMode: themeMode),
              ),
              onReduceMotionChanged: (reduceMotion) => _updatePreferences(
                preferences.copyWith(reduceMotion: reduceMotion),
              ),
            ),
    );
  }
}

class _AppStartingPage extends StatelessWidget {
  const _AppStartingPage();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'CSC Circle',
          image: true,
          child: Image.asset(
            'assets/brand/csc-icon.png',
            width: 92,
            height: 92,
            cacheWidth: 288,
            fit: BoxFit.contain,
          ),
        ),
      ),
      backgroundColor: palette.canvas,
    );
  }
}

/// Platform-aware navigation visuals shared by small Apple and Android
/// windows. Desktop layouts use a persistent rail instead of a phone tab bar.
Widget buildPhoneNavigation({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onDestinationSelected,
}) {
  final destinations = <_DestinationData>[
    _DestinationData('Home', Icons.home_outlined, Icons.home_rounded),
    _DestinationData('Events', Icons.event_outlined, Icons.event_rounded),
    _DestinationData('Discover', Icons.people_outline, Icons.people_rounded),
    _DestinationData(
      'Updates',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome,
    ),
    _DestinationData('Profile', Icons.person_outline, Icons.person_rounded),
  ];

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final palette = CscPalette.of(context);
    final highContrast = MediaQuery.highContrastOf(context);
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      activeColor: palette.ink,
      inactiveColor: palette.muted,
      backgroundColor: highContrast
          ? palette.surface
          : palette.surface.withAlpha(226),
      border: Border(top: BorderSide(color: palette.border)),
      items: destinations
          .map(
            (destination) => BottomNavigationBarItem(
              icon: Icon(destination.unselectedIcon),
              activeIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
          )
          .toList(),
    );
  }

  return NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    destinations: destinations
        .map(
          (destination) => NavigationDestination(
            icon: Icon(destination.unselectedIcon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
        )
        .toList(),
  );
}

class _DestinationData {
  const _DestinationData(this.label, this.unselectedIcon, this.selectedIcon);

  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
}
