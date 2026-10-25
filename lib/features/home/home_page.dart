import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/backend/public_content.dart';
import '../../core/config/app_config.dart';
import '../../core/design/app_theme.dart';
import '../sections/community_section_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final palette = CscPalette.of(context);
        final wide = constraints.maxWidth >= 900;
        final contentWidth = constraints.maxWidth >= 1200 ? 1120.0 : 1040.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 600 ? CscSpacing.md : CscSpacing.xl,
            CscSpacing.sm,
            constraints.maxWidth < 600 ? CscSpacing.md : CscSpacing.xl,
            CscSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!AppConfig.hasBackend) const _PublicPreviewNotice(),
                  if (!AppConfig.hasBackend)
                    const SizedBox(height: CscSpacing.md),
                  if (wide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _HeroCard()),
                        SizedBox(width: CscSpacing.md),
                        Expanded(flex: 4, child: _CommunityCard()),
                      ],
                    )
                  else ...[
                    const _HeroCard(),
                    const SizedBox(height: CscSpacing.md),
                    const _CommunityCard(),
                  ],
                  const SizedBox(height: CscSpacing.xl),
                  Text(
                    'Explore CSC Circle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: CscSpacing.xs),
                  Text(
                    'A few good places to start.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: CscSpacing.md),
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final columns = gridConstraints.maxWidth >= 720 ? 3 : 1;
                      return Wrap(
                        spacing: CscSpacing.md,
                        runSpacing: CscSpacing.md,
                        children: [
                          _QuickLinkCard(
                            width: _cardWidth(
                              gridConstraints.maxWidth,
                              columns,
                            ),
                            title: 'Find your next event',
                            subtitle: 'See dates, details, and registration.',
                            icon: Icons.event_available_rounded,
                            tint: palette.blue,
                            onTap: () => _selectSection(context, 1),
                          ),
                          _QuickLinkCard(
                            width: _cardWidth(
                              gridConstraints.maxWidth,
                              columns,
                            ),
                            title: 'Meet the community',
                            subtitle: 'Browse founders and startups.',
                            icon: Icons.groups_rounded,
                            tint: palette.lavender,
                            onTap: () => _selectSection(context, 2),
                          ),
                          _QuickLinkCard(
                            width: _cardWidth(
                              gridConstraints.maxWidth,
                              columns,
                            ),
                            title: 'Catch up on updates',
                            subtitle: 'Read the latest CSC stories.',
                            icon: Icons.auto_awesome_rounded,
                            tint: palette.pink,
                            onTap: () => _selectSection(context, 3),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: CscSpacing.xl),
                  const _OpportunitiesStrip(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _cardWidth(double width, int columns) {
    if (columns == 1) return width;
    return (width - CscSpacing.md * (columns - 1)) / columns;
  }

  void _selectSection(BuildContext context, int index) {
    CscNavigationScope.maybeOf(context)?.select(index);
  }
}

class _PublicPreviewNotice extends StatelessWidget {
  const _PublicPreviewNotice();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CscSpacing.md),
      decoration: BoxDecoration(
        color: palette.gold,
        borderRadius: BorderRadius.circular(CscRadius.control),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: palette.goldInk),
          const SizedBox(width: CscSpacing.sm),
          Expanded(
            child: Text(
              'Public preview · Member sign-in and live content are being connected.',
              style: TextStyle(
                color: palette.goldInk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.all(CscSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.lavender, palette.surface, palette.blue],
        ),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(CscRadius.card),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            bottom: -92,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withAlpha(30),
                    width: 28,
                  ),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Eyebrow('COIMBATORE STARTUP COMMUNITY'),
                const SizedBox(height: CscSpacing.md),
                Text(
                  'Great ideas grow\nin the right circle.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: CscSpacing.sm),
                Text(
                  'Connect. Build. Grow.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: CscSpacing.sm),
                Text(
                  'Meet founders, exchange ideas, and discover ways to move your startup journey forward.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: palette.secondary, height: 1.55),
                ),
                const SizedBox(height: CscSpacing.lg),
                Wrap(
                  spacing: CscSpacing.sm,
                  runSpacing: CscSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          CscNavigationScope.maybeOf(context)?.select(2),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Explore the community'),
                    ),
                    OutlinedButton(
                      onPressed: () => openCscWebsite(
                        context,
                        '/login?next=%2Fmember%2Fclaim',
                      ),
                      child: const Text('Join CSC Circle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.all(CscSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(CscRadius.card),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: palette.canvas,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(7),
            child: Image.asset(
              'assets/brand/csc-icon.png',
              fit: BoxFit.contain,
              cacheWidth: 256,
            ),
          ),
          const SizedBox(height: CscSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A circle for builders',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: CscSpacing.sm),
              Text(
                'CSC Circle brings Coimbatore’s founders, builders, creators, students, and professionals together.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.muted, height: 1.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(CscRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(CscSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(CscRadius.control),
                  ),
                  child: Icon(icon, color: palette.ink),
                ),
                const SizedBox(width: CscSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CscSpacing.xs),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunitiesStrip extends StatelessWidget {
  const _OpportunitiesStrip();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(CscSpacing.lg),
      decoration: BoxDecoration(
        color: palette.inverseSurface,
        borderRadius: BorderRadius.circular(CscRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources & opportunities',
            style: TextStyle(
              color: palette.inverseInk,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: CscSpacing.xs),
          Text(
            'Find useful guides and current ways to get involved.',
            style: TextStyle(
              color: palette.inverseInk.withAlpha(220),
              height: 1.5,
            ),
          ),
          const SizedBox(height: CscSpacing.md),
          Wrap(
            spacing: CscSpacing.sm,
            runSpacing: CscSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => CscNavigationScope.openContent(
                  context,
                  PublicContentKind.resources,
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Resources'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => CscNavigationScope.openContent(
                  context,
                  PublicContentKind.opportunities,
                ),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Opportunities'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Text(
      label,
      style: TextStyle(
        color: palette.accent,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}
