import 'dart:async';
import 'dart:io';

import 'package:csc_circle_app/features/auth/account_page.dart';
import 'package:csc_circle_app/features/auth/auth_repository.dart';
import 'package:csc_circle_app/core/backend/member_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign in and logout follow repository session transitions', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final memberData = _FakeMemberDataRepository();
    await tester.pumpWidget(
      _authApp(repository, memberDataRepository: memberData),
    );

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
    expect(find.text('Member dashboard'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Membership'), findsOneWidget);
    expect(find.text('Startups'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Digital Member ID'), findsOneWidget);
    expect(memberData.readCount, 0);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCount, 1);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
  });

  testWidgets('failed sign in stays signed out and shows a safe error', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signInFailure = const AuthUiException(
        'Email or password is incorrect.',
      );
    await tester.pumpWidget(_authApp(repository));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'founder@example.test',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'wrong passphrase',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text('Member dashboard'), findsNothing);
  });

  testWidgets('failed logout keeps the session view and reports failure', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-signout-failure',
      ),
    )..signOutFailure = const AuthUiException('Sign out could not complete.');
    await tester.pumpWidget(_authApp(auth));

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCount, 1);
    expect(find.text('Member dashboard'), findsOneWidget);
    expect(find.text('Sign out could not complete.'), findsOneWidget);
    expect(find.text('Sign in to CSC Circle'), findsNothing);
  });

  testWidgets('fixture member repository renders all dashboard sections', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-1',
        email: 'member@example.test',
      ),
    );
    final memberData = _FakeMemberDataRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: auth,
          backendConfigured: true,
          memberDataRepository: memberData,
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riya Fixture'), findsOneWidget);
    expect(find.text('Status: active'), findsOneWidget);
    expect(find.text('Fixture Works'), findsOneWidget);
    expect(find.text('Fixture notification'), findsOneWidget);
    expect(find.text('CSC Circle  ·  •••• 4821'), findsOneWidget);
    expect(find.text('member-number-4821'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'CSC Circle member ID ending in 4821',
      ),
      findsOneWidget,
    );
    expect(memberData.readCount, 4);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Riya Fixture'), findsNothing);
    expect(find.text('Fixture Works'), findsNothing);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
  });

  testWidgets('dashboard shows empty member states without fabricated data', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-empty',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: auth,
          backendConfigured: true,
          memberDataRepository: _EmptyFakeMemberDataRepository(),
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your CSC profile is not available yet.'), findsOneWidget);
    expect(
      find.text('No membership record is available for this account.'),
      findsOneWidget,
    );
    expect(
      find.text('No startup profiles are linked to this account.'),
      findsOneWidget,
    );
    expect(
      find.text('There are no member notifications to show.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Available when CSC confirms an eligible membership and ID record.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dashboard gives an offline state and retries a failed section', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-offline',
      ),
    );
    final memberData = _FakeMemberDataRepository()..failNextStartup = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: auth,
          backendConfigured: true,
          memberDataRepository: memberData,
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('You appear to be offline. Check your connection and retry.'),
      findsOneWidget,
    );
    expect(find.text('Fixture Works'), findsNothing);

    final retry = find.widgetWithText(TextButton, 'Try again');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text('Fixture Works'), findsOneWidget);
    expect(
      find.text('You appear to be offline. Check your connection and retry.'),
      findsNothing,
    );
  });

  testWidgets('dashboard scrolls at compact width and large text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-large-text',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: auth,
          backendConfigured: true,
          memberDataRepository: _FakeMemberDataRepository(),
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member dashboard'), findsOneWidget);
    expect(find.text('Digital Member ID'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account switching reloads fixture data for the new session', (
    tester,
  ) async {
    final auth = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-1',
      ),
    );
    final memberData = _FakeMemberDataRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: auth,
          backendConfigured: true,
          memberDataRepository: memberData,
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Riya Fixture'), findsOneWidget);

    memberData.displayName = 'Second Fixture';
    auth.emit(
      const AuthSnapshot(
        transition: AuthTransition.signedIn,
        userId: 'fixture-owner-2',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Second Fixture'), findsOneWidget);
    expect(find.text('Riya Fixture'), findsNothing);
    expect(memberData.readCount, 8);
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

    final backButton = find.text('Back to sign in');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    final recoveryButton = find.text('Forgot password?');
    await tester.ensureVisible(recoveryButton);
    await tester.tap(recoveryButton);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(repository.recoveryCount, 0);
  });

  testWidgets('expired sessions clear member UI and return to sign in', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(
      initial: const AuthSnapshot(
        transition: AuthTransition.initial,
        userId: 'fixture-owner-1',
      ),
    );
    final memberData = _FakeMemberDataRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          repository: repository,
          backendConfigured: true,
          memberDataRepository: memberData,
          allowMemberReads: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Riya Fixture'), findsOneWidget);

    repository.emit(
      const AuthSnapshot(transition: AuthTransition.sessionExpired),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Your session expired'), findsOneWidget);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
    expect(find.text('Riya Fixture'), findsNothing);
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

Widget _authApp(
  _FakeAuthRepository repository, {
  MemberDataRepository? memberDataRepository,
}) => MaterialApp(
  home: AccountPage(
    repository: repository,
    backendConfigured: true,
    memberDataRepository: memberDataRepository,
  ),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.emailRedirectReady = true, AuthSnapshot? initial})
    : _current =
          initial ?? const AuthSnapshot(transition: AuthTransition.initial);

  @override
  final bool emailRedirectReady;
  final StreamController<AuthSnapshot> _events =
      StreamController<AuthSnapshot>.broadcast(sync: true);

  AuthSnapshot _current;
  String? lastEmail;
  String? lastPassword;
  AuthUiException? signInFailure;
  AuthUiException? signOutFailure;
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
    if (signInFailure case final failure?) throw failure;
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
    if (signOutFailure case final failure?) throw failure;
    emit(const AuthSnapshot(transition: AuthTransition.signedOut));
  }
}

