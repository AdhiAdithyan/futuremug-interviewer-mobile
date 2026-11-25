import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/profile/data/profile_repository.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

/// The signed-in interviewer's profile, for the Profile tab and its edit
/// screens. Update methods throw [ApiException]s; the forms show the message.
class ProfileController extends AutoDisposeAsyncNotifier<InterviewerProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<InterviewerProfile> build() => _repository.fetchProfile();

  /// Pull-to-refresh: keeps showing the current profile until the new one
  /// arrives.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(_repository.fetchProfile);
    state = next;
  }

  InterviewerProfile get _current {
    final value = state.valueOrNull;
    if (value == null) {
      throw StateError('Profile not loaded yet');
    }
    return value;
  }

  Future<void> updatePersonal(PersonalDetails personal) async {
    await _save(_current.copyWith(personal: personal));
    await _syncNameToSession(personal.fullName);
  }

  Future<void> updateProfessional(ProfessionalDetails professional) =>
      _save(_current.copyWith(professional: professional));

  Future<void> updateSkills(List<SkillEntry> skills) =>
      _save(_current.copyWith(skills: skills));

  Future<void> uploadDocument(
    PickedDocument file,
    DocumentType type, {
    void Function(double progress)? onProgress,
  }) async {
    final uploaded = await _repository.uploadDocument(
      file: file,
      type: type,
      onProgress: onProgress,
    );
    final current = _current;
    // Resume and profile photo: a new one replaces the old one.
    final others = type.singleOnly
        ? current.documents.where((d) => d.type != type)
        : current.documents;
    state = AsyncData(current.copyWith(documents: [...others, uploaded]));
  }

  Future<void> deleteDocument(ProfileDocument document) async {
    await _repository.deleteDocument(document.documentId);
    final current = _current;
    state = AsyncData(
      current.copyWith(
        documents: current.documents
            .where((d) => d.documentId != document.documentId)
            .toList(),
      ),
    );
  }

  Future<void> _save(InterviewerProfile updated) async {
    final saved = await _repository.updateProfile(updated);
    // Documents are managed separately; keep the current list.
    state = AsyncData(saved.copyWith(documents: _current.documents));
  }

  Future<void> _syncNameToSession(String fullName) async {
    final auth = ref.read(authControllerProvider);
    if (auth is Authenticated && auth.user.fullName != fullName) {
      await ref
          .read(authControllerProvider.notifier)
          .updateUser(auth.user.copyWith(fullName: fullName));
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, InterviewerProfile>(
  ProfileController.new,
);
