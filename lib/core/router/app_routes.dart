/// Every route path in one place. Use these constants, never string literals.
abstract final class AppRoutes {
  static const String splash = '/splash';

  // Sign-up & sign-in (public)
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String signUpPhone = '/sign-up/phone';
  static const String signUpOtp = '/sign-up/otp';
  static const String signUpCredentials = '/sign-up/credentials';

  // Signed in, profile not complete yet
  static const String profileSetup = '/profile-setup';

  // Main tabs
  static const String dashboard = '/dashboard';
  static const String interviews = '/interviews';
  static const String availability = '/availability';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String profilePersonal = '/profile/personal';
  static const String profileProfessional = '/profile/professional';
  static const String profileSkills = '/profile/skills';

  static const Set<String> public = {
    login,
    forgotPassword,
    signUpPhone,
    signUpOtp,
    signUpCredentials,
  };
}
