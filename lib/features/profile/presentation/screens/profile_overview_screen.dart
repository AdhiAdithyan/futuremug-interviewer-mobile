import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:futuremug_interviewer/core/router/app_routes.dart';
import 'package:futuremug_interviewer/features/profile/application/profile_controller.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/documents_section.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/personal_details_form.dart';
import 'package:futuremug_interviewer/shared/widgets/error_view.dart';
import 'package:futuremug_interviewer/shared/widgets/sign_out_button.dart';

/// Profile tab: the interviewer's details, skills and documents, each with an
/// Edit action, plus sign-out.
class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileControllerProvider),
          footer: const SignOutButton(),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () => ref.read(profileControllerProvider.notifier).refresh(),
          child: _ProfileContent(profile: p),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final InterviewerProfile profile;

  static final DateFormat _dob = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(profileControllerProvider.notifier);
    final personal = profile.personal;
    final professional = profile.professional;
    final initials = personal.fullName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personal.fullName.isEmpty ? 'Your name' : personal.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (professional.currentDesignation.isNotEmpty)
                        Text(
                          '${professional.currentDesignation}'
                          '${professional.currentCompany.isEmpty ? '' : ' · ${professional.currentCompany}'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Section(
          title: 'Personal details',
          editRoute: AppRoutes.profilePersonal,
          rows: [
            ('Email', personal.email),
            ('Mobile', personal.phone),
            (
              'Date of birth',
              personal.dateOfBirth == null ? '' : _dob.format(personal.dateOfBirth!),
            ),
            (
              'Location',
              [personal.city, personal.country]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(', '),
            ),
            ('Time zone', kTimezones[personal.timezone] ?? personal.timezone),
          ],
        ),
        _Section(
          title: 'Professional details',
          editRoute: AppRoutes.profileProfessional,
          rows: [
            ('Qualification', professional.highestQualification),
            ('Experience', _years(professional.yearsOfTotalExperience)),
            ('Company', professional.currentCompany),
            ('Designation', professional.currentDesignation),
            ('LinkedIn', professional.linkedInUrl ?? ''),
          ],
        ),
        _Section(
          title: 'Skills & domains',
          editRoute: AppRoutes.profileSkills,
          child: profile.skills.isEmpty
              ? const Text('No skills added yet.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in profile.skills)
                      Chip(
                        label: Text('${s.name} · ${s.proficiency.label}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
        ),
        _Section(
          title: 'Documents',
          child: DocumentsSection(
            documents: profile.documents,
            onUpload: (file, type, onProgress) =>
                controller.uploadDocument(file, type, onProgress: onProgress),
            onRemove: controller.deleteDocument,
          ),
        ),
        if (!profile.hasResume)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Upload your resume so clients can review your background.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 24),
        const SignOutButton(),
      ],
    );
  }

  static String _years(double years) {
    final text =
        years == years.roundToDouble() ? years.toInt().toString() : '$years';
    return years == 1 ? '1 year' : '$text years';
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.editRoute,
    this.rows,
    this.child,
    this.editLabel = 'Edit',
  });

  final String title;

  /// `null` hides the Edit button (the section edits in place).
  final String? editRoute;
  final String editLabel;
  final List<(String, String)>? rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleRows = (rows ?? const <(String, String)>[])
        .where((r) => r.$2.isNotEmpty)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (editRoute != null)
                  TextButton(
                    onPressed: () => context.push(editRoute!),
                    child: Text(editLabel),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
            for (final (label, value) in visibleRows)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
