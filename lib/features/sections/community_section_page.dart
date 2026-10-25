import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/design/app_theme.dart';

class CommunitySectionPage extends StatelessWidget {
  const CommunitySectionPage({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.icon,
    required this.tint,
    required this.websitePath,
    required this.actionLabel,
    required this.detail,
    this.showSignInNote = false,
  });

  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;
  final Color tint;
  final String websitePath;
  final String actionLabel;
  final String detail;
  final bool showSignInNote;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    final resolvedTint = Theme.of(context).brightness == Brightness.dark
        ? Color.alphaBlend(tint.withAlpha(54), palette.surface)
        : tint;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CscSpacing.md,
        CscSpacing.md,
        CscSpacing.md,
        CscSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CscSpacing.xl),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(CscRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: resolvedTint,
                        borderRadius: BorderRadius.circular(CscRadius.control),
                      ),
                      child: Icon(icon, size: 28, color: palette.ink),
                    ),
                    const SizedBox(height: CscSpacing.xl),
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: CscSpacing.sm),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: CscSpacing.sm),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: palette.secondary, height: 1.6),
                    ),
                    const SizedBox(height: CscSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => openCscWebsite(context, websitePath),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(actionLabel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CscSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CscSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: palette.muted),
                      const SizedBox(width: CscSpacing.sm),
                      Expanded(
                        child: Text(
                          detail,
                          style: TextStyle(
                            color: palette.secondary,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showSignInNote) ...[
                const SizedBox(height: CscSpacing.md),
                const _SignInStatusNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInStatusNote extends StatelessWidget {
  const _SignInStatusNote();

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
      child: Text(
        'Member sign-in in this early app build opens the existing CSC Circle website. Native sign-in is being connected to the same account system.',
        style: TextStyle(color: palette.goldInk, height: 1.5),
      ),
    );
  }
}

Future<void> openCscWebsite(BuildContext context, String path) async {
  final uri = Uri.parse(AppConfig.siteUrl).resolve(path);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The CSC Circle website could not be opened.'),
      ),
    );
  }
}
