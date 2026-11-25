import 'dart:convert';

import 'package:dio/dio.dart';

/// Answers API calls from in-app fixtures when the app runs with
/// `APP_ENV=mock` (the default). Responses follow the OpenAPI spec's envelope:
/// `{status, statusCode, message, data}`.
///
/// Test accounts:
/// * any username + any password → signed in, profile complete
/// * username `newuser`          → signed in, profile NOT complete
/// * password `wrong`            → 401 invalid credentials
/// * OTP `000000`                → invalid code; any other 6 digits pass
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final method = options.method.toUpperCase();
    final path = _normalisePath(options.path);
    // File downloads answer with bytes instead of the JSON envelope.
    if (method == 'GET' &&
        path.startsWith('/evaluator/profile/documents/') &&
        path.endsWith('/download')) {
      final bytes = utf8.encode(_samplePdf);
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: ResponseBody.fromBytes(
            bytes,
            200,
            headers: {
              Headers.contentTypeHeader: ['application/pdf'],
              Headers.contentLengthHeader: ['${bytes.length}'],
            },
          ),
        ),
      );
      return;
    }

    final body = _readBody(options.data);

    final result = _route(method, path, body);
    if (result.statusCode >= 400) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: result.statusCode,
            data: result.body,
          ),
        ),
        true,
      );
      return;
    }
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: result.statusCode,
        data: result.body,
      ),
    );
  }

  static Map<String, dynamic> _readBody(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is FormData) {
      return {
        for (final field in data.fields) field.key: field.value,
        for (final file in data.files) file.key: file.value.filename,
        if (data.files.isNotEmpty) '_fileSize': data.files.first.value.length,
      };
    }
    return const <String, dynamic>{};
  }

  static String _normalisePath(String path) {
    final uri = Uri.parse(path);
    // Absolute URLs (shouldn't happen, but be safe): keep the part after /v1.
    final p = uri.path;
    final index = p.indexOf('/api/v1');
    return index >= 0 ? p.substring(index + '/api/v1'.length) : p;
  }

  _MockResult _route(String method, String path, Map<String, dynamic> body) {
    switch ((method, path)) {
      case ('POST', '/auth/otp/send'): {
          final phone = '${body['phoneNumber'] ?? ''}';
          if (phone.length < 6) {
            return _error(400, 'Enter a valid mobile number.', 'INVALID_PHONE');
          }
          return _ok({
            'otpSessionId': 'otp_sess_mock_001',
            'expiresInSeconds': 60,
            'resendAvailableAfterSeconds': 30,
            'maskedDestination':
                '${body['countryCode'] ?? ''} ******${phone.substring(phone.length - 4)}',
          });
      }

      case ('POST', '/auth/otp/verify'):
        if (body['otpCode'] == '000000') {
          return _error(400, 'That code is not correct.', 'INVALID_OTP');
        }
        return _ok({'verificationToken': 'otp_verified_mock_token'});

      case ('POST', '/auth/register'): {
          final username = '${body['username'] ?? ''}';
          if (username == 'taken') {
            return _error(409, 'That username is already taken.', 'USERNAME_TAKEN');
          }
          return _ok(_authData(username: username, onboardingComplete: false));
      }

      case ('POST', '/auth/login'): {
          if (body['password'] == 'wrong') {
            return _error(
              401,
              'Incorrect username or password.',
              'INVALID_CREDENTIALS',
            );
          }
          final username = '${body['username'] ?? 'alex.morgan'}';
          return _ok(
            _authData(
              username: username,
              onboardingComplete: username != 'newuser',
            ),
          );
      }

      case ('POST', '/auth/password/forgot'):
        return _ok({
          'recoverySessionId': 'rec_sess_mock_001',
          'maskedPhone': '+91 ******3210',
          'maskedEmail': 'a***n@futuremug.com',
        });

      case ('POST', '/auth/password/reset'):
        if (body['verificationCode'] == '000000') {
          return _error(400, 'That code is not correct.', 'INVALID_OTP');
        }
        return _ok({'reset': true});

      // ---- Onboarding (profile setup) -------------------------------------
      case ('POST', '/onboarding/step-1/personal-info'):
        _profile['personal'] = Map<String, dynamic>.of(body);
        return _ok({
          'onboardingId': 'ONB-MOCK-0001',
          'currentStep': 1,
          'nextStep': 2,
          'completedPercentage': 25,
        });

      case ('POST', '/onboarding/step-2/professional-skills'):
        _profile['professional'] = {
          for (final key in const [
            'highestQualification',
            'yearsOfTotalExperience',
            'currentCompany',
            'currentDesignation',
            'linkedInUrl',
          ])
            if (body.containsKey(key)) key: body[key],
        };
        _profile['skills'] = body['skills'] ?? const <Object>[];
        return _ok({
          'onboardingId': body['onboardingId'],
          'currentStep': 2,
          'nextStep': 3,
          'completedPercentage': 50,
        });

      case ('POST', '/onboarding/step-3/documents'):
      case ('POST', '/evaluator/profile/documents'): {
          final document = {
            'documentId': 'DOC-MOCK-${++_documentCounter}',
            'documentName': body['file'] ?? 'document.pdf',
            'documentType': body['documentType'] ?? 'CERTIFICATION',
            'fileSizeBytes': body['_fileSize'] ?? 0,
          };
          _documents.add(document);
          return _ok({...document, 'currentStep': 3, 'completedPercentage': 75});
      }

      case ('POST', '/onboarding/step-4/finalize'): {
          final personal = _profile['personal'];
          final fullName = personal is Map ? '${personal['fullName'] ?? ''}' : '';
          return _ok({
            'status': 'ACTIVE',
            'user': {
              'interviewerId': 'EV-MOCK-0001',
              'fullName': fullName,
              'isOnboardingComplete': true,
            },
          });
      }

      // ---- Profile (API gap G2) --------------------------------------------
      case ('GET', '/evaluator/profile'):
        return _ok(_currentProfile());

      case ('PUT', '/evaluator/profile'):
        for (final key in const ['personal', 'professional', 'skills']) {
          if (body.containsKey(key)) _profile[key] = body[key];
        }
        return _ok(_currentProfile());

      // ---- Dashboard -------------------------------------------------------
      case ('GET', '/dashboard/summary'): {
          final personal = _profile['personal'];
          final name = personal is Map && personal['fullName'] is String
              ? personal['fullName'] as String
              : 'Alex Morgan';
          return _ok({
            'profileSummary': {
              'interviewerId': 'EV-MOCK-0001',
              'fullName': name,
              'tier': 'Tier-1 Senior Evaluator',
              'rating': 4.9,
              'totalCompletedInterviews': 42,
              'availabilityStatus': 'AVAILABLE_NOW',
            },
            'statisticsCards': {
              'completedInterviews': 42,
              'pendingInterviews': 3,
              'todayInterviews': 1,
              'totalEarningsAccrued': 124500,
              'currency': 'INR',
            },
            'upcomingNextInterview': {
              'interviewId': 'INT-9821',
              'candidateName': 'David Chen',
              'targetRole': 'Senior Flutter Engineer',
              'clientCompany': 'Apex Enterprise Labs',
              'timeFormatted': 'Today • 4:00 PM – 5:00 PM (IST)',
              'timeRemainingMinutes': 45,
              'meetingPlatform': 'GOOGLE_MEET',
              'meetingJoinUrl': 'https://meet.google.com/',
              'status': 'CONFIRMED_LOCKED',
            },
            'monthlyInterviewChart': [
              {'month': 'Sep', 'interviews': 8, 'earnings': 24000},
              {'month': 'Oct', 'interviews': 12, 'earnings': 36000},
              {'month': 'Nov', 'interviews': 10, 'earnings': 30000},
            ],
          });
      }
    }
    if (method == 'DELETE' && path.startsWith('/evaluator/profile/documents/')) {
      final id = path.substring('/evaluator/profile/documents/'.length);
      _documents.removeWhere((d) => d['documentId'] == id);
      return _ok({'deleted': id});
    }
    return _error(404, 'Mock: no fixture for $method $path', 'MOCK_NOT_FOUND');
  }

  /// A one-page PDF served for any document download in mock mode.
  static const String _samplePdf = '''
%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj
4 0 obj << /Length 62 >> stream
BT /F1 20 Tf 72 760 Td (Futuremug mock document) Tj ET
endstream endobj
5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj
trailer << /Root 1 0 R >>
%%EOF
''';

  // In-memory "server" state, so edits survive for the app session.
  final Map<String, Object?> _profile = {
    'personal': {
      'fullName': 'Alex Morgan',
      'email': 'alex.morgan@futuremug.com',
      'phone': '+919876543210',
      'timezone': 'Asia/Kolkata',
      'city': 'Bengaluru',
      'country': 'India',
    },
    'professional': {
      'highestQualification': 'B.Tech, Computer Science',
      'yearsOfTotalExperience': 9,
      'currentCompany': 'Apex Enterprise Labs',
      'currentDesignation': 'Staff Engineer',
    },
    'skills': [
      {
        'skillId': 'SKL-1',
        'name': 'Flutter & Dart',
        'domain': 'Mobile',
        'yearsExperience': 6,
        'proficiencyLevel': 'EXPERT',
      },
      {
        'skillId': 'SKL-2',
        'name': 'System Design',
        'domain': 'Architecture',
        'yearsExperience': 5,
        'proficiencyLevel': 'ADVANCED',
      },
    ],
  };
  final List<Map<String, Object?>> _documents = [
    {
      'documentId': 'DOC-MOCK-0',
      'documentName': 'Alex_Morgan_CV.pdf',
      'documentType': 'RESUME_CV',
      'fileSizeBytes': 482113,
    },
  ];
  int _documentCounter = 0;

  Map<String, dynamic> _currentProfile() => {
        'personal': _profile['personal'],
        'professional': _profile['professional'],
        'skills': _profile['skills'],
        'documents': _documents,
      };

  static Map<String, dynamic> _authData({
    required String username,
    required bool onboardingComplete,
  }) =>
      {
        'accessToken': 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
        'refreshToken': 'mock_refresh_token',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'interviewerId': 'EV-MOCK-0001',
          'fullName': onboardingComplete ? 'Alex Morgan' : '',
          'username': username,
          'email': 'alex.morgan@futuremug.com',
          'tierLevel': 'TIER_1_EVALUATOR',
          'isOnboardingComplete': onboardingComplete,
        },
      };

  static _MockResult _ok(Map<String, dynamic> data) => _MockResult(200, {
        'status': 'SUCCESS',
        'statusCode': 200,
        'message': 'OK',
        'data': data,
      });

  static _MockResult _error(int status, String message, String errorCode) =>
      _MockResult(status, {
        'status': 'ERROR',
        'statusCode': status,
        'message': message,
        'errorCode': errorCode,
      });
}

class _MockResult {
  const _MockResult(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}
