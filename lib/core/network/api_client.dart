import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class NetworkSecurityConstants {
  static const String accessTokenKey = 'futuremug_jwt_access_token';
  static const String refreshTokenKey = 'futuremug_jwt_refresh_token';
  static const String clientVersionHeader = 'X-Client-Version';
  static const String clientPlatformHeader = 'X-Client-Platform';
  static const String baseUrl = 'https://api.futuremug.com/v1';
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int sendTimeoutMs = 15000;
}

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() => 'ApiException(code: $statusCode, message: $message)';
}

class NetworkConnectionException extends ApiException {
  const NetworkConnectionException({
    super.message = 'Unable to connect to Futuremug servers. Please check your internet connection.',
  });
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({
    super.message = 'The server took too long to respond. Please try again.',
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired or invalid credentials. Please sign in again.',
    super.statusCode = 401,
  });
}

class ApiClient {
  final Dio _dio;

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
    VoidCallback? onSessionExpired,
  }) : _dio = dio {
    _dio.options = BaseOptions(
      baseUrl: NetworkSecurityConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: NetworkSecurityConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: NetworkSecurityConstants.receiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: NetworkSecurityConstants.sendTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Dio get dio => _dio;
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final sessionExpiryNotifierProvider = StateProvider<bool>((ref) => false);

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return ApiClient(
    dio: dio,
    secureStorage: secureStorage,
    onSessionExpired: () {
      ref.read(sessionExpiryNotifierProvider.notifier).state = true;
    },
  );
});
