import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/app_theme.dart';
import '../features/home/home_page.dart';
import '../features/sections/community_section_page.dart';
import 'csc_circle_app.dart';

class CscAppShell extends StatefulWidget {
  const CscAppShell({super.key, required this.backendConfigured});

  final bool backendConfigured;

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
    const CommunitySectionPage(
      title: 'Events',
      eyebrow: 'MEET, LEARN, BUILD',
      description: 'Explore current CSC Circle events, booking information, and member registration details.',
      icon: Icons.event_available_rounded,
      tint: CscColors.blue,
      websitePath: '/events',
      actionLabel: 'Browse events',
      detail: 'Event availability and registration eligibility come from the CSC Circle platform.',
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
    const CommunitySectionPage(
      title: 'Community updates',
      eyebrow: 'WHAT’S HAPPENING',
      description: 'Read published community news, event highlights, collaborations, and milestones.',
      icon: Icons.auto_awesome_rounded,
      tint: CscColors.pink,
      websitePath: '/updates',
      actionLabel: 'Read updates',
      detail: 'Only updates published by CSC are visible to the community.',
    ),
    CommunitySectionPage(
      title: 'Your CSC Circle',
      eyebrow: 'MEMBER SPACE',
      description: 'Sign in to manage your profile, membership details, event registrations, and preferences.',
      icon: Icons.account_circle_rounded,
      tint: CscColors.gold,
      websitePath: '/login',
      actionLabel: 'Continue to sign in',
      detail: 'Native account access is being connected to the existing CSC Circle identity.',
      showSignInNote: true,
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
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        for (var index = 0; index < _destinations.length; index++)
          SingleActivator(_desktopShortcuts[index], control: true):
              _SelectDestinationIntent(index),
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
    );
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: CscColors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PhoneHeader(backendConfigured: widget.backendConfigured),
            Expanded(child: _currentPage),
          ],
        ),
      ),
      bottomNavigationBar: buildPhoneNavigation(
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
            NavigationRail(
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
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  _WideHeader(backendConfigured: widget.backendConfigured),
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
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
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
              trailing: const Padding(
                padding: EdgeInsets.only(bottom: CscSpacing.lg),
                child: Text(
                  'Connect. Build. Grow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CscColors.muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
              destinations: _railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  _WideHeader(backendConfigured: widget.backendConfigured),
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
    child: IndexedStack(index: _selectedIndex, children: _pages),
  );
}

class CscNavigationScope extends InheritedWidget {
  const CscNavigationScope({
    super.key,
    required this.select,
    required super.child,
  });

  final ValueChanged<int> select;

  static CscNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CscNavigationScope>();

  @override
  bool updateShouldNotify(CscNavigationScope oldWidget) =>
      select != oldWidget.select;
}

class _PhoneHeader extends StatelessWidget {
  const _PhoneHeader({required this.backendConfigured});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CscSpacing.md, 8, CscSpacing.md, 12),
      child: Row(
        children: [
          const _CompactMark(),
          const SizedBox(width: 10),
          const Expanded(child: _Wordmark()),
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
  const _WideHeader({required this.backendConfigured});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(CscSpacing.xl, 14, CscSpacing.xl, 10),
      child: Row(
        children: [
          Text(
            'Coimbatore Startup Community',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: CscColors.muted, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _openWebsite(context, '/login'),
            icon: Icon(backendConfigured ? Icons.person_outline : Icons.login),
            label: Text(backendConfigured ? 'Member login' : 'Sign in'),
          ),
        ],
      ),
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
      fit: BoxFit.cover,
      semanticLabel: 'CSC Circle logo',
    ),
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'CSC Circle',
        style: TextStyle(
          color: CscColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      Text(
        'CONNECT. BUILD. GROW.',
        style: TextStyle(
          color: CscColors.muted,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
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
