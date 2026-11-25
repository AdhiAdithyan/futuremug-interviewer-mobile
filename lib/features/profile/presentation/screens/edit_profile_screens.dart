import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:futuremug_interviewer/features/profile/application/profile_controller.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/personal_details_form.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/professional_details_form.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/skills_editor.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/error_view.dart';

/// Shared frame for the edit screens: loads the profile, then shows [body].
class _EditScaffold extends ConsumerWidget {
  const _EditScaffold({required this.title, required this.body});

  final String title;
  final Widget Function(InterviewerProfile profile, ProfileController controller)
      body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(profileControllerProvider),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [body(p, controller)],
          ),
        ),
      ),
    );
  }
}

/// After a successful save: confirm and go back to the Profile tab.
void _savedAndClose(BuildContext context) {
  if (!context.mounted) return;
  AppSnackbar.showInfo(context, 'Saved');
  if (context.canPop()) context.pop();
}

class EditPersonalDetailsScreen extends StatelessWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Personal details',
      body: (profile, controller) => PersonalDetailsForm(
        initial: profile.personal,
        submitLabel: 'Save',
        onSubmit: (details) async {
          await controller.updatePersonal(details);
          if (context.mounted) _savedAndClose(context);
        },
      ),
    );
  }
}

class EditProfessionalDetailsScreen extends StatelessWidget {
  const EditProfessionalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Professional details',
      body: (profile, controller) => ProfessionalDetailsForm(
        initial: profile.professional,
        submitLabel: 'Save',
        onSubmit: (details) async {
          await controller.updateProfessional(details);
          if (context.mounted) _savedAndClose(context);
        },
      ),
    );
  }
}

class EditSkillsScreen extends StatelessWidget {
  const EditSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Skills & domains',
      body: (profile, controller) => SkillsEditor(
        initial: profile.skills,
        submitLabel: 'Save',
        onSubmit: (skills) async {
          await controller.updateSkills(skills);
          if (context.mounted) _savedAndClose(context);
        },
      ),
    );
  }
}
