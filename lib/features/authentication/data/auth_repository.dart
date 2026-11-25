import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/security/secure_storage_service.dart';
import 'package:futuremug_interviewer/features/authentication/domain/evaluator_user.dart';

class OtpChallenge {
  const OtpChallenge({
    required this.otpSessionId,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    this.maskedDestination,
  });

  final String otpSessionId;
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final String? maskedDestination;
}

/// All authentication calls. Endpoints follow the OpenAPI spec v1.4.2, except
/// `POST /auth/register`, which the spec doesn't have yet (API gap G1).
class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SecureStorageService _storage;

  /// `countryCode` like `+91`, `phoneNumber` digits only.
  Future<OtpChallenge> sendOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    final data = await _api.post(
      '/auth/otp/send',
      body: {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'purpose': 'REGISTRATION_VERIFICATION',
      },
      options: ApiClient.publicCall,
    );
    return OtpChallenge(
      otpSessionId: _requireString(data, 'otpSessionId'),
      expiresInSeconds: _int(data['expiresInSeconds']) ?? 60,
      resendAfterSeconds: _int(data['resendAvailableAfterSeconds']) ?? 30,
      maskedDestination: data['maskedDestination'] as String?,
    );
  }

  /// Returns a verification token that proves the phone was verified; it is
  /// sent with [register].
  Future<String> verifyOtp({
    required String otpSessionId,
    required String otpCode,
  }) async {
    final data = await _api.post(
      '/auth/otp/verify',
      body: {'otpSessionId': otpSessionId, 'otpCode': otpCode},
      options: ApiClient.publicCall,
    );
    // The spec says verify returns tokens; until G1 is settled, accept either
    // a `verificationToken` or an `accessToken`.
    final token = data['verificationToken'] ?? data['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const UnknownApiException('Verification failed. Please try again.');
    }
    return token;
  }

  /// Creates the account's username and password (API gap G1) and signs in.
  Future<EvaluatorUser> register({
    required String verificationToken,
    required String username,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {
        'verificationToken': verificationToken,
        'username': username,
        'password': password,
      },
      options: ApiClient.publicCall,
    );
    return _persistSession(data);
  }

  Future<EvaluatorUser> login({
    required String username,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {'username': username, 'password': password, 'rememberMe': true},
      options: ApiClient.publicCall,
    );
    return _persistSession(data);
  }

  /// Returns the `recoverySessionId` for [resetPassword].
  Future<String> requestPasswordReset({required String email}) async {
    final data = await _api.post(
      '/auth/password/forgot',
      body: {'email': email},
      options: ApiClient.publicCall,
    );
    return _requireString(data, 'recoverySessionId');
  }

  Future<void> resetPassword({
    required String recoverySessionId,
    required String verificationCode,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/password/reset',
      body: {
        'recoverySessionId': recoverySessionId,
        'verificationCode': verificationCode,
        'newPassword': newPassword,
      },
      options: ApiClient.publicCall,
    );
  }

  /// The user saved on this device, if a session exists.
  Future<EvaluatorUser?> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final json = await _storage.readUserJson();
    if (json == null) return null;
    return EvaluatorUser.fromJson(json);
  }

  Future<void> updateStoredUser(EvaluatorUser user) =>
      _storage.saveUserJson(user.toJson());

  /// Clears tokens on this device. A server-side logout call can be added
  /// once the spec defines one.
  Future<void> signOut() => _storage.clearSession();

  Future<EvaluatorUser> _persistSession(Map<String, dynamic> data) async {
    final accessToken = _requireString(data, 'accessToken');
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const UnknownApiException('Sign-in response had no user profile.');
    }
    final user = EvaluatorUser.fromJson(userJson);
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
    );
    await _storage.saveUserJson(user.toJson());
    return user;
  }

  static String _requireString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    throw UnknownApiException('Unexpected server response (missing $key).');
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
  ),
);
