import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesSnapshot {
  const AppPreferencesSnapshot({
    required this.onboardingComplete,
    this.themeMode = ThemeMode.system,
    this.reduceMotion = false,
  });

  final bool onboardingComplete;
  final ThemeMode themeMode;
  final bool reduceMotion;

  AppPreferencesSnapshot copyWith({
    bool? onboardingComplete,
    ThemeMode? themeMode,
    bool? reduceMotion,
  }) => AppPreferencesSnapshot(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    themeMode: themeMode ?? this.themeMode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );
}

abstract interface class AppPreferencesStore {
  Future<AppPreferencesSnapshot> load();
  Future<void> save(AppPreferencesSnapshot snapshot);
}

class SharedPreferencesAppPreferencesStore implements AppPreferencesStore {
  const SharedPreferencesAppPreferencesStore();

  static const _onboardingKey = 'csc_onboarding_complete';
  static const _themeModeKey = 'csc_theme_mode';
  static const _reduceMotionKey = 'csc_reduce_motion';

  @override
  Future<AppPreferencesSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeModeName = preferences.getString(_themeModeKey);
    return AppPreferencesSnapshot(
      onboardingComplete: preferences.getBool(_onboardingKey) ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeName,
        orElse: () => ThemeMode.system,
      ),
      reduceMotion: preferences.getBool(_reduceMotionKey) ?? false,
    );
  }

  @override
  Future<void> save(AppPreferencesSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_onboardingKey, snapshot.onboardingComplete),
      preferences.setString(_themeModeKey, snapshot.themeMode.name),
      preferences.setBool(_reduceMotionKey, snapshot.reduceMotion),
    ]);
  }
}
