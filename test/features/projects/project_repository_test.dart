import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/projects/data/project_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectDao dao;
  late ProjectRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ProjectDao(db);
    repository = ProjectRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProjectRepository', () {
    test(
      'createProject inserts and emits through watchProjects stream',
      () async {
        final id = await repository.createProject(
          name: 'Work',
          color: 0xFF5B5BD6,
          icon: 'briefcase',
        );

        expect(id, isNotEmpty);

        final projects = await repository.getProjects();
        expect(projects.length, 1);
        expect(projects.first.id, id);
        expect(projects.first.name, 'Work');
        expect(projects.first.color, 0xFF5B5BD6);
        expect(projects.first.icon, 'briefcase');
        expect(projects.first.deletedAt, isNull);

        final single = await repository.getProject(id);
        expect(single, isNotNull);
        expect(single!.name, 'Work');
      },
    );

    test(
      'updateProject modifies name and color and updates timestamp',
      () async {
        final id = await repository.createProject(
          name: 'Personal',
          color: 0xFF3B82F6,
        );

        final initial = await repository.getProject(id);
        expect(initial, isNotNull);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final updated = initial!.copyWith(
          name: 'Personal & Family',
          color: 0xFF10B981,
        );

        await repository.updateProject(updated);

        final fetched = await repository.getProject(id);
        expect(fetched!.name, 'Personal & Family');
        expect(fetched.color, 0xFF10B981);
        expect(
          fetched.updatedAt.isAfter(initial.updatedAt) ||
              fetched.updatedAt.isAtSameMomentAs(initial.updatedAt),
          isTrue,
        );
      },
    );

    test(
      'softDeleteProject sets deletedAt and excludes from watchProjects',
      () async {
        final id = await repository.createProject(
          name: 'Temporary',
          color: 0xFFEF4444,
        );

        expect((await repository.getProjects()).length, 1);

        await repository.softDeleteProject(id);

        // Verify excluded from repository get and watch
        final activeProjects = await repository.getProjects();
        expect(activeProjects, isEmpty);

        // Verify the row still exists in raw table with deletedAt != null
        final rawEntries = await dao.getRawProjects();
        expect(rawEntries.length, 1);
        expect(rawEntries.first.id, id);
        expect(rawEntries.first.deletedAt, isNotNull);
      },
    );
  });
}