class _FakeMemberDataRepository implements MemberDataRepository {
  String displayName = 'Riya Fixture';
  int readCount = 0;
  bool failNextStartup = false;
  bool _startupFailureUsed = false;

  @override
  Future<MemberProfile?> myProfile() async {
    readCount++;
    return MemberProfile(
      userId: 'fixture-owner',
      displayName: displayName,
      aboutMe: 'Fixture account only.',
      city: 'Coimbatore',
      profileCompletion: 80,
    );
  }

  @override
  Future<MemberMembership?> myMembership() async {
    readCount++;
    return MemberMembership(
      status: 'active',
      memberNumber: 'member-number-4821',
    );
  }

  @override
  Future<List<MemberStartup>> myStartups() async {
    readCount++;
    if (failNextStartup && !_startupFailureUsed) {
      _startupFailureUsed = true;
      throw const SocketException('fixture offline');
    }
    return [
      MemberStartup(
        id: 'fixture-startup-id',
        slug: 'fixture-works',
        name: 'Fixture Works',
        industry: 'education',
        status: 'published',
        updatedAt: DateTime.utc(2026, 10, 26),
      ),
    ];
  }

  @override
  Future<MemberNotificationInbox> myNotificationInbox() async {
    readCount++;
    return MemberNotificationInbox(
      unreadCount: 1,
      items: [
        MemberNotification(
          id: 'fixture-notification-id',
          title: 'Fixture notification',
          message: 'This message exists only in a widget fixture.',
          createdAt: DateTime.utc(2026, 10, 26),
        ),
      ],
    );
  }
}

class _EmptyFakeMemberDataRepository extends _FakeMemberDataRepository {
  @override
  Future<MemberProfile?> myProfile() async => null;

  @override
  Future<MemberMembership?> myMembership() async => null;

  @override
  Future<List<MemberStartup>> myStartups() async => [];

  @override
  Future<MemberNotificationInbox> myNotificationInbox() async =>
      const MemberNotificationInbox(items: [], unreadCount: 0);
}
