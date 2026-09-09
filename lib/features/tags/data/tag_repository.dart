import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/core/database/daos/tag_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/utils/id_generator.dart';
import 'package:tamam/features/tags/data/models/tag.dart';

/// Repository managing Tag domain entities.
class TagRepository {
  /// Creates a [TagRepository].
  const TagRepository(this._tagDao);

  final TagDao _tagDao;

  /// Watches all active (non-deleted) tags.
  Stream<List<Tag>> watchTags() {
    return _tagDao.watchAllTags().map(
          (entries) => entries.map(_entryToDomain).toList(),
        );
  }

  /// Retrieves all active (non-deleted) tags.
  Future<List<Tag>> getTags() async {
    final entries = await _tagDao.getAllTags();
    return entries.map(_entryToDomain).toList();
  }

  /// Retrieves a tag by [id].
  Future<Tag?> getTag(String id) async {
    final entry = await _tagDao.getTagById(id);
    return entry != null ? _entryToDomain(entry) : null;
  }

  /// Creates and stores a new tag.
  Future<String> createTag({
    required String name,
    int? color,
  }) async {
    final id = IdGenerator.generateUuidV7();
    final now = DateTime.now();

    await _tagDao.insertTag(
      TagsCompanion.insert(
        id: id,
        name: name,
        color: Value(color),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return id;
  }

  /// Updates an existing tag.
  Future<void> updateTag(Tag tag) async {
    final now = DateTime.now();

    await _tagDao.updateTag(
      TagsCompanion(
        id: Value(tag.id),
        name: Value(tag.name),
        color: Value(tag.color),
        createdAt: Value(tag.createdAt),
        updatedAt: Value(now),
        deletedAt: Value(tag.deletedAt),
      ),
    );
  }

  /// Soft-deletes a tag by its [id].
  Future<void> softDeleteTag(String id) async {
    final now = DateTime.now();
    await _tagDao.softDeleteTag(id, now);
  }

  /// Maps a Drift [TagEntry] row to a [Tag] domain entity.
  static Tag _entryToDomain(TagEntry entry) {
    return Tag(
      id: entry.id,
      name: entry.name,
      color: entry.color,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: entry.deletedAt,
    );
  }
}

/// Riverpod provider for the [TagRepository].
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final dao = ref.watch(tagDaoProvider);
  return TagRepository(dao);
});
