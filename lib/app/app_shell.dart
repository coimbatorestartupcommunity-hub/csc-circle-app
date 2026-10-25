import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/app_theme.dart';
import '../core/backend/public_content.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/home/home_page.dart';
import '../features/content/public_content_page.dart';
import '../features/auth/account_page.dart';
import '../features/auth/auth_repository.dart';
import '../features/sections/community_section_page.dart';
import 'csc_circle_app.dart';

class CscAppShell extends StatefulWidget {
  const CscAppShell({
    super.key,
    required this.backendConfigured,
    this.authRepository,
    this.publicContentRepository,
    required this.showOnboarding,
    required this.themeMode,
    required this.reduceMotion,
    required this.onOnboardingComplete,
    required this.onThemeModeChanged,
    required this.onReduceMotionChanged,
  });

  final bool backendConfigured;
  final AuthRepository? authRepository;
  final PublicContentRepository? publicContentRepository;
  final bool showOnboarding;
  final ThemeMode themeMode;
  final bool reduceMotion;
  final Future<void> Function() onOnboardingComplete;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  State<CscAppShell> createState() => _CscAppShellState();
}

class _CscAppShellState extends State<CscAppShell> {
  static const _destinations = <_AppDestination>[
    _AppDestination('Home', Icons.home_outlined, Icons.home_rounded),
    _AppDestination('Events', Icons.event_outlined, Icons.event_rounded),
    _AppDestination('Discover', Icons.people_outline, Icons.people_rounded),
    _AppDestination('Updates', Icons.auto_awesome_outlined, Icons.auto_awesome),
    _AppDestination('Profile', Icons.person_outline, Icons.person_rounded),
  ];

  late final List<Widget> _pages = [
    const HomePage(),
    widget.publicContentRepository == null
        ? const CommunitySectionPage(
            title: 'Events',
            eyebrow: 'MEET, LEARN, BUILD',
            description: 'Explore current CSC Circle events, booking information, and member registration details.',
            icon: Icons.event_available_rounded,
            tint: CscColors.blue,
            websitePath: '/events',
            actionLabel: 'Browse events',
            detail:
                'Live event content is not configured in this preview build.',
          )
        : PublicContentPage(
            kind: PublicContentKind.events,
            repository: widget.publicContentRepository!,
          ),
    const CommunitySectionPage(
      title: 'Discover founders',
      eyebrow: 'PEOPLE AND STARTUPS',
      description: 'Find public founder and startup profiles shared by the CSC Circle community.',
      icon: Icons.people_alt_rounded,
      tint: CscColors.purple,
      websitePath: '/directory',
      actionLabel: 'Explore the directory',
      detail: 'Profiles appear according to each member’s current publication and visibility choices.',
    ),
    widget.publicContentRepository == null
        ? const CommunitySectionPage(
            title: 'Community updates',
            eyebrow: 'WHAT’S HAPPENING',
            description: 'Read published community news, event highlights, collaborations, and milestones.',
            icon: Icons.auto_awesome_rounded,
            tint: CscColors.pink,
            websitePath: '/updates',
            actionLabel: 'Read updates',
            detail: 'Live community updates are not configured in this preview build.',
          )
        : PublicContentPage(
            kind: PublicContentKind.updates,
            repository: widget.publicContentRepository!,
          ),
    AccountPage(
      repository: widget.authRepository,
      backendConfigured: widget.backendConfigured,
    ),
  ];

  int _selectedIndex = 0;
  static const _desktopShortcuts = <LogicalKeyboardKey>[
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
  ];

