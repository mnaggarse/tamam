import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/features/projects/data/models/project.dart';
import 'package:tamam/features/projects/data/project_repository.dart';

/// StreamProvider exposing the reactive stream of active projects.
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchProjects();
});

/// FutureProvider retrieving a single project by its ID.
final projectByIdProvider =
    FutureProvider.autoDispose.family<Project?, String>((ref, id) async {
  return ref.watch(projectRepositoryProvider).getProject(id);
});


/// Riverpod provider for the [ProjectController].
final projectControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProjectController, void>(
  ProjectController.new,
);

/// Controller managing project mutations and user actions.
class ProjectController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle.
  }

  /// Creates a new project and returns its unique ID, or null on failure.
  Future<String?> createProject({
    required String name,
    required int color,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await ref.read(projectRepositoryProvider).createProject(
            name: name,
            color: color,
            icon: icon,
          );
      state = const AsyncValue.data(null);
      return id;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Updates an existing project, returning true on success.
  Future<bool> updateProject(Project project) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(projectRepositoryProvider).updateProject(project);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Soft-deletes a project by its [id], returning true on success.
  Future<bool> deleteProject(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(projectRepositoryProvider).softDeleteProject(id);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
