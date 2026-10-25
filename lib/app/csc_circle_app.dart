import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import 'app_shell.dart';

class CscCircleApp extends StatelessWidget {
  const CscCircleApp({super.key, this.backendConfigured = false});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSC Circle',
      debugShowCheckedModeBanner: false,
      theme: buildCscTheme(),
      home: CscAppShell(backendConfigured: backendConfigured),
    );
  }
}

/// Platform-aware navigation visuals shared by small Apple and Android
/// windows. Desktop layouts use a persistent rail instead of a phone tab bar.
Widget buildPhoneNavigation({
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
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      activeColor: CscColors.ink,
      inactiveColor: CscColors.muted,
      backgroundColor: CscColors.white,
      border: const Border(top: BorderSide(color: CscColors.border)),
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
