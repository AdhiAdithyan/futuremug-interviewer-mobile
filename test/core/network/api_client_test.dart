import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/network/interceptors/auth_interceptor.dart';
import 'package:futuremug_interviewer/core/network/interceptors/idempotency_interceptor.dart';
import 'package:futuremug_interviewer/core/network/mock/mock_api_interceptor.dart';

/// Records the headers of each request before the mock answers it.
class _HeaderRecorder extends Interceptor {
  final List<Map<String, dynamic>> headers = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    headers.add(Map.of(options.headers));
    handler.next(options);
  }
}

void main() {
  late Dio dio;
  late ApiClient client;
  late _HeaderRecorder recorder;
  var unauthorizedCalls = 0;
  String? token;

  setUp(() {
    unauthorizedCalls = 0;
    token = 'abc123';
    recorder = _HeaderRecorder();
    dio = Dio(BaseOptions(baseUrl: 'https://mock.futuremug.local/api/v1'));
    dio.interceptors.addAll([
      AuthInterceptor(
        readAccessToken: () async => token,
        onUnauthorized: () => unauthorizedCalls++,
      ),
      IdempotencyInterceptor(),
      recorder,
      MockApiInterceptor(latency: Duration.zero),
    ]);
    client = ApiClient(dio);
  });

  tearDown(() => dio.close());

  test('unwraps the data object of the envelope', () async {
    final data = await client.post(
      '/auth/login',
      body: {'username': 'alex', 'password': 'Secret123'},
      options: ApiClient.publicCall,
    );
    expect(data['accessToken'], isA<String>());
    expect((data['user'] as Map)['isOnboardingComplete'], isTrue);
  });

  test('error responses throw typed ApiExceptions with the server message',
      () async {
    await expectLater(
      client.post(
        '/auth/login',
        body: {'username': 'alex', 'password': 'wrong'},
        options: ApiClient.publicCall,
      ),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Incorrect username or password.',
        ),
      ),
    );
  });

  test('public calls carry no token and do not trigger sign-out on 401',
      () async {
    await expectLater(
      client.post(
        '/auth/login',
        body: {'password': 'wrong'},
        options: ApiClient.publicCall,
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(recorder.headers.single.containsKey('Authorization'), isFalse);
    expect(unauthorizedCalls, 0);
  });

  test('authenticated calls carry the bearer token', () async {
    await client.get('/dashboard/summary');
    expect(recorder.headers.single['Authorization'], 'Bearer abc123');
  });

  test('no token means no Authorization header', () async {
    token = null;
    await client.get('/dashboard/summary');
    expect(recorder.headers.single.containsKey('Authorization'), isFalse);
  });

  test('writes get a unique Idempotency-Key, reads do not', () async {
    await client.get('/dashboard/summary');
    await client.post('/auth/password/forgot', body: {'email': 'a@b.co'});
    await client.post('/auth/password/forgot', body: {'email': 'a@b.co'});

    expect(recorder.headers[0].containsKey(IdempotencyInterceptor.header), isFalse);
    final first = recorder.headers[1][IdempotencyInterceptor.header];
    final second = recorder.headers[2][IdempotencyInterceptor.header];
    expect(first, isA<String>());
    expect(first, isNot(second));
  });

  test('unwrapEnvelope handles non-envelope bodies', () {
    expect(ApiClient.unwrapEnvelope({'data': 5}), {'data': 5});
    expect(ApiClient.unwrapEnvelope([1, 2]), {'data': [1, 2]});
    expect(ApiClient.unwrapEnvelope({'a': 1}), {'a': 1});
  });
}
