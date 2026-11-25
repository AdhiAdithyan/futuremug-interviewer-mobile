import 'package:flutter/foundation.dart';

/// Proficiency levels from the OpenAPI spec (`proficiencyLevel`).
enum ProficiencyLevel {
  intermediate('INTERMEDIATE', 'Intermediate'),
  advanced('ADVANCED', 'Advanced'),
  expert('EXPERT', 'Expert');

  const ProficiencyLevel(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ProficiencyLevel fromApi(Object? value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => ProficiencyLevel.intermediate,
      );
}

/// Kinds of document an interviewer can upload.
///
/// `RESUME_CV`, `CERTIFICATION` and `IDENTITY_PROOF` are in the OpenAPI spec.
/// The others are new values the backend must accept (API gap G7).
enum DocumentType {
  resume(
    'RESUME_CV',
    'Resume / CV',
    'Required. Your latest CV.',
    singleOnly: true,
  ),
  degreeCertificate(
    'DEGREE_CERTIFICATE',
    'Degree certificate',
    'Your highest qualification.',
  ),
  experienceLetter(
    'EXPERIENCE_LETTER',
    'Experience letter',
    'From a current or past employer.',
  ),
  certification(
    'CERTIFICATION',
    'Professional certificate',
    'e.g. AWS, Google Cloud, Scrum.',
  ),
  identityProof(
    'IDENTITY_PROOF',
    'ID proof',
    'Aadhaar, PAN, passport or driving licence.',
  ),
  profilePhoto(
    'PROFILE_PHOTO',
    'Profile photo',
    'A clear, recent photo of your face.',
    singleOnly: true,
    imagesOnly: true,
  ),
  other(
    'OTHER',
    'Other document',
    'Anything else that supports your profile.',
  );

  const DocumentType(
    this.apiValue,
    this.label,
    this.hint, {
    this.singleOnly = false,
    this.imagesOnly = false,
  });

  final String apiValue;
  final String label;
  final String hint;

  /// Only one allowed; uploading another replaces it.
  final bool singleOnly;

  /// Only JPG / PNG images allowed.
  final bool imagesOnly;

  static DocumentType fromApi(Object? value) => values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => DocumentType.other,
      );
}

@immutable
class PersonalDetails {
  const PersonalDetails({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.timezone,
    this.dateOfBirth,
    this.city,
    this.country,
  });

  factory PersonalDetails.fromJson(Map<String, dynamic> json) {
    final dob = _str(json['dateOfBirth']);
    return PersonalDetails(
      fullName: _str(json['fullName']) ?? '',
      email: _str(json['email']) ?? '',
      phone: _str(json['phone']) ?? '',
      timezone: _str(json['timezone']) ?? 'UTC',
      dateOfBirth: dob == null ? null : DateTime.tryParse(dob),
      city: _str(json['city']),
      country: _str(json['country']),
    );
  }

  final String fullName;
  final String email;

  /// E.164, e.g. +919876543210.
  final String phone;

  /// IANA zone, e.g. Asia/Kolkata.
  final String timezone;
  final DateTime? dateOfBirth;
  final String? city;
  final String? country;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'timezone': timezone,
        if (dateOfBirth != null) 'dateOfBirth': _date(dateOfBirth!),
        if (city != null && city!.isNotEmpty) 'city': city,
        if (country != null && country!.isNotEmpty) 'country': country,
      };
}

@immutable
class ProfessionalDetails {
  const ProfessionalDetails({
    required this.highestQualification,
    required this.yearsOfTotalExperience,
    required this.currentCompany,
    required this.currentDesignation,
    this.linkedInUrl,
  });

  factory ProfessionalDetails.fromJson(Map<String, dynamic> json) {
    return ProfessionalDetails(
      highestQualification: _str(json['highestQualification']) ?? '',
      yearsOfTotalExperience: _num(json['yearsOfTotalExperience']) ?? 0,
      currentCompany: _str(json['currentCompany']) ?? '',
      currentDesignation: _str(json['currentDesignation']) ?? '',
      linkedInUrl: _str(json['linkedInUrl']),
    );
  }

  final String highestQualification;
  final double yearsOfTotalExperience;
  final String currentCompany;
  final String currentDesignation;
  final String? linkedInUrl;

