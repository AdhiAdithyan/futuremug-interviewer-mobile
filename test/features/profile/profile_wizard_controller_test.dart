import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/features/authentication/application/auth_controller.dart';
import 'package:futuremug_interviewer/features/authentication/domain/auth_state.dart';
import 'package:futuremug_interviewer/features/profile/application/profile_wizard_controller.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  const personal = PersonalDetails(
    fullName: 'Priya Sharma',
    email: 'priya@example.com',
    phone: '+919876543210',
    timezone: 'Asia/Kolkata',
    city: 'Pune',
    country: 'India',
  );
  const professional = ProfessionalDetails(
    highestQualification: 'M.Tech',
    yearsOfTotalExperience: 8,
    currentCompany: 'Acme',
    currentDesignation: 'Lead Engineer',
  );
  const skills = [
    SkillEntry(
      name: 'Flutter & Dart',
      domain: 'Mobile',
      yearsExperience: 5,
      proficiency: ProficiencyLevel.expert,
    ),
  ];

  Future<ProfileWizardController> signedInWizard() async {
    await container
        .read(authControllerProvider.notifier)
        .signIn(username: 'newuser', password: 'Secret123');
    // Keep the auto-dispose provider alive for the whole test.
    container.listen(profileWizardControllerProvider, (_, __) {});
    await container.read(profileWizardControllerProvider.future);
    return container.read(profileWizardControllerProvider.notifier);
  }

  ProfileWizardState wizardState() =>
      container.read(profileWizardControllerProvider).requireValue;

  setUp(() {
    db = AppDatabase.inMemory();
    container = createTestContainer(database: db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('a new user starts at personal details', () async {
    await signedInWizard();
    expect(wizardState().step, ProfileWizardStep.personal);
    expect(wizardState().onboardingId, isNull);
  });

  test('full setup marks the profile complete', () async {
    final wizard = await signedInWizard();

    await wizard.submitPersonal(personal);
    expect(wizardState().step, ProfileWizardStep.professional);
    expect(wizardState().onboardingId, isNotNull);

    await wizard.saveProfessional(professional);
    expect(wizardState().step, ProfileWizardStep.skills);

    await wizard.submitSkills(skills);
    expect(wizardState().step, ProfileWizardStep.documents);

    final resume = await createTempDocument('cv.pdf');
    await wizard.uploadDocument(resume, DocumentType.resume);
    expect(wizardState().hasResume, isTrue);

    await wizard.finish();

    final auth = container.read(authControllerProvider);
    expect(auth, isA<Authenticated>());
    final user = (auth as Authenticated).user;
    expect(user.isOnboardingComplete, isTrue);
    expect(user.fullName, 'Priya Sharma');
  });

  test('finish does nothing without a resume', () async {
    final wizard = await signedInWizard();
    await wizard.submitPersonal(personal);
    await wizard.saveProfessional(professional);
    await wizard.submitSkills(skills);

    await wizard.finish();

    final auth = container.read(authControllerProvider) as Authenticated;
    expect(auth.user.isOnboardingComplete, isFalse);
  });

  test('a second resume replaces the first', () async {
    final wizard = await signedInWizard();
    await wizard.submitPersonal(personal);
    await wizard.uploadDocument(
      await createTempDocument('old.pdf'),
      DocumentType.resume,
    );
    await wizard.uploadDocument(
      await createTempDocument('new.pdf'),
      DocumentType.resume,
    );

    final resumes = wizardState()
        .documents
        .where((d) => d.type == DocumentType.resume)
        .toList();
    expect(resumes, hasLength(1));
    expect(resumes.single.documentName, 'new.pdf');
  });

  test('back goes to the previous step', () async {
    final wizard = await signedInWizard();
    await wizard.submitPersonal(personal);
    await wizard.back();
    expect(wizardState().step, ProfileWizardStep.personal);
    expect(wizardState().personal?.fullName, 'Priya Sharma');
  });

  test('progress survives an app restart', () async {
    final wizard = await signedInWizard();
    await wizard.submitPersonal(personal);
    await wizard.saveProfessional(professional);
    container.dispose();

    // "Restart": a new container on the same database, same stored session.
    container = createTestContainer(database: db);
    await container.read(authControllerProvider.notifier).signIn(
          username: 'newuser',
          password: 'Secret123',
        );
    container.listen(profileWizardControllerProvider, (_, __) {});
    final restored =
        await container.read(profileWizardControllerProvider.future);

    expect(restored.step, ProfileWizardStep.skills);
    expect(restored.personal?.fullName, 'Priya Sharma');
    expect(restored.professional?.currentCompany, 'Acme');
  });
}
