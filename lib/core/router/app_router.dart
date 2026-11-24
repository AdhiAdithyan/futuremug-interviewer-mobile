import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/phone_auth_screen.dart';
import '../../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../../features/authentication/presentation/screens/create_account_screen.dart';
import '../../features/authentication/presentation/screens/sign_in_screen.dart';
import 'scaffold_with_navbar.dart';

final onboardingRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/phone-auth',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/phone-auth',
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '+91 98765 43210';
          return OtpVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final prefilledUsername = state.extra as String?;
          return SignInScreen(prefilledUsername: prefilledUsername);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainTabScaffold(),
      ),
    ],
  );
});
