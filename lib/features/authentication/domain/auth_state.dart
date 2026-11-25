import 'package:futuremug_interviewer/features/authentication/domain/evaluator_user.dart';

/// Where the app stands on sign-in. The router redirects on every change.
sealed class AuthState {
  const AuthState();
}

/// Still reading the stored session at start-up (splash screen).
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.reason});

  /// Shown once on the login screen, e.g. "Your session has expired".
  final String? reason;
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final EvaluatorUser user;
}
