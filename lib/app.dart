import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/config/app_config.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/router/app_router.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_app_theme.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';

/// Overrides every root `ProviderScope` needs (the app and widget tests).
List<Override> appRootOverrides({required AppDatabase database}) => [
      appDatabaseProvider.overrideWithValue(database),
      // A 401 on any authenticated call signs the user out.
      sessionExpiredCallbackProvider.overrideWith(
        (ref) =>
            () => ref.read(authControllerProvider.notifier).onSessionExpired(),
      ),
    ];

class FuturemugInterviewerApp extends ConsumerWidget {
  const FuturemugInterviewerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: 'Futuremug Interviewer',
      debugShowCheckedModeBanner: false,
      theme: FuturemugAppTheme.whiteTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Allow large text for accessibility, but cap extreme sizes that
        // break fixed layouts such as the OTP boxes.
        final scaled = media.copyWith(
          textScaler: media.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 2.0,
          ),
        );
        final content = MediaQuery(
          data: scaled,
          child: child ?? const SizedBox.shrink(),
        );
        if (!config.isMock) return content;
        return Banner(
          message: 'MOCK',
          location: BannerLocation.topEnd,
          child: content,
        );
      },
    );
  }
}
