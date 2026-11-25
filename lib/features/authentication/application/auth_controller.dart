import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/logging/app_logger.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/data/auth_repository.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/authentication/domain/evaluator_user.dart';

/// Owns the signed-in session. Screens call [signIn] / [register] /
/// [signOut]; the router watches the state and redirects.
///
/// Methods throw [ApiException]s so screens can show the message.
class AuthController extends Notifier<AuthState> {
  Future<void>? _restoring;

  @override
  AuthState build() {
    final restoring = _restore();
    _restoring = restoring;
    unawaited(restoring);
    return const AuthUnknown();
  }

  /// Completes once the stored session has been read at start-up.
  Future<void> get ready => _restoring ?? Future<void>.value();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    try {
      final user = await _repository.restoreSession();
      if (state is! AuthUnknown) return; // Something already signed in/out.
      state = user == null ? const Unauthenticated() : Authenticated(user);
    } on Object catch (error, stackTrace) {
      AppLogger.error('Session restore failed', error, stackTrace);
      if (state is AuthUnknown) state = const Unauthenticated();
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    await ready; // Never let a late session restore overwrite this sign-in.
    final user = await _repository.login(
      username: username.trim(),
      password: password,
    );
    state = Authenticated(user);
  }

  Future<void> register({
    required String verificationToken,
    required String username,
    required String password,
  }) async {
    await ready;
    final user = await _repository.register(
      verificationToken: verificationToken,
      username: username.trim(),
      password: password,
    );
    state = Authenticated(user);
  }

  /// Saves changes to the signed-in user (e.g. profile completed, new name).
  Future<void> updateUser(EvaluatorUser updated) async {
    await _repository.updateStoredUser(updated);
    state = Authenticated(updated);
  }

  Future<void> signOut({String? reason}) async {
    try {
      await _repository.signOut();
      await ref.read(appDatabaseProvider).clearCache();
    } on Object catch (error, stackTrace) {
      // Never leave the user stuck signed in because cleanup failed.
      AppLogger.error('Sign-out cleanup failed', error, stackTrace);
    }
    ref.read(signUpFlowProvider.notifier).reset();
    state = Unauthenticated(reason: reason);
  }

  /// Called when any authenticated request returns 401.
  void onSessionExpired() {
    if (state is Authenticated) {
      unawaited(signOut(reason: 'Your session has expired. Please sign in again.'));
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
