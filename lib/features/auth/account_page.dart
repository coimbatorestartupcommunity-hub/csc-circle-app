import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/backend/member_data_repository.dart';
import '../member/member_dashboard_page.dart';
import 'auth_repository.dart';

enum _AuthMode { signIn, signUp, recovery, newPassword }

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.repository,
    required this.backendConfigured,
    this.memberDataRepository,
    this.allowMemberReads = false,
  });

  final AuthRepository? repository;
  final bool backendConfigured;
  final MemberDataRepository? memberDataRepository;

  /// Explicit test/approved-environment opt-in. The production app leaves it
  /// false until real positive and negative RLS verification is complete.
  final bool allowMemberReads;

  @override
  Widget build(BuildContext context) {
    if (!backendConfigured || repository == null) {
      return const _BackendPreview();
    }
    return _AuthFlow(
      repository: repository!,
      memberDataRepository: memberDataRepository,
      allowMemberReads: allowMemberReads,
    );
  }
}

class _AuthFlow extends StatefulWidget {
  const _AuthFlow({
    required this.repository,
    required this.memberDataRepository,
    required this.allowMemberReads,
  });
  final AuthRepository repository;
  final MemberDataRepository? memberDataRepository;
  final bool allowMemberReads;

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await widget.repository.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          _showMessage('You are signed in.');
        case _AuthMode.signUp:
          final result = await widget.repository.signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
          _showMessage(
            result == SignUpOutcome.emailConfirmationRequired
                ? 'Check your email for a CSC Circle confirmation link.'
                : 'Your CSC Circle account is ready.',
          );
        case _AuthMode.recovery:
          await widget.repository.sendPasswordRecovery(
            email: _emailController.text,
          );
          _showMessage('If an account matches, a recovery link is on its way.');
        case _AuthMode.newPassword:
          await widget.repository.updatePassword(
            password: _passwordController.text,
          );
          _passwordController.clear();
          _confirmController.clear();
          setState(() => _mode = _AuthMode.signIn);
          _showMessage('Your password has been updated.');
      }
    } on AuthUiException catch (error) {
      _showMessage(error.message, isError: true);
    } on Object {
      _showMessage(
        'CSC Circle could not complete that request. Try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _message = message;
        _messageIsError = isError;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.signOut();
    } on AuthUiException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return StreamBuilder<AuthSnapshot>(
      stream: widget.repository.changes,
      initialData: widget.repository.current,
      builder: (context, snapshot) {
        final auth = snapshot.data ?? widget.repository.current;
        if (auth.transition == AuthTransition.passwordRecovery) {
          _mode = _AuthMode.newPassword;
        }
        if (auth.isSignedIn && _mode != _AuthMode.newPassword) {
          return _signedIn(context, auth);
        }
        final expired = auth.transition == AuthTransition.sessionExpired;
        final needsRedirect =
            (_mode == _AuthMode.signUp || _mode == _AuthMode.recovery) &&
            !widget.repository.emailRedirectReady;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CscSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(CscSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 44,
                          color: palette.accent,
                        ),
                        const SizedBox(height: CscSpacing.md),
                        Text(
                          _mode == _AuthMode.signIn
                              ? 'Sign in to CSC Circle'
                              : _mode == _AuthMode.signUp
                              ? 'Create your CSC Circle account'
                              : _mode == _AuthMode.recovery
                              ? 'Reset your password'
                              : 'Choose a new password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: CscSpacing.xs),
                        Text(
                          'Use your existing CSC Circle account. Membership access is checked by CSC services.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.muted),
                        ),
                        if (expired) ...[
                          const SizedBox(height: CscSpacing.md),
                          const _InfoBanner(
                            text: 'Your session expired. Sign in again to continue.',
                            isError: false,
                          ),
                        ],
                        const SizedBox(height: CscSpacing.lg),
                        if (_mode != _AuthMode.newPassword)
                          TextFormField(
                            controller: _emailController,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: _mode == _AuthMode.recovery
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                        if (_mode == _AuthMode.signIn ||
                            _mode == _AuthMode.signUp ||
                            _mode == _AuthMode.newPassword) ...[
                          const SizedBox(height: CscSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_busy,
                            obscureText: _obscurePassword,
                            autofillHints: _mode == _AuthMode.signIn
                                ? const [AutofillHints.password]
                                : const [AutofillHints.newPassword],
                            textInputAction: _mode == _AuthMode.signIn
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: _mode == _AuthMode.newPassword
                                  ? 'New password'
                                  : 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Enter your password.';
                              }
                              if (_mode != _AuthMode.signIn &&
                                  password.length < 8) {
                                return 'Use at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_mode == _AuthMode.signUp ||
                            _mode == _AuthMode.newPassword) ...[
                          const SizedBox(height: CscSpacing.md),
                          TextFormField(
                            controller: _confirmController,
                            enabled: !_busy,
                            obscureText: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                ? 'Passwords do not match.'
                                : null,
                          ),
                        ],
                        if (needsRedirect) ...[
                          const SizedBox(height: CscSpacing.md),
                          const _InfoBanner(
                            text: 'Email confirmation and recovery links are paused until CSC approves and allowlists the native app redirect.',
                            isError: false,
                          ),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: CscSpacing.md),
                          _InfoBanner(
                            text: _message!,
                            isError: _messageIsError,
                          ),
                        ],
                        const SizedBox(height: CscSpacing.lg),
                        FilledButton(
                          onPressed: _busy || needsRedirect ? null : _submit,
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_submitLabel),
                        ),
                        const SizedBox(height: CscSpacing.xs),
                        if (_mode == _AuthMode.signIn) ...[
                          TextButton(
                            onPressed: () => setState(() {
                              _mode = _AuthMode.recovery;
                              _message = null;
                            }),
                            child: const Text('Forgot password?'),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _mode = _AuthMode.signUp;
                              _message = null;
                            }),
                            child: const Text('Create account'),
                          ),
                        ] else if (_mode != _AuthMode.newPassword)
                          TextButton(
                            onPressed: () => setState(() {
                              _mode = _AuthMode.signIn;
                              _message = null;
                            }),
                            child: const Text('Back to sign in'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String get _submitLabel => switch (_mode) {
    _AuthMode.signIn => 'Sign in',
    _AuthMode.signUp => 'Create account',
    _AuthMode.recovery => 'Send recovery link',
    _AuthMode.newPassword => 'Update password',
  };

  Widget _signedIn(BuildContext context, AuthSnapshot auth) =>
      MemberDashboardPage(
        key: ValueKey(auth.userId),
        auth: auth,
        actionMessage: _message,
        actionMessageIsError: _messageIsError,
        repository: widget.memberDataRepository,
        allowMemberReads: widget.allowMemberReads,
        onSignOut: _signOut,
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, required this.isError});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(CscSpacing.md),
      decoration: BoxDecoration(
        color: isError ? palette.pink : palette.gold,
        borderRadius: BorderRadius.circular(CscRadius.control),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? palette.ink : palette.goldInk,
          height: 1.45,
        ),
      ),
    );
  }
}

class _BackendPreview extends StatelessWidget {
  const _BackendPreview();

  @override
  Widget build(BuildContext context) {
    final palette = CscPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CscSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(CscSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 42,
                    color: palette.accent,
                  ),
                  const SizedBox(height: CscSpacing.md),
                  Text(
                    'CSC Circle public preview',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CscSpacing.sm),
                  const Text(
                    'Native sign-in and live community content are available when this build is configured with the existing CSC Supabase project.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CscSpacing.md),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final uri = Uri.parse(AppConfig.siteUrl)
                          .resolve('/login');
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open CSC Circle website'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
