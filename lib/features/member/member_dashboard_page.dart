import 'package:flutter/material.dart';

import '../../core/backend/member_data_repository.dart';
import '../../core/design/app_theme.dart';
import '../auth/auth_repository.dart';

/// Signed-in member dashboard shell.
///
/// Member requests are opt-in so the shipped app remains fail-closed until
/// live owner and negative RLS checks are approved. Fixture repositories can
/// be injected by widget tests to exercise the complete dashboard UI.
class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({
    super.key,
    required this.auth,
    required this.onSignOut,
    this.repository,
    this.allowMemberReads = false,
  });

  final AuthSnapshot auth;
  final Future<void> Function() onSignOut;
  final MemberDataRepository? repository;
  final bool allowMemberReads;

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> {
  Future<MemberProfile?>? _profile;
  Future<MemberMembership?>? _membership;
  Future<List<MemberStartup>>? _startups;
  Future<MemberNotificationInbox>? _notifications;
  bool _signingOut = false;

  bool get _readsEnabled =>
      widget.allowMemberReads && widget.repository != null;

  @override
  void initState() {
    super.initState();
    _startReadsIfEnabled();
  }

  @override
  void didUpdateWidget(covariant MemberDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.userId != widget.auth.userId) {
      _clearUserState();
      _startReadsIfEnabled();
    } else if (oldWidget.allowMemberReads != widget.allowMemberReads ||
        oldWidget.repository != widget.repository) {
      _clearUserState();
      _startReadsIfEnabled();
    }
  }

  void _startReadsIfEnabled() {
    if (!_readsEnabled) return;
    final repository = widget.repository!;
    _profile = repository.myProfile();
    _membership = repository.myMembership();
    _startups = repository.myStartups();
    _notifications = repository.myNotificationInbox();
  }

  void _clearUserState() {
    _profile = null;
    _membership = null;
    _startups = null;
    _notifications = null;
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CscSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CscSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 42,
                        color: palette.accent,
                      ),
                      const SizedBox(height: CscSpacing.sm),
                      Text(
                        'Member dashboard',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (widget.auth.email case final email?) ...[
                        const SizedBox(height: CscSpacing.xs),
                        Text(email, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: CscSpacing.sm),
                      Text(
                        _readsEnabled
                            ? 'Your CSC Circle account sections are shown below.'
                            : 'Member records remain protected until CSC completes authorization testing.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: palette.muted),
                      ),
                      const SizedBox(height: CscSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _signingOut ? null : _signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CscSpacing.md),
              _profileSection(context),
              const SizedBox(height: CscSpacing.md),
              _membershipSection(context),
              const SizedBox(height: CscSpacing.md),
              _startupSection(context),
              const SizedBox(height: CscSpacing.md),
              _notificationSection(context),
              const SizedBox(height: CscSpacing.md),
              _digitalIdSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSection(BuildContext context) => _memberSection(
    context,
    title: 'Profile',
    icon: Icons.account_circle_outlined,
    future: _profile,
    retry: () => setState(() => _profile = widget.repository!.myProfile()),
    content: (profile) => profile == null
        ? const Text('Your CSC profile is not available yet.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName),
              if (profile.city case final city?) Text(city),
              Text('Profile completion: ${profile.profileCompletion}%'),
            ],
          ),
  );

  Widget _membershipSection(BuildContext context) => _memberSection(
    context,
    title: 'Membership',
    icon: Icons.badge_outlined,
    future: _membership,
    retry: () =>
        setState(() => _membership = widget.repository!.myMembership()),
    content: (membership) => membership == null
        ? const Text('No membership record is available for this account.')
        : Text('Status: ${membership.status}'),
  );

  Widget _startupSection(BuildContext context) => _memberSection(
    context,
    title: 'Startups',
    icon: Icons.rocket_launch_outlined,
    future: _startups,
    retry: () => setState(() => _startups = widget.repository!.myStartups()),
    content: (startups) => startups.isEmpty
        ? const Text('No startup profiles are linked to this account.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final startup in startups)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startup.name),
                  subtitle: Text('${startup.industry} · ${startup.status}'),
                ),
            ],
          ),
  );

  Widget _notificationSection(BuildContext context) => _memberSection(
    context,
    title: 'Notifications',
    icon: Icons.notifications_none_rounded,
    future: _notifications,
    retry: () => setState(
      () => _notifications = widget.repository!.myNotificationInbox(),
    ),
    content: (inbox) => inbox.items.isEmpty
        ? const Text('There are no member notifications to show.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${inbox.unreadCount} unread'),
              for (final notification in inbox.items.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                ),
            ],
          ),
  );

  Widget _digitalIdSection(BuildContext context) => _memberSection(
    context,
    title: 'Digital Member ID',
    icon: Icons.credit_card_outlined,
    future: _membership,
    retry: () =>
        setState(() => _membership = widget.repository!.myMembership()),
    content: (membership) {
      final number = membership?.memberNumber;
      final expiresAt = membership?.expiresAt;
      final expired = expiresAt != null && !expiresAt.isAfter(DateTime.now());
      if (membership == null ||
          membership.status.toLowerCase() != 'active' ||
          expired ||
          number == null ||
          number.isEmpty) {
        return const Text(
          'Available when CSC confirms an eligible membership and ID record.',
        );
      }
      final suffix = number.length <= 4
          ? number
          : number.substring(number.length - 4);
      return Semantics(
        label: 'CSC Circle member ID ending in $suffix',
        child: Text('CSC Circle  ·  •••• $suffix'),
      );
    },
  );

  Widget _memberSection<T>(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Future<T>? future,
    required Widget Function(T value) content,
    required VoidCallback retry,
  }) {
    final palette = CscPalette.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CscSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: palette.accent),
                const SizedBox(width: CscSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: CscSpacing.sm),
            if (!_readsEnabled)
              Text(
                'Paused until approved owner and cross-user access checks pass.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.muted),
              )
            else if (future == null)
              const LinearProgressIndicator()
            else
              FutureBuilder<T>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This section could not be loaded.'),
                        TextButton(
                          onPressed: retry,
                          child: const Text('Try again'),
                        ),
                      ],
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  return content(snapshot.data as T);
                },
              ),
          ],
        ),
      ),
    );
  }
}
