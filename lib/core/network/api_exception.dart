import 'package:dio/dio.dart';

/// Every failed API call surfaces as one of these. Screens show [message];
/// controllers can branch on the subtype (e.g. [ConflictException] for a
/// double-booked slot).
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;

  /// Machine-readable code from the backend body (`errorCode`), if any.
  final String? errorCode;

  @override
  String toString() => '$runtimeType($statusCode, $errorCode): $message';

  /// Maps any error thrown by Dio (or anything else) to an [ApiException].
  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _fromDio(error);
    return UnknownApiException(error.toString());
  }

  static ApiException _fromDio(DioException e) {
    final inner = e.error;
    if (inner is ApiException) return inner;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutApiException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Secure connection failed. Check your network and try again.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
      default:
        break;
    }

    final response = e.response;
    if (response == null) return const NetworkException();

    final status = response.statusCode ?? 0;
    final body = response.data;
    final serverMessage = _readString(body, 'message');
    final errorCode = _readString(body, 'errorCode');

    return switch (status) {
      400 || 422 => ValidationException(
          serverMessage ?? 'Some details are not valid. Please check and try again.',
          statusCode: status,
          errorCode: errorCode,
          fieldErrors: _readFieldErrors(body),
        ),
      401 => UnauthorizedException(
          serverMessage ?? 'Your session has expired. Please sign in again.',
          errorCode: errorCode,
        ),
      403 => ForbiddenException(
          serverMessage ?? 'You do not have access to this.',
          errorCode: errorCode,
        ),
      404 => NotFoundException(
          serverMessage ?? 'We could not find what you were looking for.',
          errorCode: errorCode,
        ),
      409 => ConflictException(
          serverMessage ?? 'This conflicts with an existing booking.',
          errorCode: errorCode,
        ),
      429 => RateLimitedException(
          serverMessage ?? 'Too many attempts. Please wait a moment and try again.',
          errorCode: errorCode,
        ),
      >= 500 => ServerException(
          'Something went wrong on our side. Please try again shortly.',
          statusCode: status,
          errorCode: errorCode,
        ),
      _ => UnknownApiException(
          serverMessage ?? 'Unexpected error ($status).',
          statusCode: status,
          errorCode: errorCode,
        ),
    };
  }

  static String? _readString(Object? body, String key) {
    if (body is Map && body[key] is String) return body[key] as String;
    return null;
  }

  static Map<String, String> _readFieldErrors(Object? body) {
    if (body is! Map) return const {};
    final errors = body['errors'];
    if (errors is! Map) return const {};
    return {
      for (final entry in errors.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  }
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class TimeoutApiException extends ApiException {
  const TimeoutApiException([
    super.message = 'The server took too long to respond. Please try again.',
  ]);
}

class CancelledException extends ApiException {
  const CancelledException([super.message = 'Request cancelled.']);
}

class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    super.statusCode = 400,
    super.errorCode,
    this.fieldErrors = const {},
  });

  /// Field name → error text, when the backend returns per-field errors.
  final Map<String, String> fieldErrors;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.errorCode})
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.errorCode})
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.errorCode})
      : super(statusCode: 404);
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {super.errorCode})
      : super(statusCode: 409);
}

class RateLimitedException extends ApiException {
  const RateLimitedException(super.message, {super.errorCode})
      : super(statusCode: 429);
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.errorCode});
}

class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.statusCode, super.errorCode});
}
