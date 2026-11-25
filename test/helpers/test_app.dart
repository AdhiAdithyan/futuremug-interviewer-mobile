import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/app.dart';
import 'package:futuremug_interviewer/core/config/app_config.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';

/// Mock API with no artificial delay.
const testConfig = AppConfig(
  environment: AppEnvironment.mock,
  baseUrl: 'https://mock.futuremug.local/api/v1',
  mockLatency: Duration.zero,
);

/// A provider container wired like the app: mock API, in-memory database,
/// in-memory secure storage. Dispose it in `tearDown`.
ProviderContainer createTestContainer({
  AppDatabase? database,
  List<Override> overrides = const [],
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  final db = database ?? AppDatabase.inMemory();
  return ProviderContainer(
    overrides: [
      ...appRootOverrides(database: db),
      appConfigProvider.overrideWithValue(testConfig),
      ...overrides,
    ],
  );
}

/// Writes a small temporary file to stand in for a picked document.
Future<PickedDocument> createTempDocument(String name) async {
  final dir = await Directory.systemTemp.createTemp('fm_test_');
  final file = File('${dir.path}/$name');
  await file.writeAsString('test document');
  return PickedDocument(
    path: file.path,
    name: name,
    sizeBytes: await file.length(),
  );
}

/// A document picker that returns a fixed file (or `null` = cancelled).
class FakeDocumentPicker extends DocumentPicker {
  FakeDocumentPicker(this.result);

  PickedDocument? result;

  /// The last request, for assertions.
  DocumentSource? lastSource;
  bool? lastImagesOnly;

  @override
  Future<PickedDocument?> pick({
    required DocumentSource source,
    bool imagesOnly = false,
  }) async {
    lastSource = source;
    lastImagesOnly = imagesOnly;
    return result;
  }
}
