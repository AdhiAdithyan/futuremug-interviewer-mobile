import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScorecardDraftsTable extends Table {
  TextColumn get interviewId => text()();
  TextColumn get draftJsonData => text()();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {interviewId};
}

class AppDatabase {
  final QueryExecutor? execution;
  AppDatabase([this.execution]);
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
