import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/config/app_config.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/network/interceptors/auth_interceptor.dart';
import 'package:futuremug_interviewer/core/network/interceptors/idempotency_interceptor.dart';
import 'package:futuremug_interviewer/core/network/interceptors/logging_interceptor.dart';
import 'package:futuremug_interviewer/core/network/mock/mock_api_interceptor.dart';
import 'package:futuremug_interviewer/core/security/secure_storage_service.dart';

/// Thin wrapper over Dio used by every remote data source.
///
/// * Unwraps the `{status, message, data}` envelope and returns `data`.
/// * Throws only [ApiException] subtypes, never raw [DioException]s.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// For calls that must not carry a token (OTP, login, password reset).
  static final Options publicCall = Options(
    extra: const {AuthInterceptor.skipAuth: true},
  );

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) =>
      _send(
        () => _dio.get<dynamic>(path, queryParameters: query, options: options),
      );

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Options? options,
    ProgressCallback? onSendProgress,
  }) =>
      _send(
        () => _dio.post<dynamic>(
          path,
          data: body,
          options: options,
          onSendProgress: onSendProgress,
        ),
      );

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Options? options,
  }) =>
      _send(() => _dio.put<dynamic>(path, data: body, options: options));

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Options? options,
  }) =>
      _send(() => _dio.delete<dynamic>(path, data: body, options: options));

  /// Downloads a file to [savePath] (authenticated like any other call).
  Future<void> download(
    String path,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        onReceiveProgress: onProgress == null
            ? null
            : (received, total) {
                if (total > 0) onProgress(received / total);
              },
      );
    } on Object catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return unwrapEnvelope(response.data);
    } on Object catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Returns the `data` object of the standard envelope. A response without
  /// an envelope (or with a non-object `data`) is returned as
  /// `{'data': <value>}` so callers always get a map.
  @visibleForTesting
  static Map<String, dynamic> unwrapEnvelope(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (body.containsKey('data')) return {'data': data};
      return body;
    }
    return {'data': body};
  }
}

/// Called when an authenticated request returns 401. The auth session
/// controller overrides this to sign the user out.
final sessionExpiredCallbackProvider = Provider<void Function()>(
  (ref) => () {},
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      readAccessToken: storage.readAccessToken,
      // Read lazily so the callback can be overridden after creation.
      onUnauthorized: () => ref.read(sessionExpiredCallbackProvider)(),
    ),
    IdempotencyInterceptor(),
    if (kDebugMode) LoggingInterceptor(),
    // Must be last: it answers the request after the others added headers.
    if (config.isMock) MockApiInterceptor(latency: config.mockLatency),
  ]);

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
