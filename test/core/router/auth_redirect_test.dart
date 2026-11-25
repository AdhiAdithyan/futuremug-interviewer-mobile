import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/core/router/auth_redirect.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/authentication/domain/evaluator_user.dart';

void main() {
  const completeUser = EvaluatorUser(
    interviewerId: 'EV-1',
    fullName: 'Alex Morgan',
    isOnboardingComplete: true,
  );
  const newUser = EvaluatorUser(
    interviewerId: 'EV-2',
    fullName: '',
    isOnboardingComplete: false,
  );

  String? redirect(
    AuthState auth,
    String location, {
    bool hasOtpSession = false,
    bool isPhoneVerified = false,
  }) =>
      resolveAuthRedirect(
        auth: auth,
        location: location,
        hasOtpSession: hasOtpSession,
        isPhoneVerified: isPhoneVerified,
      );

  group('while the session is loading', () {
    test('everything shows the splash screen', () {
      expect(redirect(const AuthUnknown(), AppRoutes.dashboard), AppRoutes.splash);
      expect(redirect(const AuthUnknown(), AppRoutes.login), AppRoutes.splash);
      expect(redirect(const AuthUnknown(), AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    const auth = Unauthenticated();

    test('protected routes go to login', () {
      expect(redirect(auth, AppRoutes.dashboard), AppRoutes.login);
      expect(redirect(auth, AppRoutes.profile), AppRoutes.login);
      expect(redirect(auth, AppRoutes.profileSetup), AppRoutes.login);
      expect(redirect(auth, AppRoutes.splash), AppRoutes.login);
    });

    test('public routes are allowed', () {
      expect(redirect(auth, AppRoutes.login), isNull);
      expect(redirect(auth, AppRoutes.forgotPassword), isNull);
      expect(redirect(auth, AppRoutes.signUpPhone), isNull);
    });

    test('OTP step needs an OTP session', () {
      expect(redirect(auth, AppRoutes.signUpOtp), AppRoutes.signUpPhone);
      expect(redirect(auth, AppRoutes.signUpOtp, hasOtpSession: true), isNull);
    });

    test('credentials step needs a verified phone', () {
      expect(
        redirect(auth, AppRoutes.signUpCredentials),
        AppRoutes.signUpPhone,
      );
      expect(
        redirect(auth, AppRoutes.signUpCredentials, hasOtpSession: true),
        AppRoutes.signUpOtp,
      );
      expect(
        redirect(
          auth,
          AppRoutes.signUpCredentials,
          hasOtpSession: true,
          isPhoneVerified: true,
        ),
        isNull,
      );
    });

    test('query strings are ignored when matching', () {
      expect(redirect(auth, '${AppRoutes.login}?username=alex'), isNull);
    });
  });

  group('signed in without a profile', () {
    const auth = Authenticated(newUser);

    test('everything goes to profile setup', () {
      expect(redirect(auth, AppRoutes.dashboard), AppRoutes.profileSetup);
      expect(redirect(auth, AppRoutes.login), AppRoutes.profileSetup);
      expect(redirect(auth, AppRoutes.profileSetup), isNull);
    });
  });

  group('signed in with a profile', () {
    const auth = Authenticated(completeUser);

    test('entry screens go to the dashboard', () {
      expect(redirect(auth, AppRoutes.login), AppRoutes.dashboard);
      expect(redirect(auth, AppRoutes.splash), AppRoutes.dashboard);
      expect(redirect(auth, AppRoutes.signUpPhone), AppRoutes.dashboard);
      expect(redirect(auth, AppRoutes.profileSetup), AppRoutes.dashboard);
      expect(redirect(auth, '/'), AppRoutes.dashboard);
    });

    test('app screens are allowed', () {
      expect(redirect(auth, AppRoutes.dashboard), isNull);
      expect(redirect(auth, AppRoutes.interviews), isNull);
      expect(redirect(auth, AppRoutes.profile), isNull);
    });
  });
}