  Map<String, dynamic> toJson() => {
        'highestQualification': highestQualification,
        'yearsOfTotalExperience': yearsOfTotalExperience,
        'currentCompany': currentCompany,
        'currentDesignation': currentDesignation,
        if (linkedInUrl != null && linkedInUrl!.isNotEmpty)
          'linkedInUrl': linkedInUrl,
      };
}

/// One skill the interviewer can evaluate, inside a domain.
@immutable
class SkillEntry {
  const SkillEntry({
    required this.name,
    required this.domain,
    required this.yearsExperience,
    required this.proficiency,
    this.skillId,
  });

  factory SkillEntry.fromJson(Map<String, dynamic> json) {
    return SkillEntry(
      skillId: _str(json['skillId']),
      name: _str(json['name']) ?? '',
      domain: _str(json['domain']) ?? 'Other',
      yearsExperience: _num(json['yearsExperience']) ?? 0,
      proficiency: ProficiencyLevel.fromApi(json['proficiencyLevel']),
    );
  }

  final String? skillId;
  final String name;
  final String domain;
  final double yearsExperience;
  final ProficiencyLevel proficiency;

  Map<String, dynamic> toJson() => {
        if (skillId != null) 'skillId': skillId,
        'name': name,
        'domain': domain,
        'yearsExperience': yearsExperience,
        'proficiencyLevel': proficiency.apiValue,
      };

  @override
  bool operator ==(Object other) =>
      other is SkillEntry &&
      other.skillId == skillId &&
      other.name == name &&
      other.domain == domain &&
      other.yearsExperience == yearsExperience &&
      other.proficiency == proficiency;

  @override
  int get hashCode =>
      Object.hash(skillId, name, domain, yearsExperience, proficiency);
}

@immutable
class ProfileDocument {
  const ProfileDocument({
    required this.documentId,
    required this.documentName,
    required this.type,
    this.fileSizeBytes,
    this.localPath,
  });

  factory ProfileDocument.fromJson(Map<String, dynamic> json) {
    return ProfileDocument(
      documentId: _str(json['documentId']) ?? '',
      documentName: _str(json['documentName']) ?? 'Document',
      type: DocumentType.fromApi(json['documentType']),
      fileSizeBytes: _num(json['fileSizeBytes'])?.toInt(),
      localPath: _str(json['localPath']),
    );
  }

  final String documentId;
  final String documentName;
  final DocumentType type;
  final int? fileSizeBytes;

  /// Where the file is on this device, if it was uploaded from here. Used to
  /// open it without downloading. Never sent to the server.
  final String? localPath;

  bool get isImage {
    final name = documentName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentName': documentName,
        'documentType': type.apiValue,
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
        if (localPath != null) 'localPath': localPath,
      };
}

/// Everything the interviewer enters about themselves.
@immutable
class InterviewerProfile {
  const InterviewerProfile({
    required this.personal,
    required this.professional,
    required this.skills,
    required this.documents,
  });

  factory InterviewerProfile.fromJson(Map<String, dynamic> json) {
    return InterviewerProfile(
      personal: PersonalDetails.fromJson(_map(json['personal'])),
      professional: ProfessionalDetails.fromJson(_map(json['professional'])),
      skills: _list(json['skills']).map(SkillEntry.fromJson).toList(),
      documents: _list(json['documents']).map(ProfileDocument.fromJson).toList(),
    );
  }

  final PersonalDetails personal;
  final ProfessionalDetails professional;
  final List<SkillEntry> skills;
  final List<ProfileDocument> documents;

  bool get hasResume => documents.any((d) => d.type == DocumentType.resume);

  InterviewerProfile copyWith({
    PersonalDetails? personal,
    ProfessionalDetails? professional,
    List<SkillEntry>? skills,
    List<ProfileDocument>? documents,
  }) {
    return InterviewerProfile(
      personal: personal ?? this.personal,
      professional: professional ?? this.professional,
      skills: skills ?? this.skills,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toJson() => {
        'personal': personal.toJson(),
        'professional': professional.toJson(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
      };
}

// ---------------------------------------------------------------------------
// JSON helpers (tolerant of missing or mistyped fields).
// ---------------------------------------------------------------------------

String? _str(Object? v) => v is String ? v : null;

double? _num(Object? v) => v is num ? v.toDouble() : null;

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
