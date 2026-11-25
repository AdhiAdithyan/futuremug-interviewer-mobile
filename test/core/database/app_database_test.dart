import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  group('scorecard drafts', () {
    test('save, read, overwrite and delete', () async {
      expect(await db.readScorecardDraft('INT-1'), isNull);

      await db.saveScorecardDraft('INT-1', '{"score":3}');
      expect(await db.readScorecardDraft('INT-1'), '{"score":3}');

      await db.saveScorecardDraft('INT-1', '{"score":4}');
      expect(await db.readScorecardDraft('INT-1'), '{"score":4}');

      await db.deleteScorecardDraft('INT-1');
      expect(await db.readScorecardDraft('INT-1'), isNull);
    });

    test('drafts are kept when the cache is cleared (sign-out)', () async {
      await db.saveScorecardDraft('INT-2', '{}');
      await db.writeCache('dashboard', '{"x":1}');

      await db.clearCache();

      expect(await db.readCache('dashboard'), isNull);
      expect(await db.readScorecardDraft('INT-2'), '{}');
    });
  });

  test('cache write and overwrite', () async {
    await db.writeCache('k', 'v1');
    await db.writeCache('k', 'v2');
    expect(await db.readCache('k'), 'v2');
  });
}
