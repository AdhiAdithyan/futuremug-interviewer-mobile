import 'package:flutter/foundation.dart';

/// `GET /dashboard/summary` (OpenAPI `DashboardSummaryResponse.data`).
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.fullName,
    required this.stats,
    this.tier,
    this.rating,
    this.availabilityStatus,
    this.nextInterview,
    this.monthly = const [],
    this.savedAt,
    this.isFromCache = false,
  });

  factory DashboardSummary.fromJson(
    Map<String, dynamic> json, {
    DateTime? savedAt,
    bool isFromCache = false,
  }) {
    final profile = _map(json['profileSummary']);
    final next = json['upcomingNextInterview'];
    return DashboardSummary(
      fullName: _str(profile['fullName']) ?? '',
      tier: _str(profile['tier']),
      rating: _num(profile['rating']),
      availabilityStatus: _str(profile['availabilityStatus']),
      stats: DashboardStats.fromJson(_map(json['statisticsCards'])),
      nextInterview: next is Map<String, dynamic>
          ? UpcomingInterview.fromJson(next)
          : null,
      monthly: (json['monthlyInterviewChart'] is List)
          ? (json['monthlyInterviewChart'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MonthlyActivity.fromJson)
              .toList()
          : const [],
      savedAt: savedAt,
      isFromCache: isFromCache,
    );
  }

  final String fullName;
  final String? tier;
  final double? rating;
  final String? availabilityStatus;
  final DashboardStats stats;
  final UpcomingInterview? nextInterview;
  final List<MonthlyActivity> monthly;

  /// When this data was fetched (set for cached copies).
  final DateTime? savedAt;

  /// True when the server couldn't be reached and saved data is shown.
  final bool isFromCache;

  String get availabilityLabel => switch (availabilityStatus) {
        'AVAILABLE_NOW' || 'AVAILABLE' => 'Available',
        'BUSY' || 'IN_INTERVIEW' => 'In an interview',
        'ON_LEAVE' => 'On leave',
        'OFFLINE' => 'Offline',
        _ => '',
      };
}

@immutable
class DashboardStats {
  const DashboardStats({
    required this.completedInterviews,
    required this.pendingInterviews,
    required this.todayInterviews,
    required this.totalEarnings,
    required this.currency,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      completedInterviews: _num(json['completedInterviews'])?.toInt() ?? 0,
      pendingInterviews: _num(json['pendingInterviews'])?.toInt() ?? 0,
      todayInterviews: _num(json['todayInterviews'])?.toInt() ?? 0,
      totalEarnings: _num(json['totalEarningsAccrued']) ?? 0,
      currency: _str(json['currency']) ?? 'INR',
    );
  }

  final int completedInterviews;
  final int pendingInterviews;
  final int todayInterviews;
  final double totalEarnings;
  final String currency;
}

@immutable
class UpcomingInterview {
  const UpcomingInterview({
    required this.interviewId,
    required this.candidateName,
    this.targetRole,
    this.clientCompany,
    this.timeFormatted,
    this.minutesUntilStart,
    this.meetingPlatform,
    this.meetingJoinUrl,
  });

  factory UpcomingInterview.fromJson(Map<String, dynamic> json) {
    return UpcomingInterview(
      interviewId: _str(json['interviewId']) ?? '',
      candidateName: _str(json['candidateName']) ?? 'Candidate',
      targetRole: _str(json['targetRole']),
      clientCompany: _str(json['clientCompany']),
      timeFormatted: _str(json['timeFormatted']),
      minutesUntilStart: _num(json['timeRemainingMinutes'])?.toInt(),
      meetingPlatform: _str(json['meetingPlatform']),
      meetingJoinUrl: _str(json['meetingJoinUrl']),
    );
  }

  final String interviewId;
  final String candidateName;
  final String? targetRole;
  final String? clientCompany;
  final String? timeFormatted;
  final int? minutesUntilStart;
  final String? meetingPlatform;
  final String? meetingJoinUrl;

  String get platformLabel => switch (meetingPlatform) {
        'GOOGLE_MEET' => 'Google Meet',
        'ZOOM' => 'Zoom',
        'MS_TEAMS' || 'MICROSOFT_TEAMS' => 'Microsoft Teams',
        null => 'Online',
        final String other => other,
      };

  String get initials => candidateName
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
}

@immutable
class MonthlyActivity {
  const MonthlyActivity({
    required this.month,
    required this.interviews,
    required this.earnings,
  });

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    return MonthlyActivity(
      month: _str(json['month']) ?? '',
      interviews: _num(json['interviews'])?.toInt() ?? 0,
      earnings: _num(json['earnings']) ?? 0,
    );
  }

  final String month;
  final int interviews;
  final double earnings;
}

String? _str(Object? v) => v is String ? v : null;

double? _num(Object? v) => v is num ? v.toDouble() : null;

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};
