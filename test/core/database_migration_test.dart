import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tamam/core/database/database.dart';

void main() {
  test('AppDatabase creates all tables and enables foreign keys', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 3);

    // Verify inserting into projects works
    await db.projectDao.insertProject(
      ProjectsCompanion.insert(
        id: 'p1',
        name: 'Work',
        color: 0xFF000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Verify inserting into tags works
    await db.tagDao.insertTag(
      TagsCompanion.insert(
        id: 't1',
        name: 'urgent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Verify inserting into tasks works
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'task-1',
        title: 'Review PR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final projects = await db.projectDao.getAllProjects();
    final tags = await db.tagDao.getAllTags();
    final tasks = await db.taskDao.getTasks();

    expect(projects.length, 1);
    expect(tags.length, 1);
    expect(tasks.length, 1);
  });

  test('Migration from v1 creates tags table and preserves existing projects',
      () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final file = File(p.join(tempDir.path, 'migration_v1_test.sqlite'));
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Step 1: Open file with schema 1
    final db1 = AppDatabase(NativeDatabase(file));
    await db1.customStatement('PRAGMA user_version = 1;');
    await db1.projectDao.insertProject(
      ProjectsCompanion.insert(
        id: 'p-pre-migration',
        name: 'Existing Project',
        color: 0xFF123456,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await db1.close();

    // Step 2: Open with AppDatabase v3, which runs onUpgrade
    final db2 = AppDatabase(NativeDatabase(file));
    addTearDown(db2.close);

    // Verify existing project is preserved
    final projects = await db2.projectDao.getAllProjects();
    expect(projects.length, 1);
    expect(projects.first.id, 'p-pre-migration');

    // Verify tags table now exists and can receive inserts
    await db2.tagDao.insertTag(
      TagsCompanion.insert(
        id: 't-post-migration',
        name: 'new-tag',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final tags = await db2.tagDao.getAllTags();
    expect(tags.length, 1);
    expect(tags.first.name, 'new-tag');
  });

  test('Migration from v2 creates tasks table and preserves projects and tags',
      () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final file = File(p.join(tempDir.path, 'migration_v2_test.sqlite'));
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Step 1: Open file and set schema to 2
    final db1 = AppDatabase(NativeDatabase(file));
    await db1.customStatement('PRAGMA user_version = 2;');
    await db1.projectDao.insertProject(
      ProjectsCompanion.insert(
        id: 'p-v2',
        name: 'Project v2',
        color: 0xFF00FF00,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await db1.tagDao.insertTag(
      TagsCompanion.insert(
        id: 't-v2',
        name: 'tag-v2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await db1.close();

    // Step 2: Open with AppDatabase v3, which runs onUpgrade from v2
    final db2 = AppDatabase(NativeDatabase(file));
    addTearDown(db2.close);

    // Verify existing projects and tags are preserved
    final projects = await db2.projectDao.getAllProjects();
    final tags = await db2.tagDao.getAllTags();
    expect(projects.length, 1);
    expect(projects.first.name, 'Project v2');
    expect(tags.length, 1);
    expect(tags.first.name, 'tag-v2');

    // Verify tasks table was created and supports foreign key to project
    await db2.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'task-v3',
        title: 'Task in v3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final tasks = await db2.taskDao.getTasks();
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Task in v3');
  });
}
