import 'package:dio/dio.dart';
import 'package:futuremug_interviewer/core/logging/app_logger.dart';

/// Debug-only request log. Never prints tokens, passwords or OTP codes.
class LoggingInterceptor extends Interceptor {
  static const _redactedKeys = {
    'password',
    'newPassword',
    'confirmPassword',
    'otpCode',
    'verificationCode',
    'accessToken',
    'refreshToken',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${options.path} ${_redact(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.debug(
      '✕ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.path}',
    );
    handler.next(err);
  }

  static Object? _redact(Object? data) {
    if (data is! Map) return data;
    return {
      for (final entry in data.entries)
        entry.key: _redactedKeys.contains(entry.key) ? '***' : entry.value,
    };
  }
}
