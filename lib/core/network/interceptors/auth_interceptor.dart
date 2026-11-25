import 'package:dio/dio.dart';

/// Put `extra: {AuthInterceptor.skipAuth: true}` on requests that must not
/// carry a token (OTP, login, password reset).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Future<String?> Function() readAccessToken,
    required void Function() onUnauthorized,
  })  : _readAccessToken = readAccessToken,
        _onUnauthorized = onUnauthorized;

  static const String skipAuth = 'skipAuth';

  final Future<String?> Function() _readAccessToken;
  final void Function() _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final token = await _readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isAuthenticatedCall = err.requestOptions.extra[skipAuth] != true;
    if (isAuthenticatedCall && err.response?.statusCode == 401) {
      // The spec has no token-refresh endpoint yet, so an expired session
      // signs the user out. Add a refresh-and-retry here once it exists.
      _onUnauthorized();
    }
    handler.next(err);
  }
}
