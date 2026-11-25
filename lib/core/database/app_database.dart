import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local SQLite vault (`futuremug_interviewer_vault.sqlite`).
///
/// Written with Drift's raw-SQL API so the project builds without a
/// `build_runner` step. The schema lives in [_schemaV1]; bump [schemaVersion]
/// and add an `onUpgrade` step for every change.
///
/// Tables:
/// * `scorecard_drafts` – interview report drafts (autosave, never lost on
///   sign-out).
/// * `cache_entries`    – last good API responses, keyed by request, so
///   screens can show data offline.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(_openConnection());

  /// In-memory database for tests.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  static const String fileName = 'futuremug_interviewer_vault.sqlite';

  static const List<String> _schemaV1 = [
    '''
    CREATE TABLE IF NOT EXISTS scorecard_drafts (
      interview_id TEXT NOT NULL PRIMARY KEY,
      draft_json   TEXT NOT NULL,
      updated_at   INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cache_entries (
      cache_key  TEXT NOT NULL PRIMARY KEY,
      json       TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
    ''',
  ];

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          for (final statement in _schemaV1) {
            await customStatement(statement);
          }
        },
        onUpgrade: (m, from, to) async {
          // Add a step per version, e.g. `if (from < 2) { ... }`.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------------------
  // Scorecard drafts
  // ---------------------------------------------------------------------------

  Future<void> saveScorecardDraft(String interviewId, String draftJson) {
    return customStatement(
      'INSERT INTO scorecard_drafts (interview_id, draft_json, updated_at) '
      'VALUES (?, ?, ?) '
      'ON CONFLICT(interview_id) DO UPDATE SET '
      'draft_json = excluded.draft_json, updated_at = excluded.updated_at',
      [interviewId, draftJson, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<String?> readScorecardDraft(String interviewId) async {
    final row = await customSelect(
      'SELECT draft_json FROM scorecard_drafts WHERE interview_id = ?',
      variables: [Variable.withString(interviewId)],
    ).getSingleOrNull();
    return row?.read<String>('draft_json');
  }

  Future<void> deleteScorecardDraft(String interviewId) {
    return customStatement(
      'DELETE FROM scorecard_drafts WHERE interview_id = ?',
      [interviewId],
    );
  }

  // ---------------------------------------------------------------------------
  // Response cache
  // ---------------------------------------------------------------------------

  Future<void> writeCache(String key, String json) {
    return customStatement(
      'INSERT INTO cache_entries (cache_key, json, updated_at) VALUES (?, ?, ?) '
      'ON CONFLICT(cache_key) DO UPDATE SET '
      'json = excluded.json, updated_at = excluded.updated_at',
      [key, json, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<String?> readCache(String key) async {
    final row = await customSelect(
      'SELECT json FROM cache_entries WHERE cache_key = ?',
      variables: [Variable.withString(key)],
    ).getSingleOrNull();
    return row?.read<String>('json');
  }

  /// Clears cached server data (e.g. on sign-out). Drafts are kept.
  Future<void> clearCache() => customStatement('DELETE FROM cache_entries');
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, AppDatabase.fileName));
    return NativeDatabase.createInBackground(file);
  });
}

/// Overridden in `main.dart` with the opened database; tests override it with
/// [AppDatabase.inMemory].
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
