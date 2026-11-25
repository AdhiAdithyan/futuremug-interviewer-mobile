import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/app.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework errors (build/layout/paint).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error',
      details.exception,
      details.stack,
    );
  };

  // Errors outside the framework (async gaps, platform channels).
  WidgetsBinding.instance.platformDispatcher.onError = (error, stackTrace) {
    AppLogger.error('Uncaught error', error, stackTrace);
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final database = AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: appRootOverrides(database: database),
      observers: const [_ProviderErrorLogger()],
      child: const FuturemugInterviewerApp(),
    ),
  );
}

/// Logs providers that fail; successful updates are not logged (too noisy).
class _ProviderErrorLogger extends ProviderObserver {
  const _ProviderErrorLogger();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider ${provider.name ?? provider.runtimeType} failed',
      error,
      stackTrace,
    );
  }
}
