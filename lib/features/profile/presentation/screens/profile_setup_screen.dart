import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/application/sign_up_flow_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/profile/application/profile_wizard_controller.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/documents_section.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/personal_details_form.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/professional_details_form.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/skills_editor.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/async_submit.dart';
import 'package:futuremug_interviewer/shared/widgets/primary_button.dart';
import 'package:futuremug_interviewer/shared/widgets/section_card.dart';
import 'package:futuremug_interviewer/shared/widgets/sign_out_button.dart';
import 'package:futuremug_interviewer/shared/widgets/step_progress_header.dart';

/// First-time profile setup, shown to signed-in users whose profile isn't
/// complete. Four steps; progress is saved after each one.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(profileWizardControllerProvider);
    final step = wizard.valueOrNull?.step;

    return PopScope(
      // Android back goes to the previous step instead of leaving the app.
      canPop: step == null || step == ProfileWizardStep.personal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(ref.read(profileWizardControllerProvider.notifier).back());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set up your profile'),
          automaticallyImplyLeading: false,
          leading: step != null && step != ProfileWizardStep.personal
              ? IconButton(
                  tooltip: 'Previous step',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => ref
                      .read(profileWizardControllerProvider.notifier)
                      .back(),
                )
              : null,
        ),
        body: SafeArea(
          child: wizard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your profile setup.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(profileWizardControllerProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) => _WizardBody(state: state),
          ),
        ),
      ),
    );
  }
}

class _WizardBody extends ConsumerWidget {
  const _WizardBody({required this.state});

  final ProfileWizardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileWizardControllerProvider.notifier);
    final step = state.step;

    final (icon, eyebrow, content) = switch (step) {
      ProfileWizardStep.personal => (
          Icons.person_outline,
          'About you',
          PersonalDetailsForm(
            key: const ValueKey('personal'),
            initial: state.personal ?? _prefillPersonal(ref),
            defaultPhone: _verifiedPhone(ref),
            submitLabel: 'Continue',
            onSubmit: controller.submitPersonal,
          ),
        ),
      ProfileWizardStep.professional => (
          Icons.work_outline,
          'Your work',
          ProfessionalDetailsForm(
            key: const ValueKey('professional'),
            initial: state.professional,
            submitLabel: 'Continue',
            onSubmit: controller.saveProfessional,
          ),
        ),
      ProfileWizardStep.skills => (
          Icons.psychology_outlined,
          'What you interview for',
          SkillsEditor(
            key: const ValueKey('skills'),
            initial: state.skills,
            submitLabel: 'Continue',
            onSubmit: controller.submitSkills,
          ),
        ),
      ProfileWizardStep.documents => (
          Icons.folder_open_outlined,
          'Almost done',
          _DocumentsStep(state: state),
        ),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        StepProgressHeader(
          currentStep: step.index + 1,
          totalSteps: ProfileWizardStep.values.length,
        ),
        const SizedBox(height: 20),
        SectionCard(
          icon: icon,
          eyebrow: eyebrow,
          title: step.title,
          child: content,
        ),
        const SizedBox(height: 24),
        const SignOutButton(),
      ],
    );
  }

  /// Name from the account, if the server already knows it.
  static PersonalDetails? _prefillPersonal(WidgetRef ref) {
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) return null;
    final user = auth.user;
    if (user.fullName.isEmpty && (user.email ?? '').isEmpty) return null;
    return PersonalDetails(
      fullName: user.fullName,
      email: user.email ?? '',
      phone: _verifiedPhone(ref) ?? '',
      timezone: guessTimezone(),
    );
  }

  /// The number verified during sign-up, in E.164 form.
  static String? _verifiedPhone(WidgetRef ref) {
    final flow = ref.read(signUpFlowProvider);
    final code = flow.countryCode;
    final number = flow.phoneNumber;
    if (code == null || number == null) return null;
    return '$code$number';
  }
}

class _DocumentsStep extends ConsumerStatefulWidget {
  const _DocumentsStep({required this.state});

  final ProfileWizardState state;

  @override
  ConsumerState<_DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends ConsumerState<_DocumentsStep> {
  bool _agreed = false;
  bool _isFinishing = false;

  Future<void> _finish() async {
    if (!widget.state.hasResume) {
      AppSnackbar.showError(context, 'Upload your resume to continue.');
      return;
    }
    if (!_agreed) {
      AppSnackbar.showError(context, 'Please accept the interviewer terms.');
      return;
    }
    setState(() => _isFinishing = true);
    await runWithErrorSnackbar(
      context,
      () => ref.read(profileWizardControllerProvider.notifier).finish(),
    );
    // On success the router opens the dashboard and this screen goes away.
    if (mounted) setState(() => _isFinishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(profileWizardControllerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentsSection(
          documents: widget.state.documents,
          onUpload: (file, type, onProgress) =>
              controller.uploadDocument(file, type, onProgress: onProgress),
          onRemove: controller.removeDocument,
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: _agreed,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: _isFinishing
              ? null
              : (v) => setState(() => _agreed = v ?? false),
          title: Text(
            'I agree to the Futuremug interviewer terms and privacy policy.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Finish setup',
          isLoading: _isFinishing,
          onPressed: _finish,
        ),
      ],
    );
  }
}
