import 'package:flutter/foundation.dart';

/// The signed-in interviewer, as returned in the `user` object of the auth
/// responses (OpenAPI `EvaluatorUserProfile`).
@immutable
class EvaluatorUser {
  const EvaluatorUser({
    required this.interviewerId,
    required this.fullName,
    required this.isOnboardingComplete,
    this.username,
    this.email,
    this.tierLevel,
    this.avatarUrl,
  });

  factory EvaluatorUser.fromJson(Map<String, dynamic> json) {
    return EvaluatorUser(
      interviewerId: _string(json['interviewerId']) ?? '',
      fullName: _string(json['fullName']) ?? '',
      isOnboardingComplete: json['isOnboardingComplete'] == true,
      username: _string(json['username']),
      email: _string(json['email']),
      tierLevel: _string(json['tierLevel']),
      avatarUrl: _string(json['avatarUrl']),
    );
  }

  final String interviewerId;
  final String fullName;

  /// False until the interviewer has completed their profile (details,
  /// skills, documents). Drives the "profile setup vs dashboard" decision.
  final bool isOnboardingComplete;
  final String? username;
  final String? email;
  final String? tierLevel;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'interviewerId': interviewerId,
        'fullName': fullName,
        'isOnboardingComplete': isOnboardingComplete,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (tierLevel != null) 'tierLevel': tierLevel,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  EvaluatorUser copyWith({String? fullName, bool? isOnboardingComplete}) {
    return EvaluatorUser(
      interviewerId: interviewerId,
      fullName: fullName ?? this.fullName,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      username: username,
      email: email,
      tierLevel: tierLevel,
      avatarUrl: avatarUrl,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;
}
