import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens and the cached signed-in user, kept in the platform keychain /
/// keystore. Nothing secret goes to SharedPreferences or SQLite.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'fm_access_token';
  static const _refreshTokenKey = 'fm_refresh_token';
  static const _userKey = 'fm_user_json';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<Map<String, dynamic>?> readUserJson() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveUserJson(Map<String, dynamic> json) =>
      _storage.write(key: _userKey, value: jsonEncode(json));

  /// Signs the device out. Local drafts in SQLite are intentionally kept.
  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(flutterSecureStorageProvider)),
);