  void _selectDestination(int index) {
    if (index < 0 || index >= _destinations.length) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOnboarding) {
      return OnboardingPage(
        reduceMotion: widget.reduceMotion,
        onComplete: widget.onOnboardingComplete,
      );
    }
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        for (var index = 0; index < _destinations.length; index++)
          SingleActivator(
            _desktopShortcuts[index],
            control: defaultTargetPlatform != TargetPlatform.macOS,
            meta: defaultTargetPlatform == TargetPlatform.macOS,
          ): _SelectDestinationIntent(
            index,
          ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SelectDestinationIntent: CallbackAction<_SelectDestinationIntent>(
            onInvoke: (intent) {
              _selectDestination(intent.index);
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 840) {
                  return _buildDesktopLayout(constraints.maxWidth >= 1120);
                }
                if (constraints.maxWidth >= 600) {
                  return _buildTabletLayout();
                }
                return _buildPhoneLayout();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: CscPalette.of(context).canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PhoneHeader(
              backendConfigured: widget.backendConfigured,
              themeMode: widget.themeMode,
              reduceMotion: widget.reduceMotion,
              onThemeModeChanged: widget.onThemeModeChanged,
              onReduceMotionChanged: widget.onReduceMotionChanged,
            ),
            Expanded(child: _currentPage),
          ],
        ),
      ),
      bottomNavigationBar: buildPhoneNavigation(
        context: context,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _platformRail(
              context,
              extended: false,
              child: NavigationRail(
                backgroundColor: defaultTargetPlatform == TargetPlatform.macOS
                    ? Colors.transparent
                    : CscPalette.of(context).surface,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.72,
                leading: const Padding(
                  padding: EdgeInsets.only(bottom: CscSpacing.lg),
                  child: _CompactMark(),
                ),
                destinations: _railDestinations,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  _WideHeader(
                    backendConfigured: widget.backendConfigured,
                    themeMode: widget.themeMode,
                    reduceMotion: widget.reduceMotion,
                    onThemeModeChanged: widget.onThemeModeChanged,
                    onReduceMotionChanged: widget.onReduceMotionChanged,
                  ),
                  Expanded(child: _currentPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool extended) {
    final palette = CscPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _platformRail(
              context,
              extended: extended,
              child: NavigationRail(
                backgroundColor: defaultTargetPlatform == TargetPlatform.macOS
                    ? Colors.transparent
                    : palette.surface,
                extended: extended,
                minExtendedWidth: 232,
                minWidth: 88,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                labelType: extended ? null : NavigationRailLabelType.all,
                groupAlignment: -0.72,
                leading: Padding(
                  padding: EdgeInsets.only(
                    left: extended ? CscSpacing.lg : 0,
                    right: extended ? CscSpacing.lg : 0,
                    bottom: CscSpacing.xl,
                  ),
                  child: extended ? const _Wordmark() : const _CompactMark(),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: CscSpacing.lg),
                  child: Text(
                    'Connect. Build. Grow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
                destinations: _railDestinations,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  _WideHeader(
                    backendConfigured: widget.backendConfigured,
                    themeMode: widget.themeMode,
                    reduceMotion: widget.reduceMotion,
                    onThemeModeChanged: widget.onThemeModeChanged,
                    onReduceMotionChanged: widget.onReduceMotionChanged,
                  ),
                  Expanded(child: _currentPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NavigationRailDestination> get _railDestinations => _destinations
      .map(
        (destination) => NavigationRailDestination(
          icon: Icon(destination.icon),
          selectedIcon: Icon(destination.selectedIcon),
          label: Text(destination.label),
        ),
      )
      .toList();

  Widget get _currentPage => CscNavigationScope(
    select: _selectDestination,
    openPublicContent: _openPublicContent,
    child: IndexedStack(index: _selectedIndex, children: _pages),
  );

  void _openPublicContent(PublicContentKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicContentPage(
          kind: kind,
          repository: widget.publicContentRepository,
        ),
      ),
    );
  }
}

class CscNavigationScope extends InheritedWidget {
  const CscNavigationScope({
    super.key,
    required this.select,
    required this.openPublicContent,
    required super.child,
  });

  final ValueChanged<int> select;
  final ValueChanged<PublicContentKind> openPublicContent;

  static CscNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CscNavigationScope>();

  static void openContent(BuildContext context, PublicContentKind kind) =>
      maybeOf(context)?.openPublicContent(kind);

  @override
  bool updateShouldNotify(CscNavigationScope oldWidget) =>
      select != oldWidget.select ||
      openPublicContent != oldWidget.openPublicContent;
}

Widget _platformRail(
  BuildContext context, {
  required bool extended,
  required Widget child,
}) {
  if (defaultTargetPlatform != TargetPlatform.macOS) return child;
  final palette = CscPalette.of(context);
  final highContrast = MediaQuery.highContrastOf(context);
  return SizedBox(
    width: extended ? 232 : 88,
    child: ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: highContrast ? 0 : 18,
          sigmaY: highContrast ? 0 : 18,
        ),
        child: ColoredBox(
          color: highContrast
              ? palette.surface
              : palette.surface.withAlpha(226),
          child: child,
        ),
      ),
    ),
  );
}

class _PhoneHeader extends StatelessWidget {
  const _PhoneHeader({
    required this.backendConfigured,
    required this.themeMode,
    required this.reduceMotion,
    required this.onThemeModeChanged,
    required this.onReduceMotionChanged,
  });

  final bool backendConfigured;
  final ThemeMode themeMode;
  final bool reduceMotion;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CscSpacing.md, 8, CscSpacing.md, 12),
      child: Row(
        children: [
          const _CompactMark(),
          const SizedBox(width: 10),
          const Expanded(child: _Wordmark()),
          _AppearanceControl(
            themeMode: themeMode,
            reduceMotion: reduceMotion,
            onThemeModeChanged: onThemeModeChanged,
            onReduceMotionChanged: onReduceMotionChanged,
          ),
          if (isCupertino)
            CupertinoButton(
              color: palette.lavender,
              borderRadius: BorderRadius.circular(CscRadius.control),
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              onPressed: () => _openWebsite(context, '/login'),
              child: Icon(
                backendConfigured ? Icons.person_outline : Icons.login_rounded,
                size: 20,
                color: palette.ink,
                semanticLabel: backendConfigured ? 'Member profile' : 'Sign in',
              ),
            )
          else
            IconButton.filledTonal(
              tooltip: backendConfigured ? 'Member profile' : 'Sign in',
              onPressed: () => _openWebsite(context, '/login'),
              icon: Icon(
                backendConfigured ? Icons.person_outline : Icons.login_rounded,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.backendConfigured,
    required this.themeMode,
    required this.reduceMotion,
    required this.onThemeModeChanged,
    required this.onReduceMotionChanged,
  });

  final bool backendConfigured;
  final ThemeMode themeMode;
  final bool reduceMotion;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? CscSpacing.md : CscSpacing.xl,
            12,
            compact ? CscSpacing.md : CscSpacing.xl,
            10,
          ),
          child: Row(
            children: [
              Text(
                compact ? 'CSC Circle' : 'Coimbatore Startup Community',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _AppearanceControl(
                themeMode: themeMode,
                reduceMotion: reduceMotion,
                onThemeModeChanged: onThemeModeChanged,
                onReduceMotionChanged: onReduceMotionChanged,
              ),
              const SizedBox(width: CscSpacing.xs),
              if (compact)
                IconButton.filledTonal(
                  tooltip: backendConfigured ? 'Member profile' : 'Sign in',
                  onPressed: () => _openWebsite(context, '/login'),
                  icon: Icon(
                    backendConfigured ? Icons.person_outline : Icons.login,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _openWebsite(context, '/login'),
                  icon: Icon(
                    backendConfigured ? Icons.person_outline : Icons.login,
                  ),
                  label: Text(backendConfigured ? 'Member login' : 'Sign in'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactMark extends StatelessWidget {
  const _CompactMark();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.asset(
      'assets/brand/csc-icon.png',
      width: 44,
      height: 44,
      cacheWidth: 144,
      fit: BoxFit.cover,
      semanticLabel: 'CSC Circle logo',
    ),
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSC Circle',
          style: TextStyle(
            color: palette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        Text(
          'CONNECT. BUILD. GROW.',
          style: TextStyle(
            color: palette.muted,
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum _AppearanceAction { system, light, dark, toggleReduceMotion }

class _AppearanceControl extends StatelessWidget {
  const _AppearanceControl({
    required this.themeMode,
    required this.reduceMotion,
    required this.onThemeModeChanged,
    required this.onReduceMotionChanged,
  });

  final ThemeMode themeMode;
  final bool reduceMotion;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  void _select(_AppearanceAction action) {
    switch (action) {
      case _AppearanceAction.system:
        onThemeModeChanged(ThemeMode.system);
      case _AppearanceAction.light:
        onThemeModeChanged(ThemeMode.light);
      case _AppearanceAction.dark:
        onThemeModeChanged(ThemeMode.dark);
      case _AppearanceAction.toggleReduceMotion:
        onReduceMotionChanged(!reduceMotion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS;
    if (isCupertino) {
      return Tooltip(
        message: 'Appearance and motion settings',
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          borderRadius: BorderRadius.circular(CscRadius.control),
          onPressed: () => showCupertinoModalPopup<void>(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: const Text('Appearance'),
              actions: [
                _cupertinoAction(
                  context,
                  _AppearanceAction.system,
                  'Use device setting',
                ),
                _cupertinoAction(
                  context,
                  _AppearanceAction.light,
                  'Light appearance',
                ),
                _cupertinoAction(
                  context,
                  _AppearanceAction.dark,
                  'Dark appearance',
                ),
                _cupertinoAction(
                  context,
                  _AppearanceAction.toggleReduceMotion,
                  reduceMotion ? 'Turn off reduced motion' : 'Reduce motion',
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.lavender,
              borderRadius: BorderRadius.circular(CscRadius.control),
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.tune_rounded,
                color: palette.ink,
                semanticLabel: 'Appearance and motion settings',
              ),
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<_AppearanceAction>(
      tooltip: 'Appearance and motion settings',
      onSelected: _select,
      itemBuilder: (context) => [
        _appearanceItem(
          _AppearanceAction.system,
          'Use device setting',
          palette,
        ),
        _appearanceItem(_AppearanceAction.light, 'Light appearance', palette),
        _appearanceItem(_AppearanceAction.dark, 'Dark appearance', palette),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AppearanceAction.toggleReduceMotion,
          child: Row(
            children: [
              Icon(
                reduceMotion ? Icons.check_box : Icons.check_box_outline_blank,
                color: palette.muted,
                size: 20,
              ),
              const SizedBox(width: CscSpacing.sm),
              const Flexible(child: Text('Reduce motion')),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.tune_rounded),
    );
  }

  CupertinoActionSheetAction _cupertinoAction(
    BuildContext context,
    _AppearanceAction action,
    String label,
  ) => CupertinoActionSheetAction(
    isDefaultAction: switch (action) {
      _AppearanceAction.system => themeMode == ThemeMode.system,
      _AppearanceAction.light => themeMode == ThemeMode.light,
      _AppearanceAction.dark => themeMode == ThemeMode.dark,
      _AppearanceAction.toggleReduceMotion => reduceMotion,
    },
    onPressed: () {
      Navigator.pop(context);
      _select(action);
    },
    child: Text(label),
  );

  PopupMenuItem<_AppearanceAction> _appearanceItem(
    _AppearanceAction action,
    String label,
    CscPalette palette,
  ) {
    final selected = switch (action) {
      _AppearanceAction.system => themeMode == ThemeMode.system,
      _AppearanceAction.light => themeMode == ThemeMode.light,
      _AppearanceAction.dark => themeMode == ThemeMode.dark,
      _AppearanceAction.toggleReduceMotion => false,
    };
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? palette.accent : palette.secondary,
            size: 20,
          ),
          const SizedBox(width: CscSpacing.sm),
          Flexible(child: Text(label, softWrap: true)),
        ],
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _SelectDestinationIntent extends Intent {
  const _SelectDestinationIntent(this.index);

  final int index;
}

Future<void> _openWebsite(BuildContext context, String path) async {
  try {
    await openCscWebsite(context, path);
  } on Exception {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The CSC Circle website could not be opened.'),
      ),
    );
  }
}
