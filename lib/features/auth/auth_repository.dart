import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthTransition {
  initial,
  signedIn,
  tokenRefreshed,
  signedOut,
  sessionExpired,
  passwordRecovery,
}

class AuthSnapshot {
  const AuthSnapshot({required this.transition, this.userId, this.email});

  final AuthTransition transition;
  final String? userId;
  final String? email;

  bool get isSignedIn => userId != null;
}

enum SignUpOutcome { signedIn, emailConfirmationRequired }

abstract interface class AuthRepository {
  AuthSnapshot get current;
  Stream<AuthSnapshot> get changes;
  bool get emailRedirectReady;
  Future<void> signIn({required String email, required String password});
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  });
  Future<void> sendPasswordRecovery({required String email});
  Future<void> updatePassword({required String password});
  Future<void> signOut();
}

class AuthUiException implements Exception {
  const AuthUiException(this.message);
  final String message;
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this._client,
    required this.emailRedirectUri,
  });

  final SupabaseClient _client;
  final Uri? emailRedirectUri;
  late final Stream<AuthSnapshot> _changes = _client.auth.onAuthStateChange.map(
    (state) {
      final transition = switch (state.event) {
        AuthChangeEvent.initialSession => AuthTransition.initial,
        AuthChangeEvent.signedIn ||
        AuthChangeEvent.userUpdated => AuthTransition.signedIn,
        AuthChangeEvent.tokenRefreshed => AuthTransition.tokenRefreshed,
        AuthChangeEvent.signedOut =>
          state.signOutReason == SignOutReason.sessionExpired
              ? AuthTransition.sessionExpired
              : AuthTransition.signedOut,
        AuthChangeEvent.passwordRecovery => AuthTransition.passwordRecovery,
        _ =>
          state.session == null
              ? AuthTransition.signedOut
              : AuthTransition.tokenRefreshed,
      };
      return _snapshot(transition, state.session?.user);
    },
  );

  @override
  bool get emailRedirectReady => emailRedirectUri != null;

  @override
  AuthSnapshot get current =>
      _snapshot(AuthTransition.initial, _client.auth.currentSession?.user);

  @override
  Stream<AuthSnapshot> get changes => _changes;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async {
    final redirect = emailRedirectUri;
    if (redirect == null) {
      throw const AuthUiException(
        'Account creation is unavailable until CSC approves the app email redirect.',
      );
    }
    return _guard(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: redirect.toString(),
      );
      return response.session == null
          ? SignUpOutcome.emailConfirmationRequired
          : SignUpOutcome.signedIn;
    });
  }

  @override
  Future<void> sendPasswordRecovery({required String email}) async {
    final redirect = emailRedirectUri;
    if (redirect == null) {
      throw const AuthUiException(
        'Password recovery is unavailable until CSC approves the app email redirect.',
      );
    }
    await _guard(
      () => _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirect.toString(),
      ),
    );
  }

  @override
  Future<void> updatePassword({required String password}) async {
    await _guard(
      () => _client.auth.updateUser(UserAttributes(password: password)),
    );
  }

  @override
  Future<void> signOut() async {
    await _guard(() => _client.auth.signOut());
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthUiException {
      rethrow;
    } on AuthApiException catch (error) {
      final message = switch (error.code) {
        'invalid_credentials' => 'Email or password is incorrect.',
        'email_address_invalid' => 'Enter a valid email address.',
        'weak_password' => 'Choose a stronger password.',
        'user_already_exists' => 'An account already exists for this email.',
        _ => 'CSC Circle could not complete that request. Try again.',
      };
      throw AuthUiException(message);
    } on AuthRetryableFetchException {
      throw const AuthUiException(
        'CSC Circle is unreachable. Check your connection and try again.',
      );
    } on SocketException {
      throw const AuthUiException(
        'CSC Circle is unreachable. Check your connection and try again.',
      );
    } on TimeoutException {
      throw const AuthUiException(
        'CSC Circle is unreachable. Check your connection and try again.',
      );
    } on Object {
      throw const AuthUiException(
        'CSC Circle could not complete that request. Try again.',
      );
    }
  }

  AuthSnapshot _snapshot(AuthTransition transition, User? user) => AuthSnapshot(
    transition: transition,
    userId: user?.id,
    email: user?.email,
  );
}
