import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/features/dashboard/domain/dashboard_summary.dart';

/// Loads the dashboard and keeps the last good copy in the local database,
/// so the dashboard still shows something when the device is offline.
class DashboardRepository {
  DashboardRepository(this._api, this._db);

  final ApiClient _api;
  final AppDatabase _db;

  static const _cacheKey = 'dashboard_summary';

  Future<DashboardSummary> fetchSummary() async {
    try {
      final data = await _api.get('/dashboard/summary');
      final now = DateTime.now();
      await _db.writeCache(
        _cacheKey,
        jsonEncode({'savedAt': now.toIso8601String(), 'data': data}),
      );
      return DashboardSummary.fromJson(data, savedAt: now);
    } on ApiException catch (e) {
      if (e is! NetworkException && e is! TimeoutApiException) rethrow;
      final cached = await _readCache();
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<DashboardSummary?> _readCache() async {
    final raw = await _db.readCache(_cacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) return null;
    final savedAt = decoded['savedAt'];
    return DashboardSummary.fromJson(
      data,
      savedAt: savedAt is String ? DateTime.tryParse(savedAt) : null,
      isFromCache: true,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  ),
);

/// The dashboard data. Pull-to-refresh calls `ref.refresh(...future)`.
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchSummary();
});
