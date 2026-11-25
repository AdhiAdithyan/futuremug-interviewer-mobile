import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/shared/validation/validators.dart';

void main() {
  group('InterviewerProfile JSON', () {
    test('round-trips all fields', () {
      final profile = InterviewerProfile(
        personal: PersonalDetails(
          fullName: 'Priya Sharma',
          email: 'priya@example.com',
          phone: '+919876543210',
          timezone: 'Asia/Kolkata',
          dateOfBirth: DateTime(1990, 4, 9),
          city: 'Pune',
          country: 'India',
        ),
        professional: const ProfessionalDetails(
          highestQualification: 'M.Tech',
          yearsOfTotalExperience: 8.5,
          currentCompany: 'Acme',
          currentDesignation: 'Lead',
          linkedInUrl: 'https://www.linkedin.com/in/priya',
        ),
        skills: const [
          SkillEntry(
            skillId: 'S1',
            name: 'Go',
            domain: 'Backend',
            yearsExperience: 4,
            proficiency: ProficiencyLevel.advanced,
          ),
        ],
        documents: const [
          ProfileDocument(
            documentId: 'D1',
            documentName: 'cv.pdf',
            type: DocumentType.resume,
            fileSizeBytes: 1000,
          ),
        ],
      );

      final copy = InterviewerProfile.fromJson(profile.toJson());

      expect(copy.personal.fullName, 'Priya Sharma');
      expect(copy.personal.dateOfBirth, DateTime(1990, 4, 9));
      expect(copy.toJson()['personal'], containsPair('dateOfBirth', '1990-04-09'));
      expect(copy.professional.yearsOfTotalExperience, 8.5);
      expect(copy.skills.single, profile.skills.single);
      expect(copy.documents.single.type, DocumentType.resume);
      expect(copy.hasResume, isTrue);
    });

    test('tolerates missing and mistyped fields', () {
      final profile = InterviewerProfile.fromJson({
        'personal': {'fullName': 42},
        'skills': [
          'not a map',
          {'name': 'Rust', 'proficiencyLevel': 'UNKNOWN'},
        ],
      });
      expect(profile.personal.fullName, '');
      expect(profile.skills.single.name, 'Rust');
      expect(profile.skills.single.proficiency, ProficiencyLevel.intermediate);
      expect(profile.documents, isEmpty);
    });

    test('skills use the API enum values', () {
      const skill = SkillEntry(
        name: 'Go',
        domain: 'Backend',
        yearsExperience: 3,
        proficiency: ProficiencyLevel.expert,
      );
      expect(skill.toJson()['proficiencyLevel'], 'EXPERT');
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('international phone', () {
      expect(Validators.phoneE164('+919876543210'), isNull);
      expect(Validators.phoneE164('+91 98765 43210'), isNull);
      expect(Validators.phoneE164('9876543210'), isNotNull);
      expect(Validators.phoneE164('+0123'), isNotNull);
    });

    test('number range', () {
      expect(
        Validators.number('8.5', fieldName: 'years', min: 0, max: 50),
        isNull,
      );
      expect(
        Validators.number('51', fieldName: 'years', min: 0, max: 50),
        isNotNull,
      );
      expect(
        Validators.number('abc', fieldName: 'years', min: 0, max: 50),
        isNotNull,
      );
    });
  });
}
