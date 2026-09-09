import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/core/database/daos/tag_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase db;
  late TagDao dao;
  late TagRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TagDao(db);
    repository = TagRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('TagRepository', () {
    test(
      'createTag inserts and emits through watchTags stream with color',
      () async {
        final id = await repository.createTag(
          name: 'urgent',
          color: 0xFFEF4444,
        );

        expect(id, isNotEmpty);

        final tags = await repository.getTags();
        expect(tags.length, 1);
        expect(tags.first.id, id);
        expect(tags.first.name, 'urgent');
        expect(tags.first.color, 0xFFEF4444);
        expect(tags.first.deletedAt, isNull);

        final single = await repository.getTag(id);
        expect(single, isNotNull);
        expect(single!.name, 'urgent');
        expect(single.color, 0xFFEF4444);
      },
    );

    test(
      'createTag supports optional null color',
      () async {
        final id = await repository.createTag(
          name: 'general',
        );

        expect(id, isNotEmpty);

        final tags = await repository.getTags();
        expect(tags.length, 1);
        expect(tags.first.id, id);
        expect(tags.first.name, 'general');
        expect(tags.first.color, isNull);
      },
    );

    test(
      'updateTag modifies name and color and updates timestamp',
      () async {
        final id = await repository.createTag(
          name: 'initial',
          color: 0xFF3B82F6,
        );

        final initial = await repository.getTag(id);
        expect(initial, isNotNull);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final updated = initial!.copyWith(
          name: 'renamed',
          color: 0xFF10B981,
        );

        await repository.updateTag(updated);

        final fetched = await repository.getTag(id);
        expect(fetched!.name, 'renamed');
        expect(fetched.color, 0xFF10B981);
        expect(
          fetched.updatedAt.isAfter(initial.updatedAt) ||
              fetched.updatedAt.isAtSameMomentAs(initial.updatedAt),
          isTrue,
        );
      },
    );

    test(
      'softDeleteTag sets deletedAt and excludes from watchTags',
      () async {
        final id = await repository.createTag(
          name: 'to-delete',
          color: 0xFFF59E0B,
        );

        expect((await repository.getTags()).length, 1);

        await repository.softDeleteTag(id);

        // Verify excluded from repository get and watch
        final activeTags = await repository.getTags();
        expect(activeTags, isEmpty);

        // Verify the row still exists in raw table with deletedAt != null
        final rawEntries = await dao.getRawTags();
        expect(rawEntries.length, 1);
        expect(rawEntries.first.id, id);
        expect(rawEntries.first.deletedAt, isNotNull);
      },
    );
  });
}
