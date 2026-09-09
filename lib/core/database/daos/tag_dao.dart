import 'package:drift/drift.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/database/tables/tags_table.dart';

part 'tag_dao.g.dart';

/// Data access object for the [Tags] table.
@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  /// Creates a [TagDao] accessor.
  TagDao(super.db);

  /// Watches all non-deleted tags, ordered alphabetically by name.
  Stream<List<TagEntry>> watchAllTags() {
    return (select(tags)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .watch();
  }

  /// Retrieves all non-deleted tags, ordered alphabetically by name.
  Future<List<TagEntry>> getAllTags() {
    return (select(tags)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  /// Retrieves a single tag by its [id].
  Future<TagEntry?> getTagById(String id) {
    return (select(tags)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new tag.
  Future<int> insertTag(TagsCompanion companion) {
    return into(tags).insert(companion);
  }

  /// Updates an existing tag.
  Future<bool> updateTag(TagsCompanion companion) {
    return update(tags).replace(companion);
  }

  /// Soft-deletes a tag by marking `deletedAt` and updating `updatedAt`.
  Future<int> softDeleteTag(String id, DateTime deletedAt) {
    return (update(tags)..where((tbl) => tbl.id.equals(id))).write(
      TagsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  /// Physical deletion of a tag by [id] (used primarily for test cleanup).
  Future<int> hardDeleteTag(String id) {
    return (delete(tags)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves all tags including soft-deleted ones (for verification/sync).
  Future<List<TagEntry>> getRawTags() {
    return select(tags).get();
  }
}
