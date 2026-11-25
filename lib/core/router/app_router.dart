import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/core/router/auth_redirect.dart';
import 'package:futuremug_interviewer/core/router/scaffold_with_navbar.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/create_account_screen.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/otp_verification_screen.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/phone_auth_screen.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/sign_in_screen.dart';
import 'package:futuremug_interviewer/features/authentication/presentation/screens/splash_screen.dart';
import 'package:futuremug_interviewer/features/calendar/presentation/screens/availability_calendar_screen.dart';
import 'package:futuremug_interviewer/features/dashboard/presentation/screens/dashboard_home_screen.dart';
import 'package:futuremug_interviewer/features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import 'package:futuremug_interviewer/features/interviews/presentation/screens/interview_schedules_screen.dart';
import 'package:futuremug_interviewer/features/profile/presentation/screens/edit_profile_screens.dart';
import 'package:futuremug_interviewer/features/profile/presentation/screens/profile_overview_screen.dart';
import 'package:futuremug_interviewer/features/profile/presentation/screens/profile_setup_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Re-runs the router's redirect whenever auth or sign-up state changes.
class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref
    ..listen(authControllerProvider, (_, __) => refresh.notify())
    ..listen(signUpFlowProvider, (_, __) => refresh.notify())
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signUp = ref.read(signUpFlowProvider);
      return resolveAuthRedirect(
        auth: ref.read(authControllerProvider),
        location: state.matchedLocation,
        hasOtpSession: signUp.hasOtpSession,
        isPhoneVerified: signUp.isPhoneVerified,
      );
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.splash),
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => SignInScreen(
          prefilledUsername: state.uri.queryParameters['username'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUpPhone,
        builder: (_, __) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUpOtp,
        builder: (_, __) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUpCredentials,
        builder: (_, __) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, __) => const DashboardHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.interviews,
                builder: (_, __) => const InterviewSchedulesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.availability,
                builder: (_, __) => const AvailabilityCalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.earnings,
                builder: (_, __) => const EarningsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileOverviewScreen(),
                routes: [
                  GoRoute(
                    path: 'personal',
                    builder: (_, __) => const EditPersonalDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'professional',
                    builder: (_, __) => const EditProfessionalDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'skills',
                    builder: (_, __) => const EditSkillsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
