import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/daos/tag_dao.dart';
import 'package:tamam/core/database/daos/task_dao.dart';
import 'package:tamam/core/database/tables/projects_table.dart';
import 'package:tamam/core/database/tables/tags_table.dart';
import 'package:tamam/core/database/tables/tasks_table.dart';

part 'database.g.dart';

/// The central Drift database for Tamam.
@DriftDatabase(
  tables: [Projects, Tags, Tasks],
  daos: [ProjectDao, TagDao, TaskDao],
)
class AppDatabase extends _$AppDatabase {
  /// Creates an [AppDatabase] using standard file storage or a given
  /// [executor].
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Creates an [AppDatabase] using an explicit connection (for testing).
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(tags);
        }
        if (from < 3) {
          await m.createTable(tasks);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'tamam.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

/// Riverpod provider managing the singleton [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Riverpod provider exposing the [ProjectDao].
final projectDaoProvider = Provider<ProjectDao>((ref) {
  return ref.watch(appDatabaseProvider).projectDao;
});

/// Riverpod provider exposing the [TagDao].
final tagDaoProvider = Provider<TagDao>((ref) {
  return ref.watch(appDatabaseProvider).tagDao;
});

/// Riverpod provider exposing the [TaskDao].
final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(appDatabaseProvider).taskDao;
});
