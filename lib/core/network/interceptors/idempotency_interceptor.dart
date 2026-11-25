import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Adds a unique `Idempotency-Key` to every write, so a retried request can't
/// create a duplicate booking or report (PRD NFR-SYNC-2). Callers that retry
/// the same logical operation should pass their own key in the headers.
class IdempotencyInterceptor extends Interceptor {
  IdempotencyInterceptor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String header = 'Idempotency-Key';
  static const _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_writeMethods.contains(options.method.toUpperCase()) &&
        !options.headers.containsKey(header)) {
      options.headers[header] = _uuid.v4();
    }
    handler.next(options);
  }
}
