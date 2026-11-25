import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/features/authentication/domain/evaluator_user.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

/// Profile API calls.
///
/// Onboarding (first-time setup) uses the spec's endpoints:
/// * `POST /onboarding/step-1/personal-info`
/// * `POST /onboarding/step-2/professional-skills`
/// * `POST /onboarding/step-3/documents` (multipart, one file per call)
/// * `POST /onboarding/step-4/finalize`
///
/// Editing an existing profile needs endpoints the spec doesn't have yet
/// (API gap G2): `GET/PUT /evaluator/profile`,
/// `POST /evaluator/profile/documents`, `DELETE /evaluator/profile/documents/{id}`.
class ProfileRepository {
  ProfileRepository(this._api, this._db);

  final ApiClient _api;
  final AppDatabase _db;

  static const _profileCacheKey = 'evaluator_profile';

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  /// Returns the `onboardingId` used by the next steps.
  Future<String> submitPersonal(PersonalDetails personal) async {
    final data = await _api.post(
      '/onboarding/step-1/personal-info',
      body: personal.toJson(),
    );
    final id = data['onboardingId'];
    if (id is! String || id.isEmpty) {
      throw const UnknownApiException('Unexpected server response.');
    }
    return id;
  }

  Future<void> submitProfessional({
    required String onboardingId,
    required ProfessionalDetails professional,
    required List<SkillEntry> skills,
  }) async {
    await _api.post(
      '/onboarding/step-2/professional-skills',
      body: {
        'onboardingId': onboardingId,
        ...professional.toJson(),
        'skills': skills.map((s) => s.toJson()).toList(),
      },
    );
  }

  /// Uploads one document. With [onboardingId] it goes to the onboarding
  /// endpoint; without, to the profile (edit) endpoint.
  Future<ProfileDocument> uploadDocument({
    required PickedDocument file,
    required DocumentType type,
    String? onboardingId,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData.fromMap({
      if (onboardingId != null) 'onboardingId': onboardingId,
      'documentType': type.apiValue,
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final data = await _api.post(
      onboardingId != null
          ? '/onboarding/step-3/documents'
          : '/evaluator/profile/documents',
      body: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
      ),
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    return ProfileDocument(
      documentId: data['documentId'] as String? ?? '',
      documentName: data['documentName'] as String? ?? file.name,
      type: type,
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt() ?? file.sizeBytes,
      localPath: file.path,
    );
  }

  /// Completes onboarding. Returns the updated user when the server sends
  /// one; otherwise `null` (the caller marks the profile complete locally).
  Future<EvaluatorUser?> finalizeOnboarding({
    required String onboardingId,
  }) async {
    final data = await _api.post(
      '/onboarding/step-4/finalize',
      body: {
        'onboardingId': onboardingId,
        'agreedToEvaluatorTerms': true,
        'agreedToPrivacyPolicy': true,
      },
    );
    final user = data['user'];
    return user is Map<String, dynamic> ? EvaluatorUser.fromJson(user) : null;
  }

  // ---------------------------------------------------------------------------
  // Existing profile (API gap G2)
  // ---------------------------------------------------------------------------

  /// Loads the profile, falling back to the last saved copy when offline.
  Future<InterviewerProfile> fetchProfile() async {
    try {
      final data = await _api.get('/evaluator/profile');
      final profile = InterviewerProfile.fromJson(data);
      await _db.writeCache(_profileCacheKey, jsonEncode(profile.toJson()));
      return profile;
    } on NetworkException {
      final cached = await _readCachedProfile();
      if (cached != null) return cached;
      rethrow;
    } on TimeoutApiException {
      final cached = await _readCachedProfile();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<InterviewerProfile> updateProfile(InterviewerProfile profile) async {
    final data = await _api.put(
      '/evaluator/profile',
      body: {
        'personal': profile.personal.toJson(),
        'professional': profile.professional.toJson(),
        'skills': profile.skills.map((s) => s.toJson()).toList(),
      },
    );
    // Servers may echo the saved profile; otherwise keep what was sent.
    final saved = data.containsKey('personal')
        ? InterviewerProfile.fromJson(data)
        : profile;
    await _db.writeCache(_profileCacheKey, jsonEncode(saved.toJson()));
    return saved;
  }

  Future<void> deleteDocument(String documentId) async {
    await _api.delete('/evaluator/profile/documents/$documentId');
  }

  Future<InterviewerProfile?> _readCachedProfile() async {
    final raw = await _db.readCache(_profileCacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? InterviewerProfile.fromJson(decoded)
        : null;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  ),
);
