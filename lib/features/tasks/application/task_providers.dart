import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/features/tasks/data/models/task.dart';
import 'package:tamam/features/tasks/data/task_repository.dart';

/// StateProvider controlling whether completed tasks are displayed in the list.
final showCompletedTasksProvider = StateProvider<bool>((ref) => false);

/// StateProvider filtering tasks by project ID, or null for all tasks.
final selectedProjectIdFilterProvider = StateProvider<String?>((ref) => null);

/// StreamProvider exposing the reactive stream of tasks based on active
/// filters.
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final showCompleted = ref.watch(showCompletedTasksProvider);
  final projectId = ref.watch(selectedProjectIdFilterProvider);

  return ref.watch(taskRepositoryProvider).watchTasks(
        includeCompleted: showCompleted,
        projectId: projectId,
      );
});

/// StreamProvider retrieving a single task reactively by its ID.
final taskByIdProvider =
    StreamProvider.autoDispose.family<Task?, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).watchTask(id);
});


/// Riverpod provider for the [TaskController].
final taskControllerProvider =
    AutoDisposeAsyncNotifierProvider<TaskController, void>(
  TaskController.new,
);

/// Controller managing task mutations and user interactions.
class TaskController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle.
  }

  /// Creates a new task and returns its ID, or null on failure.
  Future<String?> createTask({
    required String title,
    String? notes,
    String? projectId,
    int priority = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await ref.read(taskRepositoryProvider).createTask(
            title: title,
            notes: notes,
            projectId: projectId,
            priority: priority,
          );
      state = const AsyncValue.data(null);
      return id;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Updates an existing task, returning true on success.
  Future<bool> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(taskRepositoryProvider).updateTask(task);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Toggles task completion state.
  Future<bool> toggleComplete(String id, {required bool isCompleted}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(taskRepositoryProvider)
          .toggleComplete(id, isCompleted: isCompleted);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Soft-deletes a task by its [id].
  Future<bool> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(taskRepositoryProvider).softDeleteTask(id);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
