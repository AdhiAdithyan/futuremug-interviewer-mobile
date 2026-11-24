import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/futuremug_app_theme.dart';

class FuturemugStateObserver extends ProviderObserver {
  const FuturemugStateObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('[Riverpod State Shift] Provider: ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint('🚨 [Riverpod Provider Error] ${provider.name ?? provider.runtimeType}: $error');
  }
}

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _initializeSystemChrome();

    final appDatabase = AppDatabase();

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDatabase),
      ],
      observers: const [FuturemugStateObserver()],
    );

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FuturemugInterviewerApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('🔥 [Uncaught Application Exception] $error\n$stackTrace');
  });
}

Future<void> _initializeSystemChrome() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class FuturemugInterviewerApp extends ConsumerWidget {
  const FuturemugInterviewerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(onboardingRouterProvider);

    return MaterialApp.router(
      title: 'Futuremug Interviewer',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: FuturemugAppTheme.whiteTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final constrainedScale = mediaQueryData.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: constrainedScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
