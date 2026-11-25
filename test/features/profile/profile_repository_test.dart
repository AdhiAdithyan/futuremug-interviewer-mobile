import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/core/network/mock/mock_api_interceptor.dart';
import 'package:futuremug_interviewer/features/dashboard/data/dashboard_repository.dart';
import 'package:futuremug_interviewer/features/profile/data/profile_repository.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

import '../../helpers/test_app.dart';

/// Lets a test switch the "network" off: every request then fails as if the
/// device were offline.
class _OfflineSwitch extends Interceptor {
  bool offline = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (offline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }
    handler.next(options);
  }
}

void main() {
  late AppDatabase db;
  late Dio dio;
  late _OfflineSwitch network;
  late ProfileRepository profiles;
  late DashboardRepository dashboard;

  setUp(() {
    db = AppDatabase.inMemory();
    network = _OfflineSwitch();
    dio = Dio(BaseOptions(baseUrl: testConfig.baseUrl))
      ..interceptors.addAll([
        network,
        MockApiInterceptor(latency: Duration.zero),
      ]);
    final api = ApiClient(dio);
    profiles = ProfileRepository(api, db);
    dashboard = DashboardRepository(api, db);
  });

  tearDown(() async {
    dio.close();
    await db.close();
  });

  group('ProfileRepository', () {
    test('fetches and parses the profile', () async {
      final profile = await profiles.fetchProfile();
      expect(profile.personal.fullName, isNotEmpty);
      expect(profile.skills, isNotEmpty);
      expect(profile.hasResume, isTrue);
    });

    test('updates are saved and returned', () async {
      final profile = await profiles.fetchProfile();
      final updated = profile.copyWith(
        professional: const ProfessionalDetails(
          highestQualification: 'PhD',
          yearsOfTotalExperience: 12.5,
          currentCompany: 'NewCo',
          currentDesignation: 'Principal Engineer',
        ),
      );

      await profiles.updateProfile(updated);
      final reloaded = await profiles.fetchProfile();

      expect(reloaded.professional.currentCompany, 'NewCo');
      expect(reloaded.professional.yearsOfTotalExperience, 12.5);
    });

    test('offline: falls back to the last saved profile', () async {
      final online = await profiles.fetchProfile();
      network.offline = true;

      final offline = await profiles.fetchProfile();
      expect(offline.personal.fullName, online.personal.fullName);
    });

    test('offline with nothing saved: throws NetworkException', () async {
      network.offline = true;
      await expectLater(
        profiles.fetchProfile(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('documents can be uploaded and deleted', () async {
      final file = await createTempDocument('aws_cert.pdf');
      final uploaded = await profiles.uploadDocument(
        file: file,
        type: DocumentType.certification,
      );
      expect(uploaded.documentName, 'aws_cert.pdf');
      expect(uploaded.type, DocumentType.certification);

      await profiles.deleteDocument(uploaded.documentId);
      final profile = await profiles.fetchProfile();
      expect(
        profile.documents.any((d) => d.documentId == uploaded.documentId),
        isFalse,
      );
    });
  });

  group('DashboardRepository', () {
    test('parses the summary', () async {
      final summary = await dashboard.fetchSummary();
      expect(summary.stats.completedInterviews, greaterThan(0));
      expect(summary.nextInterview?.candidateName, isNotEmpty);
      expect(summary.monthly, isNotEmpty);
      expect(summary.isFromCache, isFalse);
    });

    test('offline: shows saved data, marked as cached', () async {
      await dashboard.fetchSummary();
      network.offline = true;

      final cached = await dashboard.fetchSummary();
      expect(cached.isFromCache, isTrue);
      expect(cached.savedAt, isNotNull);
      expect(cached.stats.completedInterviews, greaterThan(0));
    });

    test('offline with nothing saved: throws', () async {
      network.offline = true;
      await expectLater(
        dashboard.fetchSummary(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
