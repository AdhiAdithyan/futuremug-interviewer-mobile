import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';

/// Decides where a navigation to [location] should go, or `null` to allow it.
/// Pure function so every rule is unit-tested (see `auth_redirect_test.dart`).
///
/// Rules:
/// 1. While the stored session is being read, show the splash screen.
/// 2. Signed out: only public routes; everything else goes to login.
///    The OTP and credentials steps need the earlier step to be done.
/// 3. Signed in without a complete profile: only the profile setup.
/// 4. Signed in with a profile: never show public routes, splash or setup.
String? resolveAuthRedirect({
  required AuthState auth,
  required String location,
  required bool hasOtpSession,
  required bool isPhoneVerified,
}) {
  final path = Uri.parse(location).path;

  switch (auth) {
    case AuthUnknown():
      return path == AppRoutes.splash ? null : AppRoutes.splash;

    case Unauthenticated():
      if (path == AppRoutes.signUpOtp && !hasOtpSession) {
        return AppRoutes.signUpPhone;
      }
      if (path == AppRoutes.signUpCredentials && !isPhoneVerified) {
        return hasOtpSession ? AppRoutes.signUpOtp : AppRoutes.signUpPhone;
      }
      return AppRoutes.public.contains(path) ? null : AppRoutes.login;

    case Authenticated(:final user):
      if (!user.isOnboardingComplete) {
        return path == AppRoutes.profileSetup ? null : AppRoutes.profileSetup;
      }
      final isEntryRoute = AppRoutes.public.contains(path) ||
          path == AppRoutes.splash ||
          path == AppRoutes.profileSetup ||
          path == '/';
      return isEntryRoute ? AppRoutes.dashboard : null;
  }
}
