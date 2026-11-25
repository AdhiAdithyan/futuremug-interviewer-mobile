import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';

void main() {
  final request = RequestOptions(path: '/test');

  DioException badResponse(int status, [Object? body]) => DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: status,
          data: body,
        ),
      );

  test('timeouts map to TimeoutApiException', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      final e = ApiException.from(
        DioException(requestOptions: request, type: type),
      );
      expect(e, isA<TimeoutApiException>());
    }
  });

  test('no connection maps to NetworkException', () {
    final e = ApiException.from(
      DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
    );
    expect(e, isA<NetworkException>());
  });

  test('status codes map to the right subtype', () {
    expect(ApiException.from(badResponse(400)), isA<ValidationException>());
    expect(ApiException.from(badResponse(422)), isA<ValidationException>());
    expect(ApiException.from(badResponse(401)), isA<UnauthorizedException>());
    expect(ApiException.from(badResponse(403)), isA<ForbiddenException>());
    expect(ApiException.from(badResponse(404)), isA<NotFoundException>());
    expect(ApiException.from(badResponse(409)), isA<ConflictException>());
    expect(ApiException.from(badResponse(429)), isA<RateLimitedException>());
    expect(ApiException.from(badResponse(503)), isA<ServerException>());
    expect(ApiException.from(badResponse(418)), isA<UnknownApiException>());
  });

  test('server message, error code and field errors are kept', () {
    final e = ApiException.from(
      badResponse(400, {
        'message': 'Username already exists',
        'errorCode': 'USERNAME_TAKEN',
        'errors': {'username': 'Taken'},
      }),
    );
    expect(e.message, 'Username already exists');
    expect(e.errorCode, 'USERNAME_TAKEN');
    expect((e as ValidationException).fieldErrors, {'username': 'Taken'});
  });

  test('server errors never show the raw server message', () {
    final e = ApiException.from(
      badResponse(500, {'message': 'NullPointerException at line 42'}),
    );
    expect(e.message, isNot(contains('NullPointer')));
  });

  test('non-Dio errors become UnknownApiException', () {
    expect(ApiException.from(StateError('x')), isA<UnknownApiException>());
  });

  test('an ApiException is returned unchanged', () {
    const original = ConflictException('clash');
    expect(identical(ApiException.from(original), original), isTrue);
  });
}
