import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.reduceMotion,
    required this.onComplete,
  });

  final bool reduceMotion;
  final Future<void> Function() onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const _pages = <_WelcomePageData>[
    _WelcomePageData(
      eyebrow: 'COIMBATORE STARTUP COMMUNITY',
      title: 'Meet your startup community.',
      description: 'CSC Circle brings Coimbatore’s founders, builders, students, and professionals into one community.',
      icon: Icons.groups_rounded,
      tint: CscColors.purple,
    ),
    _WelcomePageData(
      eyebrow: 'CONNECT AND BUILD',
      title: 'Find people and ideas to move forward.',
      description: 'Explore founder profiles, discover community events, and find ways to learn and collaborate.',
      icon: Icons.lightbulb_outline_rounded,
      tint: CscColors.blue,
    ),
    _WelcomePageData(
      eyebrow: 'CONNECT. BUILD. GROW.',
      title: 'There’s room to grow together.',
      description: 'Keep up with community updates and take the next step in your startup journey, at your own pace.',
      icon: Icons.auto_awesome_rounded,
      tint: CscColors.pink,
    ),
  ];

  late final AnimationController _revealController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  int _currentPage = 0;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _logoOpacity = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0, 0.8, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );
  }

  bool get _prefersReducedMotion =>
      widget.reduceMotion || MediaQuery.disableAnimationsOf(context);

  void _applyMotionPreference() {
    if (_prefersReducedMotion) {
      _revealController.stop();
      _revealController.value = 1;
    } else if (_revealController.status == AnimationStatus.dismissed) {
      _revealController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPreference();
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _applyMotionPreference();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_completing) return;
    setState(() => _completing = true);
    await widget.onComplete();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _finish();
      return;
    }
    setState(() => _currentPage++);
  }

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    final page = _pages[_currentPage];
    final reduceMotion =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final compactHeight = MediaQuery.sizeOf(context).height < 720;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  CscSpacing.md,
                  compactHeight ? 4 : CscSpacing.sm,
                  CscSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Semantics(
                      label: 'CSC Circle logo',
                      image: true,
                      child: Image.asset(
                        'assets/brand/csc-icon.png',
                        width: 40,
                        height: 40,
                        cacheWidth: 128,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: CscSpacing.sm),
                    Expanded(
                      child: Text(
                        'CSC Circle',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _completing ? null : _finish,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    CscSpacing.md,
                    compactHeight ? CscSpacing.sm : CscSpacing.lg,
                    CscSpacing.md,
                    CscSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Container(
                                  width: compactHeight ? 112 : 136,
                                  height: compactHeight ? 112 : 136,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette.surface,
                                    border: Border.all(color: palette.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.accent.withAlpha(22),
                                        blurRadius: reduceMotion ? 0 : 32,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(13),
                                  child: Image.asset(
                                    'assets/brand/csc-icon.png',
                                    fit: BoxFit.contain,
                                    cacheWidth: 448,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compactHeight ? 20 : CscSpacing.xl),
                          AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              if (reduceMotion) return child;
                              final position = Tween<Offset>(
                                begin: const Offset(0.035, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: position,
                                  child: child,
                                ),
                              );
                            },
                            child: _PageCopy(
                              key: ValueKey(_currentPage),
                              page: page,
                              index: _currentPage,
                              total: _pages.length,
                              palette: palette,
                            ),
                          ),
                          const SizedBox(height: CscSpacing.lg),
                          _PageIndicator(
                            count: _pages.length,
                            selectedIndex: _currentPage,
                            reduceMotion: reduceMotion,
                          ),
                          SizedBox(height: compactHeight ? 18 : CscSpacing.xl),
                          if (_currentPage == 0)
                            Semantics(
                              label: 'Public preview. Member sign-in and live content are being connected.',
                              child: Container(
                                padding: const EdgeInsets.all(CscSpacing.sm),
                                decoration: BoxDecoration(
                                  color: palette.gold,
                                  borderRadius: BorderRadius.circular(
                                    CscRadius.control,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: palette.goldInk,
                                    ),
                                    const SizedBox(width: CscSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        'Public preview · Member sign-in and live content are being connected.',
                                        style: TextStyle(
                                          color: palette.goldInk,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: CscSpacing.md),
                          _PrimaryAction(
                            label: _currentPage == _pages.length - 1
                                ? 'Explore CSC Circle'
                                : 'Next',
                            isApple: isApple,
                            isBusy: _completing,
                            onPressed: _next,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageCopy extends StatelessWidget {
  const _PageCopy({
    super.key,
    required this.page,
    required this.index,
    required this.total,
    required this.palette,
  });

  final _WelcomePageData page;
  final int index;
  final int total;
  final CscPalette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? [palette.lavender, palette.blue, palette.pink][index]
        : page.tint;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(CscRadius.control),
          ),
          child: Icon(page.icon, color: palette.ink, size: 28),
        ),
        const SizedBox(height: CscSpacing.md),
        Text(
          page.eyebrow,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: CscSpacing.sm),
        Semantics(
          header: true,
          liveRegion: true,
          label: 'Welcome page ${index + 1} of $total. ${page.title}',
          child: ExcludeSemantics(
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: CscSpacing.sm),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: palette.secondary, height: 1.55),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.selectedIndex,
    required this.reduceMotion,
  });

  final int count;
  final int selectedIndex;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Semantics(
      label: 'Page ${selectedIndex + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (index) => AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == selectedIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == selectedIndex ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(CscRadius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.isApple,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isApple;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isApple) {
      final palette = CscPalette.of(context);
      return CupertinoButton.filled(
        onPressed: isBusy ? null : onPressed,
        borderRadius: BorderRadius.circular(CscRadius.control),
        color: palette.ink,
        disabledColor: palette.muted,
        padding: const EdgeInsets.symmetric(
          horizontal: CscSpacing.lg,
          vertical: 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: palette.inverseInk)),
            const SizedBox(width: CscSpacing.sm),
            Icon(Icons.arrow_forward_rounded, color: palette.inverseInk),
          ],
        ),
      );
    }
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: Text(label),
    );
  }
}

class _WelcomePageData {
  const _WelcomePageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color tint;
}
