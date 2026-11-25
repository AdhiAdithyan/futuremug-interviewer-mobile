import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/core/logging/app_logger.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/profile/data/profile_repository.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

/// The four steps of the first-time profile setup.
enum ProfileWizardStep {
  personal('Personal details'),
  professional('Professional details'),
  skills('Skills & domains'),
  documents('Documents');

  const ProfileWizardStep(this.title);

  final String title;
}

@immutable
class ProfileWizardState {
  const ProfileWizardState({
    this.step = ProfileWizardStep.personal,
    this.onboardingId,
    this.personal,
    this.professional,
    this.skills = const [],
    this.documents = const [],
  });

  factory ProfileWizardState.fromJson(Map<String, dynamic> json) {
    final stepName = json['step'];
    return ProfileWizardState(
      step: ProfileWizardStep.values.firstWhere(
        (s) => s.name == stepName,
        orElse: () => ProfileWizardStep.personal,
      ),
      onboardingId: json['onboardingId'] as String?,
      personal: json['personal'] is Map<String, dynamic>
          ? PersonalDetails.fromJson(json['personal'] as Map<String, dynamic>)
          : null,
      professional: json['professional'] is Map<String, dynamic>
          ? ProfessionalDetails.fromJson(
              json['professional'] as Map<String, dynamic>,
            )
          : null,
      skills: (json['skills'] is List)
          ? (json['skills'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SkillEntry.fromJson)
              .toList()
          : const [],
      documents: (json['documents'] is List)
          ? (json['documents'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ProfileDocument.fromJson)
              .toList()
          : const [],
    );
  }

  final ProfileWizardStep step;

  /// Returned by step 1; required by the later API calls.
  final String? onboardingId;
  final PersonalDetails? personal;
  final ProfessionalDetails? professional;
  final List<SkillEntry> skills;
  final List<ProfileDocument> documents;

  bool get hasResume => documents.any((d) => d.type == DocumentType.resume);

  ProfileWizardState copyWith({
    ProfileWizardStep? step,
    String? onboardingId,
    PersonalDetails? personal,
    ProfessionalDetails? professional,
    List<SkillEntry>? skills,
    List<ProfileDocument>? documents,
  }) {
    return ProfileWizardState(
      step: step ?? this.step,
      onboardingId: onboardingId ?? this.onboardingId,
      personal: personal ?? this.personal,
      professional: professional ?? this.professional,
      skills: skills ?? this.skills,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step.name,
        if (onboardingId != null) 'onboardingId': onboardingId,
        if (personal != null) 'personal': personal!.toJson(),
        if (professional != null) 'professional': professional!.toJson(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
      };
}

/// Drives the profile setup wizard. Progress is saved to the local database
/// after every step, so closing the app resumes where the user left off.
///
/// Methods throw [ApiException]s; the forms show the message.
class ProfileWizardController
    extends AutoDisposeAsyncNotifier<ProfileWizardState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  String get _draftKey {
    final auth = ref.read(authControllerProvider);
    final id = auth is Authenticated ? auth.user.interviewerId : 'unknown';
    return 'profile_wizard_draft:$id';
  }

  @override
  Future<ProfileWizardState> build() async {
    try {
      final raw = await _db.readCache(_draftKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return ProfileWizardState.fromJson(decoded);
        }
      }
    } on Object catch (error, stackTrace) {
      // A broken draft must never block setup: start fresh.
      AppLogger.error('Could not read profile draft', error, stackTrace);
    }
    return const ProfileWizardState();
  }

  ProfileWizardState get _current =>
      state.valueOrNull ?? const ProfileWizardState();

  Future<void> _save(ProfileWizardState next) async {
    state = AsyncData(next);
    await _db.writeCache(_draftKey, jsonEncode(next.toJson()));
  }

  /// Step 1 → sent to the API immediately (returns the onboarding id).
  Future<void> submitPersonal(PersonalDetails personal) async {
    final onboardingId = await _repository.submitPersonal(personal);
    await _save(
      _current.copyWith(
        personal: personal,
        onboardingId: onboardingId,
        step: ProfileWizardStep.professional,
      ),
    );
  }

  /// Step 2 → kept locally; sent together with the skills (the API takes
  /// professional details and skills in one call).
  Future<void> saveProfessional(ProfessionalDetails professional) async {
    await _save(
      _current.copyWith(
        professional: professional,
        step: ProfileWizardStep.skills,
      ),
    );
  }

  /// Step 3 → professional details + skills sent to the API.
  Future<void> submitSkills(List<SkillEntry> skills) async {
    final current = _current;
    final onboardingId = current.onboardingId;
    final professional = current.professional;
    if (onboardingId == null || professional == null) {
      // Draft is inconsistent (e.g. cleared); restart from the beginning.
      await _save(const ProfileWizardState());
      return;
    }
    await _repository.submitProfessional(
      onboardingId: onboardingId,
      professional: professional,
      skills: skills,
    );
    await _save(
      current.copyWith(skills: skills, step: ProfileWizardStep.documents),
    );
  }

  /// Step 4 → each document is uploaded as soon as it is picked.
  Future<void> uploadDocument(
    PickedDocument file,
    DocumentType type, {
    void Function(double progress)? onProgress,
  }) async {
    final onboardingId = _current.onboardingId;
    if (onboardingId == null) return;
    final uploaded = await _repository.uploadDocument(
      file: file,
      type: type,
      onboardingId: onboardingId,
      onProgress: onProgress,
    );
    final current = _current;
    // Resume and profile photo: a new one replaces the old one.
    final others = type.singleOnly
        ? current.documents.where((d) => d.type != type)
        : current.documents;
    await _save(current.copyWith(documents: [...others, uploaded]));
  }

  /// Removes a document from this setup. (The onboarding API has no delete;
  /// the server keeps the file until the profile is reviewed.)
  Future<void> removeDocument(ProfileDocument document) async {
    final current = _current;
    await _save(
      current.copyWith(
        documents: current.documents
            .where((d) => d.documentId != document.documentId)
            .toList(),
      ),
    );
  }

  Future<void> back() async {
    final current = _current;
    final index = current.step.index;
    if (index == 0) return;
    await _save(
      current.copyWith(step: ProfileWizardStep.values[index - 1]),
    );
  }

  /// Completes setup. The router then opens the dashboard.
  Future<void> finish() async {
    final current = _current;
    final onboardingId = current.onboardingId;
    if (onboardingId == null || !current.hasResume) return;

    final serverUser =
        await _repository.finalizeOnboarding(onboardingId: onboardingId);

    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) return;
    final name = (serverUser?.fullName.isNotEmpty ?? false)
        ? serverUser!.fullName
        : current.personal?.fullName ?? auth.user.fullName;

    await _db.writeCache(_draftKey, '{}');
    await ref.read(authControllerProvider.notifier).updateUser(
          auth.user.copyWith(fullName: name, isOnboardingComplete: true),
        );
  }
}

final profileWizardControllerProvider = AsyncNotifierProvider.autoDispose<
    ProfileWizardController, ProfileWizardState>(
  ProfileWizardController.new,
);
