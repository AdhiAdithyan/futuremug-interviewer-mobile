import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which backend the app talks to. Chosen at build time:
///
///   flutter run --dart-define=APP_ENV=staging
///
/// `mock` (the default) answers every request from in-app fixtures, so the
/// app runs without a backend.
enum AppEnvironment { mock, dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.sendTimeout = const Duration(seconds: 20),
    this.mockLatency = const Duration(milliseconds: 600),
  });

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'mock');
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.mock,
    );
    return AppConfig(
      environment: environment,
      baseUrl: overrideUrl.isNotEmpty ? overrideUrl : _defaultBaseUrl(environment),
    );
  }

  final AppEnvironment environment;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Simulated network delay for the mock API (tests use zero).
  final Duration mockLatency;

  bool get isMock => environment == AppEnvironment.mock;
  bool get isProduction => environment == AppEnvironment.prod;

  // URLs from the OpenAPI spec (v1.4.2). `dev` has no server listed there;
  // pass --dart-define=API_BASE_URL=... until the backend team provides one.
  static String _defaultBaseUrl(AppEnvironment env) => switch (env) {
        AppEnvironment.prod => 'https://api.futuremug.com/api/v1',
        AppEnvironment.staging => 'https://staging-api.futuremug.com/api/v1',
        AppEnvironment.dev => 'https://staging-api.futuremug.com/api/v1',
        AppEnvironment.mock => 'https://mock.futuremug.local/api/v1',
      };
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
