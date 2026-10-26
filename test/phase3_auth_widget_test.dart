import 'dart:async';

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
    expect(memberData.readCount, 4);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Riya Fixture'), findsNothing);
    expect(find.text('Fixture Works'), findsNothing);
    expect(find.text('Sign in to CSC Circle'), findsOneWidget);
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

class _FakeMemberDataRepository implements MemberDataRepository {
  String displayName = 'Riya Fixture';
  int readCount = 0;

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
