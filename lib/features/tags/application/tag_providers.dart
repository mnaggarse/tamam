import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/features/tags/data/models/tag.dart';
import 'package:tamam/features/tags/data/tag_repository.dart';

/// StreamProvider exposing the reactive stream of active tags.
final tagsStreamProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchTags();
});

/// FutureProvider retrieving a single tag by its ID.
final tagByIdProvider =
    FutureProvider.autoDispose.family<Tag?, String>((ref, id) async {
  return ref.watch(tagRepositoryProvider).getTag(id);
});


/// Riverpod provider for the [TagController].
final tagControllerProvider =
    AutoDisposeAsyncNotifierProvider<TagController, void>(
  TagController.new,
);

/// Controller managing tag mutations and user actions.
class TagController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle.
  }

  /// Creates a new tag and returns its unique ID, or null on failure.
  Future<String?> createTag({
    required String name,
    int? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await ref.read(tagRepositoryProvider).createTag(
            name: name,
            color: color,
          );
      state = const AsyncValue.data(null);
      return id;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Updates an existing tag, returning true on success.
  Future<bool> updateTag(Tag tag) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(tagRepositoryProvider).updateTag(tag);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Soft-deletes a tag by its [id], returning true on success.
  Future<bool> deleteTag(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(tagRepositoryProvider).softDeleteTag(id);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
