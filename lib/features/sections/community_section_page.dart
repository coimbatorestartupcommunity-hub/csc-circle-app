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
  Widget build(BuildContext context) => SingleChildScrollView(
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
                color: CscColors.white,
                border: Border.all(color: CscColors.border),
                borderRadius: BorderRadius.circular(CscRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(CscRadius.control),
                    ),
                    child: Icon(icon, size: 28, color: CscColors.ink),
                  ),
                  const SizedBox(height: CscSpacing.xl),
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: CscColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: CscSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: CscSpacing.sm),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: CscColors.secondary, height: 1.6),
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
                    const Icon(Icons.shield_outlined, color: CscColors.muted),
                    const SizedBox(width: CscSpacing.sm),
                    Expanded(
                      child: Text(
                        detail,
                        style: const TextStyle(
                          color: CscColors.secondary,
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

class _SignInStatusNote extends StatelessWidget {
  const _SignInStatusNote();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(CscSpacing.md),
    decoration: BoxDecoration(
      color: CscColors.gold,
      borderRadius: BorderRadius.circular(CscRadius.control),
    ),
    child: const Text(
      'Member sign-in in this early app build opens the existing CSC Circle website. Native sign-in is being connected to the same account system.',
      style: TextStyle(color: CscColors.ink, height: 1.5),
    ),
  );
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
