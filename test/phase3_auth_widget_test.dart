import 'dart:async';

import 'package:csc_circle_app/features/auth/account_page.dart';
import 'package:csc_circle_app/features/auth/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign in and logout follow repository session transitions', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_authApp(repository));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'founder@example.test',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'correct horse battery',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(repository.lastEmail, 'founder@example.test');
    expect(repository.lastPassword, 'correct horse battery');
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.textContaining('stay paused'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCount, 1);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
  });

  testWidgets(
    'signup reports email confirmation without fabricating a session',
    (tester) async {
      final repository = _FakeAuthRepository();
      repository.signUpOutcome = SignUpOutcome.emailConfirmationRequired;
      await tester.pumpWidget(_authApp(repository));

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'secure passphrase',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'secure passphrase',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(repository.signUpCount, 1);
      expect(find.textContaining('Check your email'), findsOneWidget);
      expect(find.text('Signed in'), findsNothing);
    },
  );

  testWidgets('recovery uses the approved app redirect capability', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(emailRedirectReady: true);
    await tester.pumpWidget(_authApp(repository));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'founder@example.test',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send recovery link'));
    await tester.pumpAndSettle();

    expect(repository.recoveryCount, 1);
    expect(find.textContaining('If an account matches'), findsOneWidget);
  });

  testWidgets('signup and recovery remain gated until redirects are approved', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(emailRedirectReady: false);
    await tester.pumpWidget(_authApp(repository));

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('until CSC approves and allowlists'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Create account').first,
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create account').first,
          )
          .onPressed,
      isNull,
    );
    expect(repository.signUpCount, 0);
  });

  testWidgets('expired sessions return the user to sign in', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_authApp(repository));

    repository.emit(
      const AuthSnapshot(transition: AuthTransition.sessionExpired),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Your session expired'), findsOneWidget);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
  });

  testWidgets('password recovery deep link opens the new password form', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_authApp(repository));

    repository.emit(
      const AuthSnapshot(
        transition: AuthTransition.passwordRecovery,
        userId: 'fixture-user-id',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a new password'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'new secure passphrase',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'new secure passphrase',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Update password'));
    await tester.pumpAndSettle();

    expect(repository.updatePasswordCount, 1);
  });
}

Widget _authApp(_FakeAuthRepository repository) => MaterialApp(
  home: AccountPage(repository: repository, backendConfigured: true),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.emailRedirectReady = true});

  @override
  final bool emailRedirectReady;
  final StreamController<AuthSnapshot> _events =
      StreamController<AuthSnapshot>.broadcast(sync: true);

  AuthSnapshot _current = const AuthSnapshot(
    transition: AuthTransition.initial,
  );
  String? lastEmail;
  String? lastPassword;
  SignUpOutcome signUpOutcome = SignUpOutcome.signedIn;
  int signUpCount = 0;
  int recoveryCount = 0;
  int updatePasswordCount = 0;
  int signOutCount = 0;

  @override
  AuthSnapshot get current => _current;

  @override
  Stream<AuthSnapshot> get changes => _events.stream;

  void emit(AuthSnapshot snapshot) {
    _current = snapshot;
    _events.add(snapshot);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    emit(
      AuthSnapshot(
        transition: AuthTransition.signedIn,
        userId: 'fixture-user-id',
        email: email,
      ),
    );
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async {
    signUpCount++;
    lastEmail = email;
    lastPassword = password;
    if (signUpOutcome == SignUpOutcome.signedIn) {
      emit(
        AuthSnapshot(
          transition: AuthTransition.signedIn,
          userId: 'fixture-user-id',
          email: email,
        ),
      );
    }
    return signUpOutcome;
  }

  @override
  Future<void> sendPasswordRecovery({required String email}) async {
    recoveryCount++;
    lastEmail = email;
  }

  @override
  Future<void> updatePassword({required String password}) async {
    updatePasswordCount++;
    lastPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    emit(const AuthSnapshot(transition: AuthTransition.signedOut));
  }
}
